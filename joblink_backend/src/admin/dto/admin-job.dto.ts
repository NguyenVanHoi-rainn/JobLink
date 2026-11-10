import { IsIn } from 'class-validator';

export class UpdateAdminJobStatusDto {
  @IsIn(['DRAFT', 'PUBLISHED', 'CLOSED', 'HIDDEN'])
  status: 'DRAFT' | 'PUBLISHED' | 'CLOSED' | 'HIDDEN';
}
