import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { UserRole } from '../auth/auth.types';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  list() {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  create(email: string, role: UserRole) {
    const user = this.repo.create({ email, role });
    return this.repo.save(user);
  }
}
