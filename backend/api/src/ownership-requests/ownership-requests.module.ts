import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OwnershipRequest } from './ownership-request.entity';
import { OwnershipRequestsController } from './ownership-requests.controller';
import { OwnershipRequestsService } from './ownership-requests.service';
import { Batch } from '../batches/batch.entity';
import { BatchRelation } from '../batches/batch-relation.entity';
import { BatchEventsModule } from '../batch-events/batch-events.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([OwnershipRequest, Batch, BatchRelation]),
    BatchEventsModule,
  ],
  controllers: [OwnershipRequestsController],
  providers: [OwnershipRequestsService],
})
export class OwnershipRequestsModule {}
