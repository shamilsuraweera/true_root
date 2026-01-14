import { IsEmail, IsEnum, IsString } from 'class-validator';
import { UserRole } from '../../auth/auth.types';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;

  @IsEnum(UserRole)
  role: UserRole;
}
