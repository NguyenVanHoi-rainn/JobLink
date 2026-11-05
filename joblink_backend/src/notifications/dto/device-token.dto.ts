import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class DeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  token!: string;

  @IsOptional()
  @IsString()
  @IsIn([
    'android',
    'ios',
    'web',
  ])
  platform?: string;
}
