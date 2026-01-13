import { Controller, Get, Param, Query } from '@nestjs/common';
import { BatchEventsService } from './batch-events.service';

@Controller('batch-events')
export class BatchEventsController {
  constructor(private readonly service: BatchEventsService) {}

  @Get('recent')
  recent(@Query('limit') limit?: string) {
    const parsedLimit = limit ? Number(limit) : undefined;
    return this.service.getRecent(Number.isFinite(parsedLimit) ? parsedLimit : undefined);
  }

  @Get(':batchId')
  getByBatch(@Param('batchId') batchId: string) {
    return this.service.getByBatch(Number(batchId));
  }
}
