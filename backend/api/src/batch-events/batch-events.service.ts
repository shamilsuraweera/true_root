import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BatchEvent, BatchEventType } from './batch-event.entity';

type BatchEventDetails = Partial<
  Pick<
    BatchEvent,
    | 'stageId'
    | 'description'
    | 'quantityBefore'
    | 'quantityAfter'
    | 'statusBefore'
    | 'statusAfter'
    | 'gradeBefore'
    | 'gradeAfter'
    | 'actorUserId'
    | 'metadata'
  >
>;

@Injectable()
export class BatchEventsService {
  constructor(
    @InjectRepository(BatchEvent)
    private readonly repo: Repository<BatchEvent>,
  ) {}

  async log(batchId: number, type: BatchEventType, description?: string, details?: BatchEventDetails) {
    const event = this.repo.create({
      batchId,
      type,
      description: description ?? null,
      ...details,
    });
    return this.repo.save(event);
  }

  async getByBatch(batchId: number) {
    return this.repo.find({
      where: { batchId },
      order: { createdAt: 'ASC' },
    });
  }

  async getRecent(limit = 10) {
    return this.repo.find({
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  async getRecentForOwner(ownerId: number, limit = 10) {
    return this.repo
      .createQueryBuilder('event')
      .innerJoin('batches', 'batch', 'batch.id = event.batch_id')
      .where('batch.owner_id = :ownerId', { ownerId })
      .orderBy('event.createdAt', 'DESC')
      .take(limit)
      .getMany();
  }
}
