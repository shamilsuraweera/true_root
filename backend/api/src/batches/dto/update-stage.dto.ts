import { IsInt, IsOptional } from 'class-validator';

export class UpdateStageDto {
  @IsOptional()
  @IsInt()
  stageId?: number | null;
}
