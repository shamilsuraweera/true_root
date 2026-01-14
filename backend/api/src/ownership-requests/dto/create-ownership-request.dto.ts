import { IsInt, IsOptional, IsPositive, IsString } from 'class-validator';

export class CreateOwnershipRequestDto {
  @IsInt()
  @IsPositive()
  batchId: number;

  @IsInt()
  @IsPositive()
  requesterId: number;

  @IsInt()
  @IsPositive()
  ownerId: number;

  @IsPositive()
  quantity: number;

  @IsOptional()
  @IsString()
  note?: string;
}
