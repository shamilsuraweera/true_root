import { IsInt, IsPositive, IsString, IsOptional } from 'class-validator';

export class CreateBatchDto {
  @IsInt()
  @IsPositive()
  productId: number;

  @IsInt()
  @IsPositive()
  quantity: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  ownerId?: number;

  @IsOptional()
  @IsString()
  grade?: string;
}
