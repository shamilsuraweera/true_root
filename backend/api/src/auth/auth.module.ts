import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import type { StringValue } from 'ms';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    UsersModule,
    PassportModule,
    JwtModule.register({
      secret: resolveJwtSecret(),
      signOptions: {
        expiresIn: resolveJwtExpiresIn(process.env.JWT_EXPIRES_IN),
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
})
export class AuthModule {}

function resolveJwtExpiresIn(value?: string): number | StringValue {
  if (!value || value.trim().length == 0) {
    return '7d' as StringValue;
  }
  const numeric = Number(value);
  if (Number.isFinite(numeric)) {
    return numeric;
  }
  return value as StringValue;
}

function resolveJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim().length === 0) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('JWT_SECRET is required in production');
    }
    return 'dev-secret';
  }
  return secret;
}
