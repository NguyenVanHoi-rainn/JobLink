import { IsIn, IsOptional } from 'class-validator';

export class EmployerVerificationQueryDto {
  @IsOptional()
  @IsIn(['UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED'])
  status?: 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
}
