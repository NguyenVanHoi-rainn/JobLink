import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsString,
  MinLength,
} from 'class-validator';

export enum RegisterRole {
  WORKER = 'WORKER',
  EMPLOYER = 'EMPLOYER',
}

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsEnum(RegisterRole)
  role: RegisterRole;

  @IsString()
  @IsNotEmpty()
  name: string;
}