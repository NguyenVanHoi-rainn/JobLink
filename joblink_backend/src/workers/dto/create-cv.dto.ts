import {
  IsNotEmpty,
  IsString,
} from 'class-validator';

export class CreateCvDto {
  @IsString()
  @IsNotEmpty()
  fileName: string;

  @IsString()
  @IsNotEmpty()
  fileUrl: string;
}