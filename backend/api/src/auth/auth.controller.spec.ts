import { Controller, Post, Body } from '@nestjs/common';
import { AuthService, UserRole } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  login(@Body() body: { userId: number; role: UserRole }) {
    return this.authService.login(body.userId, body.role);
  }
}
