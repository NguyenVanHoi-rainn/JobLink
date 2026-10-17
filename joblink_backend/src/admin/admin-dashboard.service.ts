import { Injectable } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminDashboardService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async getOverview() {
    const [
      totalUsers,
      activeUsers,
      lockedUsers,

      totalWorkers,
      totalEmployers,

      totalJobs,
      publishedJobs,
      draftJobs,
      closedJobs,
      hiddenJobs,

      totalApplications,

      totalReports,
      openReports,
      reviewingReports,

      totalAppointments,
    ] = await Promise.all([
      this.prisma.user.count(),

      this.prisma.user.count({
        where: {
          status: 'ACTIVE',
        },
      }),

      this.prisma.user.count({
        where: {
          status: 'LOCKED',
        },
      }),

      this.prisma.user.count({
        where: {
          role: 'WORKER',
        },
      }),

      this.prisma.user.count({
        where: {
          role: 'EMPLOYER',
        },
      }),

      this.prisma.job.count(),

      this.prisma.job.count({
        where: {
          status: 'PUBLISHED',
        },
      }),

      this.prisma.job.count({
        where: {
          status: 'DRAFT',
        },
      }),

      this.prisma.job.count({
        where: {
          status: 'CLOSED',
        },
      }),

      this.prisma.job.count({
        where: {
          status: 'HIDDEN',
        },
      }),

      this.prisma.application.count(),

      this.prisma.report.count(),

      this.prisma.report.count({
        where: {
          status: 'OPEN',
        },
      }),

      this.prisma.report.count({
        where: {
          status: 'REVIEWING',
        },
      }),

      this.prisma.workAppointment.count(),
    ]);

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
        locked: lockedUsers,

        workers: totalWorkers,
        employers: totalEmployers,
      },

      jobs: {
        total: totalJobs,
        published: publishedJobs,
        draft: draftJobs,
        closed: closedJobs,
        hidden: hiddenJobs,
      },

      applications: {
        total: totalApplications,
      },

      reports: {
        total: totalReports,
        open: openReports,
        reviewing: reviewingReports,
      },

      appointments: {
        total: totalAppointments,
      },
    };
  }

  async getUsersByRole() {
    const result =
      await this.prisma.user.groupBy({
        by: [
          'role',
        ],

        _count: {
          _all: true,
        },
      });

    return result.map(
      (item) => ({
        role:
          item.role,

        count:
          item._count._all,
      }),
    );
  }

  async getJobsByStatus() {
    const result =
      await this.prisma.job.groupBy({
        by: [
          'status',
        ],

        _count: {
          _all: true,
        },
      });

    return result.map(
      (item) => ({
        status:
          item.status,

        count:
          item._count._all,
      }),
    );
  }

  async getApplicationsByStatus() {
    const result =
      await this.prisma.application.groupBy({
        by: [
          'status',
        ],

        _count: {
          _all: true,
        },
      });

    return result.map(
      (item) => ({
        status:
          item.status,

        count:
          item._count._all,
      }),
    );
  }

  async getReportsByStatus() {
    const result =
      await this.prisma.report.groupBy({
        by: [
          'status',
        ],

        _count: {
          _all: true,
        },
      });

    return result.map(
      (item) => ({
        status:
          item.status,

        count:
          item._count._all,
      }),
    );
  }

  async getAppointmentsByStatus() {
    const result =
      await this.prisma.workAppointment.groupBy({
        by: [
          'status',
        ],

        _count: {
          _all: true,
        },
      });

    return result.map(
      (item) => ({
        status:
          item.status,

        count:
          item._count._all,
      }),
    );
  }
}