import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BatchEvent } from './batch-event.entity';

@Injectable()
export class BatchEventsService {
  constructor(
    @InjectRepository(BatchEvent)
    private readonly repo: Repository<BatchEvent>,
  ) {}

  findByBatchId(batchId: string) {
    return this.repo.find({
      where: { batchId },
      order: { createdAt: 'ASC' },
    });
  }
}
