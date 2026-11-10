import { IsBoolean, IsOptional } from 'class-validator';

export class ConfirmWorkAppointmentDto {
  @IsOptional()
  @IsBoolean()
  ignoreScheduleConflict?: boolean;
}
