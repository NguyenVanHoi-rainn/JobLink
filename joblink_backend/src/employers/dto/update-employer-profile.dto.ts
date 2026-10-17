import {
  IsOptional,
  IsString,
  IsUrl,
} from 'class-validator';

export class UpdateEmployerProfileDto {
  @IsOptional()
  @IsString()
  companyName?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsUrl()
  logoUrl?: string;
}