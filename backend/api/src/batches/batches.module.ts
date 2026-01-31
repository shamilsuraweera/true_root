import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Batch } from './batch.entity';
import { BatchRelation } from './batch-relation.entity';
import { BatchesService } from './batches.service';
import { BatchesController } from './batches.controller';
import { BatchEventsModule } from '../batch-events/batch-events.module';
import { Stage } from '../stages/stage.entity';
import { User } from '../users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Batch, BatchRelation, Stage, User]), BatchEventsModule],
  providers: [BatchesService],
  controllers: [BatchesController],
})
export class BatchesModule {}
