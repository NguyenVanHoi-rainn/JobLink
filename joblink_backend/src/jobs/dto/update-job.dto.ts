import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsMilitaryTime,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
} from 'class-validator';

import { Type } from 'class-transformer';

export type UpdateSalaryTypeDto =
  | 'HOURLY'
  | 'DAILY'
  | 'SHIFT'
  | 'MONTHLY'
  | 'FIXED';

export type UpdateShiftTypeDto =
  | 'MORNING'
  | 'AFTERNOON'
  | 'EVENING'
  | 'NIGHT'
  | 'FLEXIBLE';

export type UpdateJobDayOfWeekDto =
  | 'MONDAY'
  | 'TUESDAY'
  | 'WEDNESDAY'
  | 'THURSDAY'
  | 'FRIDAY'
  | 'SATURDAY'
  | 'SUNDAY';

export class UpdateJobDto {
  // =====================================================
  // BASIC
  // =====================================================

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  title?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  description?: string;

  @IsOptional()
  @IsUUID('4')
  categoryId?: string;

  // =====================================================
  // SALARY
  // =====================================================

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  salary?: number;

  @IsOptional()
  @IsIn([
    'HOURLY',
    'DAILY',
    'SHIFT',
    'MONTHLY',
    'FIXED',
  ])
  salaryType?: UpdateSalaryTypeDto;

  // =====================================================
  // LOCATION
  // =====================================================

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  location?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number | null;

  // =====================================================
  // WORK SCHEDULE
  // =====================================================

  @IsOptional()
  @IsIn([
    'MORNING',
    'AFTERNOON',
    'EVENING',
    'NIGHT',
    'FLEXIBLE',
  ])
  shiftType?: UpdateShiftTypeDto;

  @IsOptional()
  @IsMilitaryTime()
  startTime?: string;

  @IsOptional()
  @IsMilitaryTime()
  endTime?: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(
    [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ],
    {
      each: true,
    },
  )
  workDays?: UpdateJobDayOfWeekDto[];

  // =====================================================
  // URGENT
  // =====================================================

  @IsOptional()
  @IsBoolean()
  urgent?: boolean;

  @IsOptional()
  @IsDateString()
  urgentUntil?: string | null;

  // =====================================================
  // CV
  // =====================================================

  @IsOptional()
  @IsBoolean()
  cvRequired?: boolean;

  // =====================================================
  // DEADLINE
  //
  // null = bỏ deadline
  // =====================================================

  @IsOptional()
  @IsDateString()
  deadline?: string | null;

  // =====================================================
  // SKILLS
  // =====================================================

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', {
    each: true,
  })
  skillIds?: string[];
}