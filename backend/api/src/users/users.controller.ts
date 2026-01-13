import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get()
  list() {
    return this.service.list();
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.service.getById(Number(id));
  }

  @Post()
  create(@Body() body: CreateUserDto) {
    return this.service.create(body.email, body.role);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() body: UpdateUserDto) {
    return this.service.update(Number(id), body);
  }
}
