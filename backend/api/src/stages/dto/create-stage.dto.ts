import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateStageDto {
  @IsString()
  name: string;

  @IsInt()
  @Min(0)
  sequence: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
