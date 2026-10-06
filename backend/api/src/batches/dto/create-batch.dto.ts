import { IsInt, IsNumber, IsPositive, IsString, IsOptional } from 'class-validator';

export class CreateBatchDto {
  @IsInt()
  @IsPositive()
  productId: number;

  @IsNumber()
  @IsPositive()
  quantity: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  ownerId?: number;

  @IsOptional()
  @IsString()
  grade?: string;

  @IsOptional()
  @IsInt()
  @IsPositive()
  stageId?: number;

  @IsOptional()
  @IsString()
  unit?: string;
}
