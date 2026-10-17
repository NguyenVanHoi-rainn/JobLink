import {
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class ApplyJobDto {
  @IsOptional()
  @IsUUID('4')
  cvId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}