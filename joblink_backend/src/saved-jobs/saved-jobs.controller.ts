import {
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { SavedJobsService } from './saved-jobs.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('saved-jobs')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('WORKER')
export class SavedJobsController {
  constructor(
    private readonly savedJobsService:
      SavedJobsService,
  ) {}

  @Post(':jobId')
  saveJob(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.savedJobsService.saveJob(
      user.sub,
      jobId,
    );
  }

  @Get()
  getMySavedJobs(
    @CurrentUser()
    user: any,
  ) {
    return this.savedJobsService.getMySavedJobs(
      user.sub,
    );
  }

  @Get(':jobId/check')
  isSaved(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.savedJobsService.isSaved(
      user.sub,
      jobId,
    );
  }

  @Delete(':jobId')
  removeSavedJob(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.savedJobsService.removeSavedJob(
      user.sub,
      jobId,
    );
  }
}