import { IsInt, IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';

export class TransformBatchDto {
  @IsInt()
  @IsPositive()
  productId: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  quantity?: number;

  @IsOptional()
  @IsString()
  grade?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsInt()
  @IsPositive()
  stageId?: number;

  @IsOptional()
  @IsString()
  unit?: string;
}
