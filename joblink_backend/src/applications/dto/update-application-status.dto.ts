import { IsEnum } from 'class-validator';

export enum EmployerApplicationStatusDto {
  REVIEWING = 'REVIEWING',
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED',
}

export class UpdateApplicationStatusDto {
  @IsEnum(EmployerApplicationStatusDto)
  status: EmployerApplicationStatusDto;
}