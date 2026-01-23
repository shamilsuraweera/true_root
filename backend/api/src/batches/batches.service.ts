import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Batch } from './batch.entity';
import { BatchRelation } from './batch-relation.entity';
import { BatchEventsService } from '../batch-events/batch-events.service';
import { BatchEventType } from '../batch-events/batch-event.entity';
import { MergeBatchesDto } from './dto/merge-batches.dto';
import { TransformBatchDto } from './dto/transform-batch.dto';

@Injectable()
export class BatchesService {
  constructor(
    @InjectRepository(Batch)
    private readonly repo: Repository<Batch>,
    @InjectRepository(BatchRelation)
    private readonly relations: Repository<BatchRelation>,
    private readonly events: BatchEventsService,
  ) {}

  private isLocked(batch: Batch) {
    return (
      batch.isDisqualified ||
      ['MERGED', 'TRANSFORMED', 'SPLIT', 'ARCHIVED', 'DELETED'].includes(batch.status)
    );
  }

  private async ensureMutable(batch: Batch) {
    if (this.isLocked(batch)) {
      throw new BadRequestException('Batch is locked and cannot be modified');
    }
    const childrenCount = await this.relations.count({ where: { parentBatchId: batch.id } });
    if (childrenCount > 0) {
      throw new BadRequestException('Batch has derived batches and cannot be modified');
    }
  }

  async createBatch(productId: number, quantity: number, grade?: string, ownerId?: number) {
    const saved = await this.createBatchRecord({
      productId,
      quantity,
      grade: grade ?? null,
      status: 'CREATED',
      unit: 'kg',
      stageId: null,
      ownerId: ownerId ?? 1,
    });
    await this.events.log(saved.id, BatchEventType.CREATED, 'Batch created', {
      quantityAfter: saved.quantity,
      statusAfter: saved.status,
      gradeAfter: saved.grade ?? null,
    });
    return saved;
  }

  async listBatches(limit = 20, offset = 0, ownerId?: number, includeInactive = false) {
    const qb = this.repo
      .createQueryBuilder('batch')
      .orderBy('batch.createdAt', 'DESC')
      .take(limit)
      .skip(offset);

    if (ownerId) {
      qb.andWhere('batch.owner_id = :ownerId', { ownerId });
    }

    if (!includeInactive) {
      qb.andWhere('batch.quantity > 0');
      qb.andWhere('batch.status NOT IN (:...hidden)', {
        hidden: ['MERGED', 'TRANSFORMED', 'SPLIT', 'DELETED'],
      });
    }

    return qb.getMany();
  }

  async getBatch(id: number) {
    const batch = await this.repo.findOne({ where: { id } });
    if (!batch) throw new NotFoundException('Batch not found');
    return batch;
  }

  async changeQuantity(id: number, quantity: number) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previous = batch.quantity;
    batch.quantity = quantity;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.QUANTITY_CHANGED, `Quantity set to ${quantity}`, {
      quantityBefore: previous,
      quantityAfter: quantity,
    });
    return saved;
  }

  async changeStatus(id: number, status: string) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previous = batch.status;
    batch.status = status;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.STATUS_CHANGED, `Status set to ${status}`, {
      statusBefore: previous,
      statusAfter: status,
    });
    return saved;
  }

  async changeGrade(id: number, grade: string) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previous = batch.grade ?? null;
    batch.grade = grade;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.GRADE_CHANGED, `Grade set to ${grade}`, {
      gradeBefore: previous,
      gradeAfter: grade,
    });
    return saved;
  }

  async disqualify(id: number, reason: string) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previous = batch.status;
    batch.status = 'DISQUALIFIED';
    batch.isDisqualified = true;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.DISQUALIFIED, reason, {
      statusBefore: previous,
      statusAfter: batch.status,
    });
    return saved;
  }

  async archiveBatch(id: number) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previous = batch.status;
    batch.status = 'ARCHIVED';
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.ARCHIVED, 'Batch archived', {
      statusBefore: previous,
      statusAfter: batch.status,
    });
    return saved;
  }

  async deleteBatch(id: number) {
    const batch = await this.getBatch(id);
    await this.ensureMutable(batch);
    const previousStatus = batch.status;
    const previousQuantity = batch.quantity;
    batch.status = 'DELETED';
    batch.quantity = 0;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.DELETED, 'Batch deleted', {
      statusBefore: previousStatus,
      statusAfter: saved.status,
      quantityBefore: previousQuantity,
      quantityAfter: saved.quantity,
    });
    return { deleted: true };
  }

  async history(id: number) {
    await this.getBatch(id);
    return this.events.getByBatch(id);
  }

  async getQrPayload(id: number) {
    const batch = await this.getBatch(id);
    return {
      batchId: batch.id,
      payload: batch.qrPayload ?? `true_root://batch/${batch.id}`,
    };
  }

  async getLineage(id: number) {
    await this.getBatch(id);

    const parents = await this.relations.find({
      where: { childBatchId: id },
      order: { createdAt: 'DESC' },
    });
    const children = await this.relations.find({
      where: { parentBatchId: id },
      order: { createdAt: 'DESC' },
    });

    const parentIds = parents.map((item) => item.parentBatchId);
    const childIds = children.map((item) => item.childBatchId);
    const batches = await this.repo.findBy({ id: In([...parentIds, ...childIds]) });
    const batchMap = new Map(batches.map((batch) => [batch.id, batch]));

    return {
      parents: parents.map((relation) => ({
        ...relation,
        batch: batchMap.get(relation.parentBatchId) ?? null,
      })),
      children: children.map((relation) => ({
        ...relation,
        batch: batchMap.get(relation.childBatchId) ?? null,
      })),
    };
  }

  async splitBatch(id: number, items: { quantity: number; grade?: string }[]) {
    if (!items || items.length < 2) {
      throw new BadRequestException('At least two split items are required');
    }

    const parent = await this.getBatch(id);
    await this.ensureMutable(parent);
    const total = items.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
    if (total <= 0) {
      throw new BadRequestException('Split quantity must be greater than zero');
    }
    if (total > Number(parent.quantity)) {
      throw new BadRequestException('Split quantity exceeds available quantity');
    }

    const previousQuantity = parent.quantity;
    parent.quantity = Number(parent.quantity) - total;
    if (parent.quantity === 0) {
      parent.status = 'SPLIT';
    }
    const savedParent = await this.repo.save(parent);

    const children: Batch[] = [];
    for (const item of items) {
    const child = await this.createBatchRecord({
      productId: parent.productId,
      quantity: item.quantity,
      grade: item.grade ?? parent.grade ?? null,
      status: parent.status === 'SPLIT' ? 'CREATED' : parent.status,
      unit: parent.unit,
      stageId: parent.stageId ?? null,
      ownerId: parent.ownerId ?? null,
    });
      await this.createRelation(parent.id, child.id, 'SPLIT', child.quantity);
      await this.events.log(child.id, BatchEventType.SPLIT, `Split from batch ${parent.id}`, {
        quantityAfter: child.quantity,
      });
      children.push(child);
    }

    await this.events.log(parent.id, BatchEventType.SPLIT, `Split into ${children.length} batches`, {
      quantityBefore: previousQuantity,
      quantityAfter: savedParent.quantity,
      metadata: { children: children.map((child) => child.id) },
    });

    return { parent: savedParent, children };
  }

  async mergeBatches(body: MergeBatchesDto) {
    const uniqueIds = Array.from(new Set(body.batchIds));
    if (uniqueIds.length < 2) {
      throw new BadRequestException('At least two unique batches are required');
    }

    const batches = await this.repo.findBy({ id: In(uniqueIds) });
    if (batches.length !== uniqueIds.length) {
      throw new NotFoundException('One or more batches not found');
    }
    await Promise.all(batches.map((batch) => this.ensureMutable(batch)));

    const totalQuantity = batches.reduce((sum, batch) => sum + Number(batch.quantity), 0);
    const newBatch = await this.createBatchRecord({
      productId: body.productId,
      quantity: totalQuantity,
      grade: body.grade ?? null,
      status: body.status ?? 'CREATED',
      unit: body.unit ?? batches[0].unit,
      stageId: body.stageId ?? null,
      ownerId: batches[0].ownerId ?? null,
    });

    for (const batch of batches) {
      const previousStatus = batch.status;
      const previousQuantity = batch.quantity;
      batch.status = 'MERGED';
      batch.quantity = 0;
      await this.repo.save(batch);
      await this.createRelation(batch.id, newBatch.id, 'MERGE', Number(previousQuantity));
      await this.events.log(batch.id, BatchEventType.MERGED, `Merged into batch ${newBatch.id}`, {
        statusBefore: previousStatus,
        statusAfter: batch.status,
      });
    }

    await this.events.log(newBatch.id, BatchEventType.MERGED, `Merged from batches ${uniqueIds.join(', ')}`, {
      quantityAfter: newBatch.quantity,
      metadata: { sources: uniqueIds },
    });

    return newBatch;
  }

  async transformBatch(id: number, body: TransformBatchDto) {
    const parent = await this.getBatch(id);
    await this.ensureMutable(parent);
    const quantity = body.quantity ?? Number(parent.quantity);
    if (quantity <= 0) {
      throw new BadRequestException('Transform quantity must be greater than zero');
    }
    if (quantity > Number(parent.quantity)) {
      throw new BadRequestException('Transform quantity exceeds available quantity');
    }

    const previousQuantity = parent.quantity;
    parent.quantity = Number(parent.quantity) - quantity;
    if (parent.quantity === 0) {
      parent.status = 'TRANSFORMED';
    }
    const savedParent = await this.repo.save(parent);

    const newBatch = await this.createBatchRecord({
      productId: body.productId,
      quantity,
      grade: body.grade ?? parent.grade ?? null,
      status: body.status ?? 'CREATED',
      unit: body.unit ?? parent.unit,
      stageId: body.stageId ?? parent.stageId ?? null,
      ownerId: parent.ownerId ?? null,
    });

    await this.createRelation(parent.id, newBatch.id, 'TRANSFORM', quantity);
    await this.events.log(parent.id, BatchEventType.TRANSFORMED, `Transformed into batch ${newBatch.id}`, {
      quantityBefore: previousQuantity,
      quantityAfter: savedParent.quantity,
      metadata: { targetBatchId: newBatch.id },
    });
    await this.events.log(newBatch.id, BatchEventType.TRANSFORMED, `Transformed from batch ${parent.id}`, {
      quantityAfter: newBatch.quantity,
      metadata: { sourceBatchId: parent.id },
    });

    return { parent: savedParent, transformed: newBatch };
  }

  private buildBatchCode() {
    const suffix = Math.floor(Math.random() * 1000)
      .toString()
      .padStart(3, '0');
    return `BATCH-${Date.now()}-${suffix}`;
  }

  private async createBatchRecord(params: {
    productId: number;
    quantity: number;
    grade: string | null;
    status: string;
    unit: string;
    stageId: number | null;
    ownerId: number | null;
  }) {
    const batchCode = this.buildBatchCode();
    const batch = this.repo.create({
      productId: params.productId,
      ownerId: params.ownerId,
      quantity: params.quantity,
      batchCode,
      unit: params.unit,
      grade: params.grade,
      status: params.status,
      stageId: params.stageId,
      isDisqualified: false,
    });

    let saved = await this.repo.save(batch);
    saved.qrPayload = `true_root://batch/${saved.id}`;
    saved = await this.repo.save(saved);
    return saved;
  }

  private async createRelation(parentId: number, childId: number, type: string, quantity?: number) {
    const relation = this.relations.create({
      parentBatchId: parentId,
      childBatchId: childId,
      relationType: type,
      quantity: quantity ?? null,
    });
    return this.relations.save(relation);
  }
}
