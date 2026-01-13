import { Controller, Get, Query } from '@nestjs/common';
import { RequestsService } from './requests.service';

@Controller('requests')
export class RequestsController {
  constructor(private readonly service: RequestsService) {}

  @Get('pending')
  pending(@Query('limit') limit?: string) {
    const parsedLimit = limit ? Number(limit) : undefined;
    return this.service.listPending(Number.isFinite(parsedLimit) ? parsedLimit : undefined);
  }
}
