import { IsArray, IsEmail, IsEnum, IsOptional, IsString } from 'class-validator';
import { UserRole } from '../../auth/auth.types';

export class UpdateUserDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  organization?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  accountType?: string;

  @IsOptional()
  @IsArray()
  members?: string[];
}
