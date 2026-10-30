import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';

import {
  JobsService,
} from './jobs.service.js';

import {
  SearchJobsDto,
} from './dto/search-jobs.dto.js';

import {
  JwtAuthGuard,
} from '../auth/guards/jwt-auth.guard.js';

import {
  RolesGuard,
} from '../auth/guards/roles.guard.js';

import {
  Roles,
} from '../auth/decorators/roles.decorator.js';

import {
  CurrentUser,
} from '../auth/decorators/current-user.decorator.js';

@Controller('jobs')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('WORKER')
export class WorkerJobsController {
  constructor(
    private readonly jobsService:
      JobsService,
  ) {}

  // =====================================================
  // META
  // =====================================================

  @Get('meta/categories')
  getCategories() {
    return this.jobsService
      .getActiveCategories();
  }

  @Get('meta/skills')
  getSkills() {
    return this.jobsService
      .getActiveSkills();
  }

  // =====================================================
  // SEARCH / FILTER
  // GET /api/v1/jobs
  // =====================================================

  @Get()
  searchJobs(
    @CurrentUser()
    user: any,

    @Query()
    query: SearchJobsDto,
  ) {
    return this.jobsService.searchJobs(
      user.sub,
      query,
    );
  }

  // =====================================================
  // DETAIL
  // =====================================================

  @Get(':id')
  getJobDetail(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.jobsService
      .getPublishedJobById(
        id,
      );
  }
}