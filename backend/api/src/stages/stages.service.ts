import { Injectable } from '@nestjs/common';
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
}
