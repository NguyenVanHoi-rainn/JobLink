import {
  Body,
  Controller,
  Get,
  Patch,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { UpdateAdminJobStatusDto } from './dto/admin-job.dto.js';

@Controller('admin/jobs')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AdminJobsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  getJobs() {
    return this.prisma.job.findMany({
      select: {
        id: true,
        title: true,
        salary: true,
        salaryType: true,
        location: true,
        status: true,
        createdAt: true,
        employer: {
          select: {
            companyName: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  @Patch(':id/status')
  updateJobStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAdminJobStatusDto,
  ) {
    return this.prisma.job.update({
      where: { id },
      data: { status: dto.status },
      select: {
        id: true,
        status: true,
      },
    });
  }
}
