import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';

import { AdminDashboardService } from './admin-dashboard.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';

@Controller('admin/dashboard')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('ADMIN')
export class AdminDashboardController {
  constructor(
    private readonly adminDashboardService:
      AdminDashboardService,
  ) {}

  @Get('overview')
  getOverview() {
    return this.adminDashboardService.getOverview();
  }

  @Get('users-by-role')
  getUsersByRole() {
    return this.adminDashboardService.getUsersByRole();
  }

  @Get('jobs-by-status')
  getJobsByStatus() {
    return this.adminDashboardService.getJobsByStatus();
  }

  @Get('applications-by-status')
  getApplicationsByStatus() {
    return this.adminDashboardService.getApplicationsByStatus();
  }

  @Get('reports-by-status')
  getReportsByStatus() {
    return this.adminDashboardService.getReportsByStatus();
  }

  @Get('appointments-by-status')
  getAppointmentsByStatus() {
    return this.adminDashboardService.getAppointmentsByStatus();
  }
}