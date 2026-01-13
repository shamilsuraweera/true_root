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
    const batchCode = this.buildBatchCode();
    const batch = this.repo.create({
      productId,
      quantity,
      batchCode,
      unit: 'kg',
      grade: grade ?? null,
      status: 'CREATED',
      isDisqualified: false,
    });

    let saved = await this.repo.save(batch);
    saved.qrPayload = `true_root://batch/${saved.id}`;
    saved = await this.repo.save(saved);
    await this.events.log(saved.id, BatchEventType.CREATED, 'Batch created', {
      quantityAfter: saved.quantity,
      statusAfter: saved.status,
      gradeAfter: saved.grade ?? null,
    });
    return saved;
  }

  async getBatch(id: number) {
    const batch = await this.repo.findOne({ where: { id } });
    if (!batch) throw new NotFoundException('Batch not found');
    return batch;
  }

  async changeQuantity(id: number, quantity: number) {
    const batch = await this.getBatch(id);
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

  private buildBatchCode() {
    const suffix = Math.floor(Math.random() * 1000)
      .toString()
      .padStart(3, '0');
    return `BATCH-${Date.now()}-${suffix}`;
  }
}
