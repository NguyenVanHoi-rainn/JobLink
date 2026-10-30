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
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller()
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
export class ApplicationsController {
  constructor(
    private readonly applicationsService:
      ApplicationsService,
  ) {}

  // =====================================================
  // WORKER
  // =====================================================

  @Post('jobs/:jobId/apply')
  @Roles('WORKER')
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
  @Roles('WORKER')
  getMyApplications(
    @CurrentUser()
    user: any,
  ) {
    return this.applicationsService.getMyApplications(
      user.sub,
    );
  }

  @Get('applications/me/:id')
  @Roles('WORKER')
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
  @Roles('WORKER')
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

  // =====================================================
  // EMPLOYER
  // =====================================================

  @Get('employer/jobs')
  @Roles('EMPLOYER')
  getEmployerJobs(
    @CurrentUser()
    user: any,
  ) {
    return this.applicationsService.getEmployerJobs(
      user.sub,
    );
  }

  @Get('employer/jobs/:jobId/applications')
  @Roles('EMPLOYER')
  getJobApplications(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.applicationsService.getJobApplications(
      user.sub,
      jobId,
    );
  }

  @Get('employer/applications/:id')
  @Roles('EMPLOYER')
  getApplicationForEmployer(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.applicationsService.getApplicationForEmployer(
      user.sub,
      id,
    );
  }

  @Get('employer/applications/:id/cv')
  @Roles('EMPLOYER')
  getApplicationCv(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.applicationsService.getApplicationCv(
      user.sub,
      id,
    );
  }

  @Patch('employer/applications/:id/status')
  @Roles('EMPLOYER')
  updateApplicationStatus(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,

    @Body()
    dto: UpdateApplicationStatusDto,
  ) {
    return this.applicationsService.updateApplicationStatus(
      user.sub,
      id,
      dto,
    );
  }

  @Get('employer/applications/:id/match')
  @Roles('EMPLOYER')
  getCandidateMatch(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.applicationsService.getCandidateMatch(
      user.sub,
      id,
    );
  }
}
