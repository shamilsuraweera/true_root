import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BatchEvent, BatchEventType } from './batch-event.entity';

@Injectable()
export class BatchEventsService {
  constructor(
    @InjectRepository(BatchEvent)
    private readonly repo: Repository<BatchEvent>,
  ) {}

  async log(batchId: number, type: BatchEventType, description: string) {
    const event = this.repo.create({ batchId, type, description });
    return this.repo.save(event);
  }

  async getByBatch(batchId: number) {
    return this.repo.find({
      where: { batchId },
      order: { createdAt: 'ASC' },
    });
  }
}
