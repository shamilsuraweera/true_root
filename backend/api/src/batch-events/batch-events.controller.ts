import { Controller, Get, Param } from '@nestjs/common';
import { BatchEventsService } from './batch-events.service';

@Controller('batches')
export class BatchEventsController {
  constructor(private readonly service: BatchEventsService) {}

  @Get(':id/history')
  getHistory(@Param('id') id: string) {
    return this.service.findByBatchId(id);
  }
}
