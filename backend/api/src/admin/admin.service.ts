import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Batch } from '../batches/batch.entity';
import { BatchEvent } from '../batch-events/batch-event.entity';
import { Product } from '../products/product.entity';
import { Stage } from '../stages/stage.entity';
import { User } from '../users/user.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(Product)
    private readonly products: Repository<Product>,
    @InjectRepository(Stage)
    private readonly stages: Repository<Stage>,
    @InjectRepository(Batch)
    private readonly batches: Repository<Batch>,
    @InjectRepository(BatchEvent)
    private readonly events: Repository<BatchEvent>,
  ) {}

  async getOverview(limit = 10) {
    const [users, products, stages, batches] = await Promise.all([
      this.users.count(),
      this.products.count(),
      this.stages.count(),
      this.batches.count(),
    ]);

    const recentEvents = await this.events.find({
      order: { createdAt: 'DESC' },
      take: limit,
    });

    return {
      counts: {
        users,
        products,
        stages,
        batches,
      },
      recentEvents,
    };
  }
}
