import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { StagesService } from './stages.service';
import { CreateStageDto } from './dto/create-stage.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateStageDto } from './dto/update-stage.dto';

@Controller('stages')
@UseGuards(JwtAuthGuard)
export class StagesController {
  constructor(private readonly service: StagesService) {}

  @Get()
  list() {
    return this.service.list();
  }

  @Post()
  create(@Body() body: CreateStageDto) {
    return this.service.create(body.name, body.sequence, body.active);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() body: UpdateStageDto) {
    return this.service.update(Number(id), body);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(Number(id));
  }
}
