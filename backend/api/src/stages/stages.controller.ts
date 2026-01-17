import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { StagesService } from './stages.service';
import { CreateStageDto } from './dto/create-stage.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

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
}
