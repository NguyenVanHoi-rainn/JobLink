import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class SavedJobsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  private async getWorker(
    userId: string,
  ) {
    const worker =
      await this.prisma.workerProfile.findUnique({
        where: {
          userId,
        },
      });

    if (!worker) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    return worker;
  }

  async saveJob(
    userId: string,
    jobId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    const job =
      await this.prisma.job.findUnique({
        where: {
          id: jobId,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy việc làm',
      );
    }

    if (job.status !== 'PUBLISHED') {
      throw new BadRequestException(
        'Chỉ có thể lưu việc làm đang PUBLISHED',
      );
    }

    const existing =
      await this.prisma.savedJob.findFirst({
        where: {
          workerId:
            worker.id,

          jobId,
        },
      });

    if (existing) {
      return existing;
    }

    return this.prisma.savedJob.create({
      data: {
        workerId:
          worker.id,

        jobId,
      },
    });
  }

  async getMySavedJobs(
    userId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    return this.prisma.savedJob.findMany({
      where: {
        workerId:
          worker.id,
      },

      include: {
        job: {
          include: {
            category: true,

            employer: {
              include: {
                user: true,
              },
            },

            jobSkills: {
              include: {
                skill: true,
              },
            },
          },
        },
      },

      orderBy: {
        savedAt: 'desc',
      },
    });
  }

  async isSaved(
    userId: string,
    jobId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    const saved =
      await this.prisma.savedJob.findFirst({
        where: {
          workerId:
            worker.id,

          jobId,
        },
      });

    return {
      isSaved:
        !!saved,
    };
  }

    async removeSavedJob(
    userId: string,
    jobId: string,
    ) {
    const worker =
        await this.getWorker(userId);

    const saved =
        await this.prisma.savedJob.findFirst({
        where: {
            workerId:
            worker.id,

            jobId,
        },
        });

    if (!saved) {
        throw new NotFoundException(
        'Việc làm này chưa được lưu',
        );
    }

    await this.prisma.savedJob.deleteMany({
        where: {
        workerId:
            worker.id,

        jobId,
        },
    });

    return {
        message:
        'Đã bỏ lưu việc làm',
    };
    }
}