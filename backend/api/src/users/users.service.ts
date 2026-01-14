import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { UserRole } from '../auth/auth.types';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  list() {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  create(email: string, role: UserRole, password?: string) {
    const user = this.repo.create({ email, role, password: password ?? 'password' });
    return this.repo.save(user);
  }

  async getById(id: number) {
    const user = await this.repo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getByEmail(email: string, includePassword = false) {
    const query = this.repo.createQueryBuilder('user').where('user.email = :email', { email });
    if (includePassword) {
      query.addSelect('user.password');
    }
    const user = await query.getOne();
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async update(id: number, data: UpdateUserDto) {
    const user = await this.getById(id);
    Object.assign(user, data);
    return this.repo.save(user);
  }
}
