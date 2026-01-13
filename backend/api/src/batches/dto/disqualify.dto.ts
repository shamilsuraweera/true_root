import { IsString } from 'class-validator';

export class DisqualifyDto {
  @IsString()
  reason: string;
}
