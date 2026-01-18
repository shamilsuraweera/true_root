import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Stage } from './stage.entity';

@Injectable()
export class StagesService {
  constructor(
    @InjectRepository(Stage)
    private readonly repo: Repository<Stage>,
  ) {}

  list() {
    return this.repo.find({ order: { sequence: 'ASC' } });
  }

  create(name: string, sequence: number, active?: boolean) {
    const stage = this.repo.create({
      name,
      sequence,
      active: active ?? true,
    });
    return this.repo.save(stage);
  }

  async update(id: number, data: Partial<Stage>) {
    const stage = await this.repo.findOne({ where: { id } });
    if (!stage) {
      throw new NotFoundException('Stage not found');
    }
    Object.assign(stage, data);
    return this.repo.save(stage);
  }

  async remove(id: number) {
    const stage = await this.repo.findOne({ where: { id } });
    if (!stage) {
      throw new NotFoundException('Stage not found');
    }
    await this.repo.remove(stage);
    return { success: true };
  }
}
