import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  OwnershipRequest,
  OwnershipRequestStatus,
} from './ownership-request.entity';
import { Batch } from '../batches/batch.entity';
import { BatchRelation } from '../batches/batch-relation.entity';
import { BatchEventsService } from '../batch-events/batch-events.service';
import { BatchEventType } from '../batch-events/batch-event.entity';

@Injectable()
export class OwnershipRequestsService {
  constructor(
    @InjectRepository(OwnershipRequest)
    private readonly repo: Repository<OwnershipRequest>,
    @InjectRepository(Batch)
    private readonly batches: Repository<Batch>,
    @InjectRepository(BatchRelation)
    private readonly relations: Repository<BatchRelation>,
    private readonly events: BatchEventsService,
  ) {}

  async createRequest(
    batchId: number,
    requesterId: number,
    ownerId: number,
    quantity: number,
    note?: string,
  ) {
    const batch = await this.batches.findOne({ where: { id: batchId } });
    if (!batch) throw new NotFoundException('Batch not found');
    if (batch.isItem) {
      throw new BadRequestException(
        'Ownership requests are not allowed for items',
      );
    }
    if (requesterId === ownerId) {
      throw new BadRequestException(
        'Cannot request ownership of your own batch',
      );
    }
    if (
      batch.isDisqualified ||
      ['MERGED', 'TRANSFORMED', 'SPLIT', 'ARCHIVED', 'DELETED'].includes(
        batch.status,
      )
    ) {
      throw new BadRequestException(
        'Batch is not eligible for ownership requests',
      );
    }
    if (batch.ownerId !== ownerId) {
      throw new BadRequestException('Owner mismatch');
    }
    if (quantity <= 0 || quantity > Number(batch.quantity)) {
      throw new BadRequestException('Invalid quantity');
    }

    const request = this.repo.create({
      batchId,
      requesterId,
      ownerId,
      quantity,
      status: OwnershipRequestStatus.PENDING,
      note: note ?? null,
    });
    return this.repo.save(request);
  }

  listInbox(ownerId: number, limit = 20) {
    return this.repo.find({
      where: { ownerId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  listOutbox(requesterId: number, limit = 20) {
    return this.repo.find({
      where: { requesterId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  async approve(id: number) {
    const request = await this.repo.findOne({ where: { id } });
    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== OwnershipRequestStatus.PENDING) {
      throw new BadRequestException('Request already resolved');
    }

    const batch = await this.batches.findOne({
      where: { id: request.batchId },
    });
    if (!batch) throw new NotFoundException('Batch not found');
    if (batch.ownerId !== request.ownerId) {
      throw new BadRequestException('Owner mismatch');
    }
    if (
      batch.isDisqualified ||
      ['MERGED', 'TRANSFORMED', 'SPLIT', 'ARCHIVED', 'DELETED'].includes(
        batch.status,
      )
    ) {
      throw new BadRequestException(
        'Batch is not eligible for ownership approval',
      );
    }

    const transferQty = Number(request.quantity);
    const remaining = Number(batch.quantity) - transferQty;
    if (remaining < 0) {
      throw new BadRequestException('Insufficient quantity');
    }

    let transferredBatch = batch;
    let ownerRemainingBatch: Batch | null = null;
    if (remaining === 0) {
      batch.ownerId = request.requesterId;
      batch.status = 'TRANSFERRED';
      await this.batches.save(batch);
    } else {
      batch.quantity = 0;
      batch.status = 'SPLIT';
      await this.batches.save(batch);

      ownerRemainingBatch = await this.createBatchFromTransfer(
        batch,
        remaining,
        request.ownerId,
        'CREATED',
      );
      transferredBatch = await this.createBatchFromTransfer(
        batch,
        transferQty,
        request.requesterId,
        'CREATED',
      );
      await this.createRelation(
        batch.id,
        ownerRemainingBatch.id,
        'SPLIT',
        remaining,
      );
      await this.createRelation(
        batch.id,
        transferredBatch.id,
        'TRANSFER',
        transferQty,
      );
    }

    request.status = OwnershipRequestStatus.APPROVED;
    await this.repo.save(request);

    await this.events.log(
      batch.id,
      BatchEventType.TRANSFERRED,
      `Transferred ${transferQty}`,
      {
        quantityAfter: batch.quantity,
        metadata: { to: request.requesterId, requestId: request.id },
      },
    );
    if (ownerRemainingBatch) {
      await this.events.log(
        ownerRemainingBatch.id,
        BatchEventType.SPLIT,
        `Remaining quantity after transfer request ${request.id}`,
        {
          quantityAfter: ownerRemainingBatch.quantity,
          metadata: { ownerId: request.ownerId, requestId: request.id },
        },
      );
    }
    await this.events.log(
      transferredBatch.id,
      BatchEventType.TRANSFERRED,
      `Received ${transferQty}`,
      {
        quantityAfter: transferredBatch.quantity,
        metadata: { from: request.ownerId, requestId: request.id },
      },
    );

    return {
      request,
      batch: transferredBatch,
      ownerBatch: ownerRemainingBatch,
    };
  }

  async reject(id: number, note?: string) {
    const request = await this.repo.findOne({ where: { id } });
    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== OwnershipRequestStatus.PENDING) {
      throw new BadRequestException('Request already resolved');
    }
    request.status = OwnershipRequestStatus.REJECTED;
    request.note = note ?? request.note;
    return this.repo.save(request);
  }

  private async createBatchFromTransfer(
    source: Batch,
    quantity: number,
    ownerId: number,
    status: string,
  ) {
    const batchCode = `BATCH-${Date.now()}-${Math.floor(Math.random() * 1000)
      .toString()
      .padStart(3, '0')}`;
    const batch = this.batches.create({
      productId: source.productId,
      ownerId,
      quantity,
      batchCode,
      unit: source.unit,
      grade: source.grade,
      status,
      stageId: source.stageId,
      isDisqualified: false,
      isItem: source.isItem,
      itemName: source.itemName,
    });

    let saved = await this.batches.save(batch);
    saved.qrPayload = `true_root://batch/${saved.id}`;
    saved = await this.batches.save(saved);
    return saved;
  }

  private async createRelation(
    parentId: number,
    childId: number,
    type: string,
    quantity: number,
  ) {
    const relation = this.relations.create({
      parentBatchId: parentId,
      childBatchId: childId,
      relationType: type,
      quantity,
    });
    return this.relations.save(relation);
  }
}
