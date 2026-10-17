import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Res,
  UseGuards,
} from '@nestjs/common';

import type { Response } from 'express';
import { join } from 'path';

import { ApplicationsService } from './applications.service.js';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('employers/me')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('EMPLOYER')
export class EmployerApplicationsController {
  constructor(
    private readonly applicationsService: ApplicationsService,
  ) {}

  @Get('jobs/:jobId/applications')
  getJobApplications(
    @CurrentUser()
    user: any,

    @Param('jobId', ParseUUIDPipe)
    jobId: string,
  ) {
    return this.applicationsService.getJobApplications(
      user.sub,
      jobId,
    );
  }

  @Get('applications/:id')
  getApplication(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.applicationsService.getApplicationForEmployer(
      user.sub,
      id,
    );
  }

  @Get('applications/:id/cv')
  async getApplicationCv(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,

    @Res()
    res: Response,
  ) {
    const cv =
      await this.applicationsService.getApplicationCv(
        user.sub,
        id,
      );

    return res.sendFile(
      join(
        process.cwd(),
        cv.fileUrl,
      ),
    );
  }

  @Patch('applications/:id/status')
  updateStatus(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
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

  @Get('applications/:id/match')
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