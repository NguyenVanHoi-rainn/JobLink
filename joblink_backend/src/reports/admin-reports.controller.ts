import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';

import { ReportsService } from './reports.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';

@Controller('admin/reports')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('ADMIN')
export class AdminReportsController {
  constructor(
    private readonly reportsService:
      ReportsService,
  ) {}

  @Get()
  getReports(
    @Query('status')
    status?: string,
  ) {
    return this.reportsService.getAdminReports(
      status,
    );
  }

  @Get(':id')
  getReport(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.reportsService.getAdminReportById(
      id,
    );
  }

  @Patch(':id/review')
  review(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.reportsService.startReview(
      id,
    );
  }

  @Patch(':id/resolve')
  resolve(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.reportsService.resolveReport(
      id,
    );
  }

  @Patch(':id/reject')
  reject(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.reportsService.rejectReport(
      id,
    );
  }
}