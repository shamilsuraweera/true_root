import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UserRole } from './auth.types';
import { UsersService } from '../users/users.service';

@Injectable()
export class AuthService {
  constructor(private readonly users: UsersService) {}

  login(userId: number, role: UserRole) {
    return {
      user: {
        id: userId,
        role,
      },
    };
  }

  async loginWithPassword(email: string, password: string) {
    const user = await this.users.getByEmail(email, true);
    if (user.password !== password) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.login(user.id, user.role as UserRole);
  }

  async register(email: string, password: string, role: UserRole, name?: string) {
    const user = await this.users.create(email, role, password);
    if (name) {
      await this.users.update(user.id, { name });
    }
    return this.login(user.id, user.role as UserRole);
  }
}
