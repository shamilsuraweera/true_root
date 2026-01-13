import { Body, Controller, Get, Post } from '@nestjs/common';
import { StagesService } from './stages.service';
import { CreateStageDto } from './dto/create-stage.dto';

@Controller('stages')
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
