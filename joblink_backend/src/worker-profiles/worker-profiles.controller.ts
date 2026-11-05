import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';

import {
  WorkerProfilesService,
} from './worker-profiles.service.js';

import {
  UpdateWorkerProfileDto,
} from './dto/update-worker-profile.dto.js';

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

@Controller(
  'workers/me/profile',
)
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('WORKER')
export class WorkerProfilesController {
  constructor(
    private readonly workerProfilesService:
      WorkerProfilesService,
  ) {}

  @Get()
  getMyProfile(
    @CurrentUser()
    user: any,
  ) {
    return this.workerProfilesService
      .getMyProfile(
        user.sub,
      );
  }

  @Patch()
  updateMyProfile(
    @CurrentUser()
    user: any,

    @Body()
    dto: UpdateWorkerProfileDto,
  ) {
    return this.workerProfilesService
      .updateMyProfile(
        user.sub,
        dto,
      );
  }
}