import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';

import { JobRecommendationsService } from './job-recommendations.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller(
  'workers/me/recommendations',
)
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('WORKER')
export class JobRecommendationsController {
  constructor(
    private readonly jobRecommendationsService:
      JobRecommendationsService,
  ) {}

  @Get('jobs')
  getRecommendedJobs(
    @CurrentUser()
    user: any,
  ) {
    return this.jobRecommendationsService.getRecommendations(
      user.sub,
    );
  }
}