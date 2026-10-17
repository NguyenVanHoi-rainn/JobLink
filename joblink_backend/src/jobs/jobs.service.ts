import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreateJobDto } from './dto/create-job.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';

import {
  JobSortDto,
  SearchJobsDto,
} from './dto/search-jobs.dto.js';

@Injectable()
export class JobsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  private async getEmployer(userId: string) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          userId,
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
      );
    }

    return employer;
  }

  private async validateCategory(
    categoryId: string,
  ) {
    const category =
      await this.prisma.category.findFirst({
        where: {
          id: categoryId,
          status: true,
        },
      });

    if (!category) {
      throw new NotFoundException(
        'Ngành nghề không tồn tại hoặc đã bị vô hiệu hóa',
      );
    }
  }

  private calculateDistanceKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
    ) {
    const earthRadius = 6371;

    const toRad = (value: number) =>
        (value * Math.PI) / 180;

    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) *
        Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c =
        2 *
        Math.atan2(
        Math.sqrt(a),
        Math.sqrt(1 - a),
        );

    return earthRadius * c;
    }

  private async validateSkills(
    skillIds: string[],
  ) {
    if (skillIds.length === 0) {
      return;
    }

    const skills =
      await this.prisma.skill.findMany({
        where: {
          id: {
            in: skillIds,
          },

          status: true,
        },
      });

    if (skills.length !== skillIds.length) {
      throw new NotFoundException(
        'Có kỹ năng không tồn tại hoặc đã bị vô hiệu hóa',
      );
    }
  }

  async createJob(
    userId: string,
    dto: CreateJobDto,
  ) {
    const employer =
      await this.getEmployer(userId);

    await this.validateCategory(
      dto.categoryId,
    );

    const skillIds =
      dto.skillIds ?? [];

    await this.validateSkills(skillIds);

    if (
      dto.deadline &&
      new Date(dto.deadline) <= new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển phải lớn hơn thời điểm hiện tại',
      );
    }

    return this.prisma.$transaction(
      async (tx) => {
        const job = await tx.job.create({
          data: {
            employerId: employer.id,
            categoryId: dto.categoryId,

            title: dto.title,
            description: dto.description,
            salary: dto.salary,

            location: dto.location,

            latitude:
              dto.latitude ?? null,

            longitude:
              dto.longitude ?? null,

            cvRequired:
              dto.cvRequired ?? false,

            deadline: dto.deadline
              ? new Date(dto.deadline)
              : null,

            status: 'DRAFT',
          },
        });

        if (skillIds.length > 0) {
          await tx.jobSkill.createMany({
            data: skillIds.map(
              (skillId) => ({
                jobId: job.id,
                skillId,
              }),
            ),
          });
        }

        return tx.job.findUnique({
          where: {
            id: job.id,
          },

          include: {
            category: true,

            jobSkills: {
              include: {
                skill: true,
              },
            },
          },
        });
      },
    );
  }

  async getMyJobs(
    userId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    return this.prisma.job.findMany({
      where: {
        employerId: employer.id,
      },

      include: {
        category: true,

        jobSkills: {
          include: {
            skill: true,
          },
        },

        _count: {
          select: {
            applications: true,
          },
        },
      },

      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async getMyJobById(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId: employer.id,
        },

        include: {
          category: true,

          jobSkills: {
            include: {
              skill: true,
            },
          },

          _count: {
            select: {
              applications: true,
            },
          },
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    return job;
  }

  async updateJob(
    userId: string,
    jobId: string,
    dto: UpdateJobDto,
  ) {
    const employer =
      await this.getEmployer(userId);

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId: employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (job.status === 'HIDDEN') {
      throw new BadRequestException(
        'Tin tuyển dụng đang bị Admin ẩn',
      );
    }

    if (
      dto.categoryId !== undefined
    ) {
      await this.validateCategory(
        dto.categoryId,
      );
    }

    if (
      dto.skillIds !== undefined
    ) {
      await this.validateSkills(
        dto.skillIds,
      );
    }

    if (
      dto.deadline &&
      new Date(dto.deadline) <= new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển phải lớn hơn thời điểm hiện tại',
      );
    }

    return this.prisma.$transaction(
      async (tx) => {
        await tx.job.update({
          where: {
            id: jobId,
          },

          data: {
            ...(dto.title !== undefined && {
              title: dto.title,
            }),

            ...(dto.description !== undefined && {
              description:
                dto.description,
            }),

            ...(dto.categoryId !== undefined && {
              categoryId:
                dto.categoryId,
            }),

            ...(dto.salary !== undefined && {
              salary: dto.salary,
            }),

            ...(dto.location !== undefined && {
              location:
                dto.location,
            }),

            ...(dto.latitude !== undefined && {
              latitude:
                dto.latitude,
            }),

            ...(dto.longitude !== undefined && {
              longitude:
                dto.longitude,
            }),

            ...(dto.cvRequired !== undefined && {
              cvRequired:
                dto.cvRequired,
            }),

            ...(dto.deadline !== undefined && {
              deadline:
                new Date(dto.deadline),
            }),
          },
        });

        if (
          dto.skillIds !== undefined
        ) {
          await tx.jobSkill.deleteMany({
            where: {
              jobId,
            },
          });

          if (
            dto.skillIds.length > 0
          ) {
            await tx.jobSkill.createMany({
              data: dto.skillIds.map(
                (skillId) => ({
                  jobId,
                  skillId,
                }),
              ),
            });
          }
        }

        return tx.job.findUnique({
          where: {
            id: jobId,
          },

          include: {
            category: true,

            jobSkills: {
              include: {
                skill: true,
              },
            },
          },
        });
      },
    );
  }

  async publishJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    if (
      employer.verificationStatus !==
      'VERIFIED'
    ) {
      throw new BadRequestException(
        'Employer phải được xác minh trước khi đăng tin',
      );
    }

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId: employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (job.status !== 'DRAFT') {
      throw new BadRequestException(
        'Chỉ tin DRAFT mới có thể được đăng',
      );
    }

    if (
      job.deadline &&
      job.deadline <= new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển đã hết',
      );
    }

    return this.prisma.job.update({
      where: {
        id: jobId,
      },

      data: {
        status: 'PUBLISHED',
      },
    });
  }

  async closeJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId: employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (job.status !== 'PUBLISHED') {
      throw new BadRequestException(
        'Chỉ tin đang PUBLISHED mới có thể đóng',
      );
    }

    return this.prisma.job.update({
      where: {
        id: jobId,
      },

      data: {
        status: 'CLOSED',
      },
    });
  }

  async republishJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    if (
      employer.verificationStatus !==
      'VERIFIED'
    ) {
      throw new BadRequestException(
        'Employer phải được xác minh trước khi đăng lại tin',
      );
    }

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId: employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (job.status !== 'CLOSED') {
      throw new BadRequestException(
        'Chỉ tin CLOSED mới có thể đăng lại',
      );
    }

    if (
      job.deadline &&
      job.deadline <= new Date()
    ) {
      throw new BadRequestException(
        'Hãy cập nhật hạn ứng tuyển mới trước khi đăng lại',
      );
    }

    return this.prisma.job.update({
      where: {
        id: jobId,
      },

      data: {
        status: 'PUBLISHED',
      },
    });
  }

    async getActiveCategories() {
    return this.prisma.category.findMany({
        where: {
        status: true,
        },

        orderBy: {
        name: 'asc',
        },
    });
    }

    async getActiveSkills() {
    return this.prisma.skill.findMany({
        where: {
        status: true,
        },

        orderBy: {
        name: 'asc',
        },
    });
    }

    async searchJobs(
    userId: string,
    dto: SearchJobsDto,
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

    if (
        dto.minSalary !== undefined &&
        dto.maxSalary !== undefined &&
        dto.minSalary > dto.maxSalary
    ) {
        throw new BadRequestException(
        'Mức lương tối thiểu không được lớn hơn mức lương tối đa',
        );
    }

    if (
        (dto.latitude === undefined) !==
        (dto.longitude === undefined)
    ) {
        throw new BadRequestException(
        'Phải cung cấp đầy đủ latitude và longitude',
        );
    }


    const latitude =
        dto.latitude ??
        (worker.latitude !== null
        ? Number(worker.latitude)
        : undefined);

    const longitude =
        dto.longitude ??
        (worker.longitude !== null
        ? Number(worker.longitude)
        : undefined);

    if (
        dto.maxDistanceKm !== undefined &&
        (
        latitude === undefined ||
        longitude === undefined
        )
    ) {
        throw new BadRequestException(
        'Cần có vị trí để lọc theo khoảng cách',
        );
    }

    const andConditions: any[] = [
        {
        OR: [
            {
            deadline: null,
            },
            {
            deadline: {
                gt: new Date(),
            },
            },
        ],
        },
    ];

    if (dto.keyword?.trim()) {
        const keyword = dto.keyword.trim();

        andConditions.push({
        OR: [
            {
            title: {
                contains: keyword,
                mode: 'insensitive',
            },
            },

            {
            description: {
                contains: keyword,
                mode: 'insensitive',
            },
            },

            {
            location: {
                contains: keyword,
                mode: 'insensitive',
            },
            },
        ],
        });
    }

    if (dto.location?.trim()) {
        andConditions.push({
        location: {
            contains: dto.location.trim(),
            mode: 'insensitive',
        },
        });
    }

    const jobs =
        await this.prisma.job.findMany({
        where: {
            status: 'PUBLISHED',

            ...(dto.categoryId && {
            categoryId: dto.categoryId,
            }),

            ...(dto.cvRequired !== undefined && {
            cvRequired: dto.cvRequired,
            }),

            ...(dto.minSalary !== undefined ||
            dto.maxSalary !== undefined
            ? {
                salary: {
                    ...(dto.minSalary !== undefined && {
                    gte: dto.minSalary,
                    }),

                    ...(dto.maxSalary !== undefined && {
                    lte: dto.maxSalary,
                    }),
                },
                }
            : {}),

            AND: andConditions,
        },

        include: {
            category: true,

            employer: {
            select: {
                id: true,
                companyName: true,
                logoUrl: true,
                address: true,
                verificationStatus: true,
            },
            },

            jobSkills: {
            include: {
                skill: true,
            },
            },
        },

        orderBy: {
            createdAt: 'desc',
        },
        });

    let result = jobs.map((job) => {
        let distanceKm: number | null = null;

        if (
        latitude !== undefined &&
        longitude !== undefined &&
        job.latitude !== null &&
        job.longitude !== null
        ) {
        distanceKm =
            this.calculateDistanceKm(
            latitude,
            longitude,
            Number(job.latitude),
            Number(job.longitude),
            );

        distanceKm =
            Math.round(
            distanceKm * 10,
            ) / 10;
        }

        return {
        ...job,
        distanceKm,
        };
    });

    if (
        dto.maxDistanceKm !== undefined
    ) {
        result = result.filter(
        (job) =>
            job.distanceKm !== null &&
            job.distanceKm <=
            dto.maxDistanceKm!,
        );
    }

    switch (dto.sort) {
        case JobSortDto.SALARY_ASC:
        result.sort(
            (a, b) =>
            Number(a.salary) -
            Number(b.salary),
        );
        break;

        case JobSortDto.SALARY_DESC:
        result.sort(
            (a, b) =>
            Number(b.salary) -
            Number(a.salary),
        );
        break;

        case JobSortDto.DISTANCE:
        result.sort((a, b) => {
            if (a.distanceKm === null) {
            return 1;
            }

            if (b.distanceKm === null) {
            return -1;
            }

            return (
            a.distanceKm -
            b.distanceKm
            );
        });
        break;
    }

    const page = dto.page ?? 1;
    const limit = dto.limit ?? 10;

    const total = result.length;

    const start =
        (page - 1) * limit;

    const items = result.slice(
        start,
        start + limit,
    );

    return {
        page,
        limit,
        total,

        totalPages:
        Math.ceil(total / limit),

        items,
    };
    }

    async getPublishedJobById(
    jobId: string,
    ) {
    const job =
        await this.prisma.job.findFirst({
        where: {
            id: jobId,
            status: 'PUBLISHED',

            OR: [
            {
                deadline: null,
            },

            {
                deadline: {
                gt: new Date(),
                },
            },
            ],
        },

        include: {
            category: true,

            employer: {
            select: {
                id: true,
                companyName: true,
                description: true,
                logoUrl: true,
                address: true,
                verificationStatus: true,
            },
            },

            jobSkills: {
            include: {
                skill: true,
            },
            },
        },
        });

    if (!job) {
        throw new NotFoundException(
        'Không tìm thấy việc làm hoặc tin đã đóng',
        );
    }

    return job;
    }

}