import { Controller, Get, Param } from '@nestjs/common';
import { BatchEventsService } from './batch-events.service';

@Controller('batch-events')
export class BatchEventsController {
  constructor(private readonly service: BatchEventsService) {}

  @Get(':batchId')
  getByBatch(@Param('batchId') batchId: string) {
    return this.service.getByBatch(Number(batchId));
  }
}
