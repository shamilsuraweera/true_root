import { IsEmail, IsEnum, IsOptional, IsString } from 'class-validator';
import { UserRole } from '../auth.types';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;

  @IsEnum(UserRole)
  role: UserRole;

  @IsOptional()
  @IsString()
  name?: string;
}
