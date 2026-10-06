import { IsNumber, IsPositive } from 'class-validator';

export class UpdateQuantityDto {
  @IsNumber()
  @IsPositive()
  quantity: number;
}
