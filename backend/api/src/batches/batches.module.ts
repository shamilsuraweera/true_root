import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Batch } from './batch.entity';
import { BatchesService } from './batches.service';
import { BatchesController } from './batches.controller';
import { BatchEventsModule } from '../batch-events/batch-events.module';

@Module({
  imports: [TypeOrmModule.forFeature([Batch]), BatchEventsModule],
  providers: [BatchesService],
  controllers: [BatchesController],
})
export class BatchesModule {}
