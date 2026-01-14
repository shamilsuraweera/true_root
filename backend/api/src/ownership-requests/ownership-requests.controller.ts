import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { OwnershipRequestsService } from './ownership-requests.service';
import { CreateOwnershipRequestDto } from './dto/create-ownership-request.dto';
import { UpdateOwnershipRequestDto } from './dto/update-ownership-request.dto';

@Controller('ownership-requests')
export class OwnershipRequestsController {
  constructor(private readonly service: OwnershipRequestsService) {}

  @Post()
  create(@Body() body: CreateOwnershipRequestDto) {
    return this.service.createRequest(
      body.batchId,
      body.requesterId,
      body.ownerId,
      body.quantity,
      body.note,
    );
  }

  @Get('inbox')
  inbox(@Query('ownerId') ownerId: string, @Query('limit') limit?: string) {
    const parsedLimit = limit ? Number(limit) : undefined;
    return this.service.listInbox(
      Number(ownerId),
      Number.isFinite(parsedLimit) ? parsedLimit : undefined,
    );
  }

  @Get('outbox')
  outbox(@Query('requesterId') requesterId: string, @Query('limit') limit?: string) {
    const parsedLimit = limit ? Number(limit) : undefined;
    return this.service.listOutbox(
      Number(requesterId),
      Number.isFinite(parsedLimit) ? parsedLimit : undefined,
    );
  }

  @Patch(':id/approve')
  approve(@Param('id') id: string) {
    return this.service.approve(Number(id));
  }

  @Patch(':id/reject')
  reject(@Param('id') id: string, @Body() body: UpdateOwnershipRequestDto) {
    return this.service.reject(Number(id), body.note);
  }
}
