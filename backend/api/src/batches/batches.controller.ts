import { Controller, Post, Get, Patch, Param, Body, Query, Delete, UseGuards } from '@nestjs/common';
import { BatchesService } from './batches.service';
import { CreateBatchDto } from './dto/create-batch.dto';
import { UpdateQuantityDto } from './dto/update-quantity.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { UpdateGradeDto } from './dto/update-grade.dto';
import { DisqualifyDto } from './dto/disqualify.dto';
import { SplitBatchDto } from './dto/split-batch.dto';
import { MergeBatchesDto } from './dto/merge-batches.dto';
import { TransformBatchDto } from './dto/transform-batch.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('batches')
@UseGuards(JwtAuthGuard)
export class BatchesController {
  constructor(private readonly service: BatchesService) {}

  @Post()
  create(@Body() body: CreateBatchDto) {
    return this.service.createBatch(body.productId, body.quantity, body.grade, body.ownerId);
  }

  @Get()
  list(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('ownerId') ownerId?: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    const parsedLimit = limit ? Number(limit) : undefined;
    const parsedOffset = offset ? Number(offset) : undefined;
    const parsedOwnerId = ownerId ? Number(ownerId) : undefined;
    const parsedIncludeInactive = includeInactive === 'true';
    return this.service.listBatches(
      Number.isFinite(parsedLimit) ? parsedLimit : undefined,
      Number.isFinite(parsedOffset) ? parsedOffset : undefined,
      Number.isFinite(parsedOwnerId) ? parsedOwnerId : undefined,
      parsedIncludeInactive,
    );
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

  @Patch(':id/archive')
  archive(@Param('id') id: string) {
    return this.service.archiveBatch(Number(id));
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.deleteBatch(Number(id));
  }

  @Post(':id/split')
  split(@Param('id') id: string, @Body() body: SplitBatchDto) {
    return this.service.splitBatch(Number(id), body.items);
  }

  @Post('merge')
  merge(@Body() body: MergeBatchesDto) {
    return this.service.mergeBatches(body);
  }

  @Post(':id/transform')
  transform(@Param('id') id: string, @Body() body: TransformBatchDto) {
    return this.service.transformBatch(Number(id), body);
  }

  @Get(':id/history')
  history(@Param('id') id: string) {
    return this.service.history(Number(id));
  }

  @Get(':id/qr')
  qr(@Param('id') id: string) {
    return this.service.getQrPayload(Number(id));
  }

  @Get(':id/lineage')
  lineage(@Param('id') id: string) {
    return this.service.getLineage(Number(id));
  }
}
