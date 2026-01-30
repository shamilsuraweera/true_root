import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../admin/admin.guard';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Controller('products')
@UseGuards(JwtAuthGuard)
export class ProductsController {
  constructor(private readonly service: ProductsService) {}

  @Get()
  list() {
    return this.service.list();
  }

  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  create(@Body() body: CreateProductDto) {
    return this.service.create(body.name);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  update(@Param('id') id: string, @Body() body: UpdateProductDto) {
    return this.service.update(Number(id), body.name);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  remove(@Param('id') id: string) {
    return this.service.remove(Number(id));
  }
}
