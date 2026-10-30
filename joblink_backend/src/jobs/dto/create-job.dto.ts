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

import {
  Type,
} from 'class-transformer';

export type SalaryTypeDto =
  | 'HOURLY'
  | 'DAILY'
  | 'SHIFT'
  | 'MONTHLY'
  | 'FIXED';

export type ShiftTypeDto =
  | 'MORNING'
  | 'AFTERNOON'
  | 'EVENING'
  | 'NIGHT'
  | 'FLEXIBLE';

export type JobDayOfWeekDto =
  | 'MONDAY'
  | 'TUESDAY'
  | 'WEDNESDAY'
  | 'THURSDAY'
  | 'FRIDAY'
  | 'SATURDAY'
  | 'SUNDAY';

export class CreateJobDto {
  // =====================================================
  // BASIC
  // =====================================================

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsUUID('4')
  categoryId: string;

  // =====================================================
  // SALARY
  // =====================================================

  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  salary: number;

  @IsIn([
    'HOURLY',
    'DAILY',
    'SHIFT',
    'MONTHLY',
    'FIXED',
  ])
  salaryType: SalaryTypeDto;

  // =====================================================
  // LOCATION
  // =====================================================

  @IsString()
  @IsNotEmpty()
  location: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number;

  // =====================================================
  // WORK SCHEDULE
  // =====================================================

  @IsIn([
    'MORNING',
    'AFTERNOON',
    'EVENING',
    'NIGHT',
    'FLEXIBLE',
  ])
  shiftType: ShiftTypeDto;

  @IsMilitaryTime()
  startTime: string;

  @IsMilitaryTime()
  endTime: string;

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
  workDays: JobDayOfWeekDto[];

  // =====================================================
  // URGENT
  // =====================================================

  @IsOptional()
  @IsBoolean()
  urgent?: boolean;

  @IsOptional()
  @IsDateString()
  urgentUntil?: string;

  // =====================================================
  // CV
  // =====================================================

  @IsOptional()
  @IsBoolean()
  cvRequired?: boolean;

  // =====================================================
  // DEADLINE
  // =====================================================

  @IsOptional()
  @IsDateString()
  deadline?: string;

  // =====================================================
  // SKILLS
  // =====================================================

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID(
    '4',
    {
      each: true,
    },
  )
  skillIds?: string[];
}