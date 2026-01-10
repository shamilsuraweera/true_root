import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Batch, BatchGrade, BatchStatus } from './batch.entity';
import { Product } from '../products/product.entity';
import { BatchEvent, BatchEventType } from '../batch-events/batch-event.entity';

@Injectable()
export class BatchesService {
  constructor(
    @InjectRepository(Batch) private batchRepo: Repository<Batch>,
    @InjectRepository(Product) private productRepo: Repository<Product>,
    @InjectRepository(BatchEvent) private eventRepo: Repository<BatchEvent>,
  ) {}

  async createBatch(productId: number, quantity: number, grade: BatchGrade) {
    const product = await this.productRepo.findOne({ where: { id: productId } });
    if (!product) throw new NotFoundException('Product not found');

    const batch = this.batchRepo.create({
      product,
      quantity,
      grade,
      status: BatchStatus.CREATED,
    });

    const saved = await this.batchRepo.save(batch);

    await this.logEvent(saved, BatchEventType.CREATED, { quantity, grade });

    return saved;
  }

  async getBatch(id: string) {
    const batch = await this.batchRepo.findOne({
      where: { id },
      relations: ['product'],
    });
    if (!batch) throw new NotFoundException('Batch not found');
    return batch;
  }

  async changeQuantity(id: string, quantity: number) {
    const batch = await this.getBatch(id);
    batch.quantity = quantity;
    await this.batchRepo.save(batch);
    await this.logEvent(batch, BatchEventType.QUANTITY_CHANGED, { quantity });
    return batch;
  }

  async changeStatus(id: string, status: BatchStatus) {
    const batch = await this.getBatch(id);
    batch.status = status;
    await this.batchRepo.save(batch);
    await this.logEvent(batch, BatchEventType.STATUS_CHANGED, { status });
    return batch;
  }

  async changeGrade(id: string, grade: BatchGrade) {
    const batch = await this.getBatch(id);
    batch.grade = grade;
    await this.batchRepo.save(batch);
    await this.logEvent(batch, BatchEventType.GRADE_CHANGED, { grade });
    return batch;
  }

  async disqualify(id: string, reason: string) {
    const batch = await this.getBatch(id);
    batch.status = BatchStatus.DISQUALIFIED;
    await this.batchRepo.save(batch);
    await this.logEvent(batch, BatchEventType.DISQUALIFIED, { reason });
    return batch;
  }

  async history(id: string) {
    return this.eventRepo.find({
      where: { batch: { id } },
      order: { createdAt: 'ASC' },
    });
  }

  private async logEvent(batch: Batch, type: BatchEventType, metadata: any) {
    const event = this.eventRepo.create({ batch, type, metadata });
    await this.eventRepo.save(event);
  }
}
