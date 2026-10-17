import {
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  ValidateIf,
} from 'class-validator';

export class UpdateWorkExperienceDto {
  @IsOptional()
  @IsString()
  companyName?: string;

  @IsOptional()
  @IsString()
  position?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ValidateIf(
    (_, value) =>
      value !== undefined && value !== null,
  )
  @IsDateString()
  endDate?: string | null;

  @IsOptional()
  @IsBoolean()
  isCurrent?: boolean;
}