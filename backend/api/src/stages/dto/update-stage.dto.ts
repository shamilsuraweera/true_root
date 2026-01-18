import { IsBoolean, IsInt, IsOptional, IsString } from 'class-validator';

export class UpdateStageDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsInt()
  sequence?: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
