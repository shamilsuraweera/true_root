import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Request } from 'express';

interface AuthRequest extends Request {
  user: {
    sub: number;
    role: string;
  };
}

export class RolesGuard implements CanActivate {
  constructor(private readonly requiredRole: string) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthRequest>();

    if (!request.user) {
      throw new ForbiddenException('No user in request');
    }

    if (request.user.role !== this.requiredRole) {
      throw new ForbiddenException('Insufficient role');
    }

    return true;
  }
}
