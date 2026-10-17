import {
  IsNotEmpty,
  IsString,
} from 'class-validator';

export class SubmitVerificationDto {
  @IsString()
  @IsNotEmpty()
  taxCode: string;
}