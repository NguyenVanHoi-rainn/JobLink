import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { ReportsService } from './reports.service.js';

import { CreateReportDto } from './dto/create-report.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('reports')
@UseGuards(
  JwtAuthGuard,
)
export class ReportsController {
  constructor(
    private readonly reportsService:
      ReportsService,
  ) {}

  @Post()
  createReport(
    @CurrentUser()
    user: any,

    @Body()
    dto: CreateReportDto,
  ) {
    return this.reportsService.createReport(
      user.sub,
      dto,
    );
  }

  @Get('me')
  getMyReports(
    @CurrentUser()
    user: any,
  ) {
    return this.reportsService.getMyReports(
      user.sub,
    );
  }

  @Get('me/:id')
  getMyReportById(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.reportsService.getMyReportById(
      user.sub,
      id,
    );
  }
}