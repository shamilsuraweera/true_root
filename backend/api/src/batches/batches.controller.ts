import { Controller, Post, Get, Patch, Param, Body } from '@nestjs/common';
import { BatchesService } from './batches.service';
import { CreateBatchDto } from './dto/create-batch.dto';
import { UpdateQuantityDto } from './dto/update-quantity.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { UpdateGradeDto } from './dto/update-grade.dto';
import { DisqualifyDto } from './dto/disqualify.dto';

@Controller('batches')
export class BatchesController {
  constructor(private readonly service: BatchesService) {}

  @Post()
  create(@Body() body: CreateBatchDto) {
    return this.service.createBatch(body.productId, body.quantity, body.grade);
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.service.getBatch(Number(id));
  }

  @Patch(':id/quantity')
  changeQuantity(@Param('id') id: string, @Body() body: UpdateQuantityDto) {
    return this.service.changeQuantity(Number(id), body.quantity);
  }

  @Patch(':id/status')
  changeStatus(@Param('id') id: string, @Body() body: UpdateStatusDto) {
    return this.service.changeStatus(Number(id), body.status);
  }

  @Patch(':id/grade')
  changeGrade(@Param('id') id: string, @Body() body: UpdateGradeDto) {
    return this.service.changeGrade(Number(id), body.grade);
  }

  @Patch(':id/disqualify')
  disqualify(@Param('id') id: string, @Body() body: DisqualifyDto) {
    return this.service.disqualify(Number(id), body.reason);
  }

  @Get(':id/history')
  history(@Param('id') id: string) {
    return this.service.history(Number(id));
  }

  @Get(':id/qr')
  qr(@Param('id') id: string) {
    return this.service.getQrPayload(Number(id));
  }
}
