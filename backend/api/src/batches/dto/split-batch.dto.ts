import { Type } from 'class-transformer';
import { ArrayMinSize, IsNumber, IsOptional, IsString, IsPositive, ValidateNested } from 'class-validator';

export class SplitItemDto {
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  quantity: number;

  @IsOptional()
  @IsString()
  grade?: string;
}

export class SplitBatchDto {
  @ArrayMinSize(2)
  @ValidateNested({ each: true })
  @Type(() => SplitItemDto)
  items: SplitItemDto[];
}
