import {
  IsDateString,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateWorkAppointmentDto {
  @IsDateString()
  appointmentDate: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  location: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  instruction?: string;
}