import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { BatchEventsService } from './batch-events.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('batch-events')
@UseGuards(JwtAuthGuard)
export class BatchEventsController {
  constructor(private readonly service: BatchEventsService) {}

  @Get('recent')
  recent(@Query('limit') limit?: string, @Query('ownerId') ownerId?: string) {
    const parsedLimit = limit ? Number(limit) : undefined;
    const parsedOwnerId = ownerId ? Number(ownerId) : undefined;
    if (Number.isFinite(parsedOwnerId)) {
      return this.service.getRecentForOwner(
        parsedOwnerId,
        Number.isFinite(parsedLimit) ? parsedLimit : undefined,
      );
    }
    return this.service.getRecent(Number.isFinite(parsedLimit) ? parsedLimit : undefined);
  }

  @Get(':batchId')
  getByBatch(@Param('batchId') batchId: string) {
    return this.service.getByBatch(Number(batchId));
  }
}
