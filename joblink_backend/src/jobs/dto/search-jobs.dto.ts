import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

import {
  Transform,
  Type,
} from 'class-transformer';

export enum JobSortDto {
  NEWEST = 'NEWEST',
  SALARY_ASC = 'SALARY_ASC',
  SALARY_DESC = 'SALARY_DESC',
  DISTANCE = 'DISTANCE',
}

export enum SalaryTypeFilterDto {
  HOURLY = 'HOURLY',
  DAILY = 'DAILY',
  SHIFT = 'SHIFT',
  MONTHLY = 'MONTHLY',
  FIXED = 'FIXED',
}

export enum ShiftTypeFilterDto {
  MORNING = 'MORNING',
  AFTERNOON = 'AFTERNOON',
  EVENING = 'EVENING',
  NIGHT = 'NIGHT',
  FLEXIBLE = 'FLEXIBLE',
}

export enum DayOfWeekFilterDto {
  MONDAY = 'MONDAY',
  TUESDAY = 'TUESDAY',
  WEDNESDAY = 'WEDNESDAY',
  THURSDAY = 'THURSDAY',
  FRIDAY = 'FRIDAY',
  SATURDAY = 'SATURDAY',
  SUNDAY = 'SUNDAY',
}

export class SearchJobsDto {
  // =====================================================
  // SEARCH
  // =====================================================

  @IsOptional()
  @IsString()
  keyword?: string;

  @IsOptional()
  @IsString()
  location?: string;

  // =====================================================
  // CATEGORY
  // =====================================================

  @IsOptional()
  @IsUUID('4')
  categoryId?: string;

  // =====================================================
  // SALARY
  // =====================================================

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minSalary?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxSalary?: number;

  @IsOptional()
  @IsEnum(SalaryTypeFilterDto)
  salaryType?: SalaryTypeFilterDto;

  // =====================================================
  // SHIFT
  // =====================================================

  @IsOptional()
  @IsEnum(ShiftTypeFilterDto)
  shiftType?: ShiftTypeFilterDto;

  // =====================================================
  // WORK DAYS
  // Ví dụ:
  // ?workDays=MONDAY,TUESDAY
  // =====================================================

  @IsOptional()
  @Transform(({ value }) => {
    if (Array.isArray(value)) {
      return value;
    }

    if (typeof value === 'string') {
      return value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
    }

    return value;
  })
  @IsEnum(
    DayOfWeekFilterDto,
    {
      each: true,
    },
  )
  workDays?: DayOfWeekFilterDto[];

  // =====================================================
  // SKILLS
  // Ví dụ:
  // ?skillIds=id1,id2,id3
  // =====================================================

  @IsOptional()
  @Transform(({ value }) => {
    if (Array.isArray(value)) {
      return value;
    }

    if (typeof value === 'string') {
      return value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
    }

    return value;
  })
  @IsUUID(
    '4',
    {
      each: true,
    },
  )
  skillIds?: string[];

  // =====================================================
  // CV
  // =====================================================

  @IsOptional()
  @Transform(({ value }) => {
    if (value === true || value === 'true') {
      return true;
    }

    if (value === false || value === 'false') {
      return false;
    }

    return value;
  })
  @IsBoolean()
  cvRequired?: boolean;

  // =====================================================
  // URGENT
  // =====================================================

  @IsOptional()
  @Transform(({ value }) => {
    if (value === true || value === 'true') {
      return true;
    }

    if (value === false || value === 'false') {
      return false;
    }

    return value;
  })
  @IsBoolean()
  urgent?: boolean;

  // =====================================================
  // DISTANCE
  // =====================================================

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  maxDistanceKm?: number;

  // =====================================================
  // SORT
  // =====================================================

  @IsOptional()
  @IsEnum(JobSortDto)
  sort?: JobSortDto;

  // =====================================================
  // PAGINATION
  // =====================================================

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}