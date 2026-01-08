import { Injectable } from '@nestjs/common';
import { UserRole } from './auth.types';

@Injectable()
export class AuthService {
  login(userId: number, role: UserRole) {
    return {
      accessToken: 'mock-jwt-token',
      user: {
        id: userId,
        role,
      },
    };
  }
}
