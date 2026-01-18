import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Batch } from '../batches/batch.entity';
import { BatchEvent } from '../batch-events/batch-event.entity';
import { Product } from '../products/product.entity';
import { Stage } from '../stages/stage.entity';
import { User } from '../users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Product, Stage, Batch, BatchEvent])],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
