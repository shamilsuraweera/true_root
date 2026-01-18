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
    const ownerIdNum = ownerId ? Number(ownerId) : NaN;
    const safeLimit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;
    if (Number.isFinite(ownerIdNum)) {
      return this.service.getRecentForOwner(ownerIdNum, safeLimit);
    }
    return this.service.getRecent(safeLimit);
  }

  @Get(':batchId')
  getByBatch(@Param('batchId') batchId: string) {
    return this.service.getByBatch(Number(batchId));
  }
}
