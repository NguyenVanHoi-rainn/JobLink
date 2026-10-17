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

import { AdminService } from './admin.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';

import { RejectEmployerDto } from './dto/reject-employer.dto.js';

@Controller('admin')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('ADMIN')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
  ) {}

  @Get('employer-verifications')
  getPendingEmployerVerifications() {
    return this.adminService.getPendingEmployerVerifications();
  }

  @Get('employer-verifications/:id')
  getEmployerVerification(
    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.adminService.getEmployerVerification(
      id,
    );
  }

  @Get('employer-verifications/:id/file')
  async getEmployerVerificationFile(
    @Param('id', ParseUUIDPipe)
    id: string,

    @Res()
    res: Response,
  ) {
    const fileUrl =
      await this.adminService.getEmployerVerificationFile(
        id,
      );

    return res.sendFile(
      join(
        process.cwd(),
        fileUrl,
      ),
    );
  }

  @Patch('employer-verifications/:id/approve')
  approveEmployer(
    @Param('id', ParseUUIDPipe)
    id: string,
  ) {
    return this.adminService.approveEmployer(
      id,
    );
  }

  @Patch('employer-verifications/:id/reject')
  rejectEmployer(
    @Param('id', ParseUUIDPipe)
    id: string,

    @Body()
    dto: RejectEmployerDto,
  ) {
    return this.adminService.rejectEmployer(
      id,
      dto,
    );
  }
}