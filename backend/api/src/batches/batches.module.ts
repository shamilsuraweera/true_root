import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BatchesService } from './batches.service';
import { BatchesController } from './batches.controller';
import { Batch } from './batch.entity';
import { Product } from '../products/product.entity';
import { BatchEvent } from '../batch-events/batch-event.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Batch, Product, BatchEvent])],
  providers: [BatchesService],
  controllers: [BatchesController],
})
export class BatchesModule {}
