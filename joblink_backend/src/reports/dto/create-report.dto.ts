import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateReportDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  targetType: string;

  @IsUUID()
  targetId: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  reason: string;

  @IsOptional()
  @IsString()
  description?: string;
}