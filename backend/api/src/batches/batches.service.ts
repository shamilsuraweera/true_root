import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Batch } from './batch.entity';
import { BatchEventsService } from '../batch-events/batch-events.service';
import { BatchEventType } from '../batch-events/batch-event.entity';

@Injectable()
export class BatchesService {
  constructor(
    @InjectRepository(Batch)
    private readonly repo: Repository<Batch>,
    private readonly events: BatchEventsService,
  ) {}

  async createBatch(productId: number, quantity: number, grade?: string) {
    const batch = this.repo.create({
      productId,
      quantity,
      grade: grade ?? null,
      status: 'CREATED',
    });

    const saved = await this.repo.save(batch);
    await this.events.log(saved.id, BatchEventType.CREATED, 'Batch created');
    return saved;
  }

  async getBatch(id: number) {
    const batch = await this.repo.findOne({ where: { id } });
    if (!batch) throw new NotFoundException('Batch not found');
    return batch;
  }

  async changeQuantity(id: number, quantity: number) {
    const batch = await this.getBatch(id);
    batch.quantity = quantity;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.QUANTITY_CHANGED, `Quantity set to ${quantity}`);
    return saved;
  }

  async changeStatus(id: number, status: string) {
    const batch = await this.getBatch(id);
    batch.status = status;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.STATUS_CHANGED, `Status set to ${status}`);
    return saved;
  }

  async changeGrade(id: number, grade: string) {
    const batch = await this.getBatch(id);
    batch.grade = grade;
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.GRADE_CHANGED, `Grade set to ${grade}`);
    return saved;
  }

  async disqualify(id: number, reason: string) {
    const batch = await this.getBatch(id);
    batch.status = 'DISQUALIFIED';
    const saved = await this.repo.save(batch);
    await this.events.log(id, BatchEventType.DISQUALIFIED, reason);
    return saved;
  }

  async history(id: number) {
    await this.getBatch(id);
    return this.events.getByBatch(id);
  }

  async getQrPayload(id: number) {
    const batch = await this.getBatch(id);
    return {
      batchId: batch.id,
      payload: `true_root://batch/${batch.id}`,
    };
  }
}
