import { IsInt, IsPositive } from 'class-validator';

export class UpdateQuantityDto {
  @IsInt()
  @IsPositive()
  quantity: number;
}
