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

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('employers/me/jobs')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('EMPLOYER')
export class JobsController {
  constructor(
    private readonly jobsService: JobsService,
  ) {}

  @Get()
  getMyJobs(
    @CurrentUser()
    user: any,
  ) {
    return this.jobsService.getMyJobs(
      user.sub,
    );
  }

  @Get(':id')
  getMyJobById(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.jobsService.getMyJobById(
      user.sub,
      id,
    );
  }

  @Post()
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

  @Patch(':id')
  updateJob(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
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

  @Patch(':id/publish')
  publishJob(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.jobsService.publishJob(
      user.sub,
      id,
    );
  }

  @Patch(':id/close')
  closeJob(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.jobsService.closeJob(
      user.sub,
      id,
    );
  }

  @Patch(':id/republish')
  republishJob(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.jobsService.republishJob(
      user.sub,
      id,
    );
  }
}