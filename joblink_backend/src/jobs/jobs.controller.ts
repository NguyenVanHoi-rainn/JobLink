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

import { JobsService } from './jobs.service.js';

import { CreateJobDto } from './dto/create-job.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto.js';

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
export class JobsController {
  constructor(
    private readonly jobsService: JobsService,
  ) {}

  // =====================================================
  // EMPLOYER PROFILE
  // =====================================================

  @Get('profile')
  getMyEmployerProfile(
    @CurrentUser()
    user: any,
  ) {
    return this.jobsService.getMyEmployerProfile(
      user.sub,
    );
  }

  @Patch('profile')
  updateMyEmployerProfile(
    @CurrentUser()
    user: any,

    @Body()
    dto: UpdateEmployerProfileDto,
  ) {
    return this.jobsService.updateMyEmployerProfile(
      user.sub,
      dto,
    );
  }

  @Patch('profile/submit-verification')
  submitEmployerVerification(
    @CurrentUser()
    user: any,
  ) {
    return this.jobsService.submitEmployerVerification(
      user.sub,
    );
  }

  // =====================================================
  // JOB META
  // =====================================================

  @Get('jobs/meta/categories')
  getActiveCategories() {
    return this.jobsService.getActiveCategories();
  }

  @Get('jobs/meta/skills')
  getActiveSkills() {
    return this.jobsService.getActiveSkills();
  }

  // =====================================================
  // JOB LIST
  // =====================================================

  @Get('jobs')
  getMyJobs(
    @CurrentUser()
    user: any,
  ) {
    return this.jobsService.getMyJobs(
      user.sub,
    );
  }

  // =====================================================
  // JOB DETAIL
  // =====================================================

  @Get('jobs/:id')
  getMyJobById(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.jobsService.getMyJobById(
      user.sub,
      id,
    );
  }

  // =====================================================
  // CREATE
  // =====================================================

  @Post('jobs')
  createJob(
    @CurrentUser()
    user: any,

    @Body()
    dto: CreateJobDto,
  ) {
    return this.jobsService.createJob(
      user.sub,
      dto,
    );
  }

  // =====================================================
  // UPDATE
  // =====================================================

  @Patch('jobs/:id')
  updateJob(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,

    @Body()
    dto: UpdateJobDto,
  ) {
    return this.jobsService.updateJob(
      user.sub,
      id,
      dto,
    );
  }

  // =====================================================
  // PUBLISH
  // =====================================================

  @Patch('jobs/:id/publish')
  publishJob(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.jobsService.publishJob(
      user.sub,
      id,
    );
  }

  // =====================================================
  // CLOSE
  // =====================================================

  @Patch('jobs/:id/close')
  closeJob(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.jobsService.closeJob(
      user.sub,
      id,
    );
  }

  // =====================================================
  // REPUBLISH
  // =====================================================

  @Patch('jobs/:id/republish')
  republishJob(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.jobsService.republishJob(
      user.sub,
      id,
    );
  }
}