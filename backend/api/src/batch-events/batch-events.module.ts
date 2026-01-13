import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BatchEvent } from './batch-event.entity';
import { BatchEventsService } from './batch-events.service';
import { BatchEventsController } from './batch-events.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BatchEvent])],
  providers: [BatchEventsService],
  controllers: [BatchEventsController],
  exports: [BatchEventsService],
})
export class BatchEventsModule {}
