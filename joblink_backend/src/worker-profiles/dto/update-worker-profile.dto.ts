import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsIn,
  IsInt,
  IsMilitaryTime,
  IsNumber,
  IsOptional,
//   IsPhoneNumber,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import {
  Type,
} from 'class-transformer';

export type WorkerSalaryTypeDto =
  | 'HOURLY'
  | 'DAILY'
  | 'SHIFT'
  | 'MONTHLY'
  | 'FIXED';

export type WorkerDayOfWeekDto =
  | 'MONDAY'
  | 'TUESDAY'
  | 'WEDNESDAY'
  | 'THURSDAY'
  | 'FRIDAY'
  | 'SATURDAY'
  | 'SUNDAY';

export class WorkerAvailabilityDto {
  @IsIn([
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ])
  dayOfWeek: WorkerDayOfWeekDto;

  @IsMilitaryTime()
  startTime: string;

  @IsMilitaryTime()
  endTime: string;
}

export class UpdateWorkerProfileDto {
  // =====================================================
  // BASIC
  // =====================================================

  @IsOptional()
  @IsString()
  @MaxLength(150)
  fullName?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  phone?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  bio?: string | null;

  // =====================================================
  // LOCATION
  // =====================================================

  @IsOptional()
  @IsString()
  @MaxLength(255)
  searchArea?: string | null;

  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  maxDistanceKm?: number | null;

  // =====================================================
  // SALARY
  // =====================================================

  @IsOptional()
  @IsNumber()
  @Min(0)
  preferredMinSalary?: number | null;

  @IsOptional()
  @IsIn([
    'HOURLY',
    'DAILY',
    'SHIFT',
    'MONTHLY',
    'FIXED',
  ])
  preferredSalaryType?:
    | WorkerSalaryTypeDto
    | null;

  // =====================================================
  // SKILLS
  // =====================================================

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(30)
  @IsUUID(
    '4',
    {
      each: true,
    },
  )
  skillIds?: string[];

  // =====================================================
  // INTERESTED CATEGORIES
  // =====================================================

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(15)
  @IsUUID(
    '4',
    {
      each: true,
    },
  )
  categoryIds?: string[];

  // =====================================================
  // AVAILABLE SCHEDULE
  // =====================================================

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @ValidateNested({
    each: true,
  })
  @Type(
    () => WorkerAvailabilityDto,
  )
  availabilities?:
    WorkerAvailabilityDto[];
}