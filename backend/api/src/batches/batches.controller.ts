import { Controller, Post, Get, Patch, Param, Body } from '@nestjs/common';
import { BatchesService } from './batches.service';
import { BatchGrade, BatchStatus } from './batch.entity';

@Controller('batches')
export class BatchesController {
  constructor(private readonly service: BatchesService) {}

  @Post()
  create(
    @Body() body: { productId: number; quantity: number; grade: BatchGrade },
  ) {
    return this.service.createBatch(body.productId, body.quantity, body.grade);
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.service.getBatch(id);
  }

  @Patch(':id/quantity')
  changeQuantity(@Param('id') id: string, @Body() body: { quantity: number }) {
    return this.service.changeQuantity(id, body.quantity);
  }

  @Patch(':id/status')
  changeStatus(@Param('id') id: string, @Body() body: { status: BatchStatus }) {
    return this.service.changeStatus(id, body.status);
  }

  @Patch(':id/grade')
  changeGrade(@Param('id') id: string, @Body() body: { grade: BatchGrade }) {
    return this.service.changeGrade(id, body.grade);
  }

  @Patch(':id/disqualify')
  disqualify(@Param('id') id: string, @Body() body: { reason: string }) {
    return this.service.disqualify(id, body.reason);
  }

  @Get(':id/history')
  history(@Param('id') id: string) {
    return this.service.history(id);
  }
}
