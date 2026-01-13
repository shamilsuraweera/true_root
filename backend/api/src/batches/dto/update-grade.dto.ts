import { IsString } from 'class-validator';

export class UpdateGradeDto {
  @IsString()
  grade: string;
}
