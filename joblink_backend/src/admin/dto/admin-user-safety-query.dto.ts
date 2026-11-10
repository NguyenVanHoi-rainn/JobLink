import { IsIn, IsOptional } from 'class-validator';

export class AdminUserSafetyQueryDto {
  @IsOptional()
  @IsIn(['WORKER', 'EMPLOYER', 'ADMIN'])
  role?: 'WORKER' | 'EMPLOYER' | 'ADMIN';

  @IsOptional()
  @IsIn(['ACTIVE', 'LOCKED'])
  status?: 'ACTIVE' | 'LOCKED';
}
