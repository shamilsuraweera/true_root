import { IsOptional, IsString } from 'class-validator';

export class UpdateOwnershipRequestDto {
  @IsOptional()
  @IsString()
  note?: string;
}
