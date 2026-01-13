import { ArrayMinSize, IsArray, IsInt, IsOptional, IsPositive, IsString } from 'class-validator';

export class MergeBatchesDto {
  @IsArray()
  @ArrayMinSize(2)
  @IsInt({ each: true })
  @IsPositive({ each: true })
  batchIds: number[];

  @IsInt()
  @IsPositive()
  productId: number;

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
