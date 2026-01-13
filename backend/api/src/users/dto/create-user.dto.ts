import { IsEmail, IsEnum } from 'class-validator';
import { UserRole } from '../../auth/auth.types';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsEnum(UserRole)
  role: UserRole;
}
