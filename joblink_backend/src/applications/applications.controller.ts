import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { ApplicationsService } from './applications.service.js';
import { ApplyJobDto } from './dto/apply-job.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller()
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('WORKER')
export class ApplicationsController {
  constructor(
    private readonly applicationsService: ApplicationsService,
  ) {}

  @Post('jobs/:jobId/apply')
  applyJob(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,

    @Body()
    dto: ApplyJobDto,
  ) {
    return this.applicationsService.applyJob(
      user.sub,
      jobId,
      dto,
    );
  }

  @Get('applications/me')
  getMyApplications(
    @CurrentUser()
    user: any,
  ) {
    return this.applicationsService.getMyApplications(
      user.sub,
    );
  }

  @Get('applications/me/:id')
  getMyApplicationById(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.applicationsService.getMyApplicationById(
      user.sub,
      id,
    );
  }

  @Patch('applications/me/:id/withdraw')
  withdrawApplication(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.applicationsService.withdrawApplication(
      user.sub,
      id,
    );
  }
}