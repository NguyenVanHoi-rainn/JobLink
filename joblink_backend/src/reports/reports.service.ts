import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreateReportDto } from './dto/create-report.dto.js';

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async createReport(
    reporterId: string,
    dto: CreateReportDto,
  ) {
    const targetType =
      dto.targetType
        .trim()
        .toUpperCase();

    // Không cho tự report chính mình
    // nếu targetType là USER.
    if (
      targetType === 'USER' &&
      dto.targetId === reporterId
    ) {
      throw new BadRequestException(
        'Bạn không thể báo cáo chính mình',
      );
    }

    // Kiểm tra target tồn tại đối với
    // các loại hiện JobLink đang sử dụng.
    if (targetType === 'USER') {
      const user =
        await this.prisma.user.findUnique({
          where: {
            id: dto.targetId,
          },

          select: {
            id: true,
          },
        });

      if (!user) {
        throw new NotFoundException(
          'Không tìm thấy người dùng cần báo cáo',
        );
      }
    }

    if (targetType === 'JOB') {
      const job =
        await this.prisma.job.findUnique({
          where: {
            id: dto.targetId,
          },

          select: {
            id: true,
          },
        });

      if (!job) {
        throw new NotFoundException(
          'Không tìm thấy việc làm cần báo cáo',
        );
      }
    }

    if (targetType === 'CONVERSATION') {
      const conversation =
        await this.prisma.conversation.findUnique({
          where: {
            id: dto.targetId,
          },

          select: {
            id: true,

            members: {
              where: {
                userId: reporterId,
              },

              select: {
                userId: true,
              },
            },
          },
        });

      if (!conversation) {
        throw new NotFoundException(
          'Không tìm thấy cuộc trò chuyện',
        );
      }

      if (
        conversation.members.length === 0
      ) {
        throw new ForbiddenException(
          'Bạn không thuộc cuộc trò chuyện này',
        );
      }
    }

    // Ngăn spam cùng một report đang OPEN/REVIEWING.
    const existing =
      await this.prisma.report.findFirst({
        where: {
          reporterId,

          targetType,

          targetId:
            dto.targetId,

          status: {
            in: [
              'OPEN',
              'REVIEWING',
            ],
          },
        },
      });

    if (existing) {
      throw new BadRequestException(
        'Bạn đã có báo cáo đang được xử lý cho đối tượng này',
      );
    }

    return this.prisma.report.create({
      data: {
        reporterId,

        targetType,

        targetId:
          dto.targetId,

        reason:
          dto.reason.trim(),

        description:
          dto.description?.trim() ||
          null,

        status:
          'OPEN',
      },
    });
  }

  async getMyReports(
    reporterId: string,
  ) {
    return this.prisma.report.findMany({
      where: {
        reporterId,
      },

      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async getMyReportById(
    reporterId: string,
    reportId: string,
  ) {
    const report =
      await this.prisma.report.findUnique({
        where: {
          id: reportId,
        },
      });

    if (!report) {
      throw new NotFoundException(
        'Không tìm thấy báo cáo',
      );
    }

    if (
      report.reporterId !==
      reporterId
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền xem báo cáo này',
      );
    }

    return report;
  }

  async getAdminReports(
    status?: string,
  ) {
    return this.prisma.report.findMany({
      where: {
        ...(status && {
          status:
            status as any,
        }),
      },

      include: {
        reporter: {
          select: {
            id: true,
            email: true,
            role: true,
            status: true,
          },
        },
      },

      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async getAdminReportById(
    reportId: string,
  ) {
    const report =
      await this.prisma.report.findUnique({
        where: {
          id: reportId,
        },

        include: {
          reporter: {
            select: {
              id: true,
              email: true,
              role: true,
              status: true,
            },
          },
        },
      });

    if (!report) {
      throw new NotFoundException(
        'Không tìm thấy báo cáo',
      );
    }

    return report;
  }

  async startReview(
    reportId: string,
  ) {
    const report =
      await this.prisma.report.findUnique({
        where: {
          id: reportId,
        },
      });

    if (!report) {
      throw new NotFoundException(
        'Không tìm thấy báo cáo',
      );
    }

    if (
      report.status !== 'OPEN'
    ) {
      throw new BadRequestException(
        'Chỉ báo cáo OPEN mới có thể chuyển sang REVIEWING',
      );
    }

    return this.prisma.report.update({
      where: {
        id: reportId,
      },

      data: {
        status:
          'REVIEWING',
      },
    });
  }

  async resolveReport(
    reportId: string,
  ) {
    const report =
      await this.prisma.report.findUnique({
        where: {
          id: reportId,
        },
      });

    if (!report) {
      throw new NotFoundException(
        'Không tìm thấy báo cáo',
      );
    }

    if (
      report.status !== 'REVIEWING'
    ) {
      throw new BadRequestException(
        'Chỉ báo cáo REVIEWING mới có thể RESOLVED',
      );
    }

    return this.prisma.report.update({
      where: {
        id: reportId,
      },

      data: {
        status:
          'RESOLVED',

        resolvedAt:
          new Date(),
      },
    });
  }

  async rejectReport(
    reportId: string,
  ) {
    const report =
      await this.prisma.report.findUnique({
        where: {
          id: reportId,
        },
      });

    if (!report) {
      throw new NotFoundException(
        'Không tìm thấy báo cáo',
      );
    }

    if (
      report.status !== 'REVIEWING'
    ) {
      throw new BadRequestException(
        'Chỉ báo cáo REVIEWING mới có thể REJECTED',
      );
    }

    return this.prisma.report.update({
      where: {
        id: reportId,
      },

      data: {
        status:
          'REJECTED',

        resolvedAt:
          new Date(),
      },
    });
  }
}