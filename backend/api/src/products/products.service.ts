import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './product.entity';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private readonly repo: Repository<Product>,
  ) {}

  list() {
    return this.repo.find({ order: { name: 'ASC' } });
  }

  create(name: string) {
    const product = this.repo.create({ name });
    return this.repo.save(product);
  }

  async update(id: number, name: string) {
    const product = await this.repo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    product.name = name;
    return this.repo.save(product);
  }

  async remove(id: number) {
    const product = await this.repo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    await this.repo.remove(product);
    return { success: true };
  }
}
