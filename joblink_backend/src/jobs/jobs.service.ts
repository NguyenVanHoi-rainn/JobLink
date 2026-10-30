import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreateJobDto } from './dto/create-job.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto.js';

import {
  JobSortDto,
  SearchJobsDto,
} from './dto/search-jobs.dto.js';

@Injectable()
export class JobsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  // =====================================================
  // EMPLOYER HELPER
  // =====================================================

  private async getEmployer(
    userId: string,
  ) {
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

  private normalizeNullableText(
    value: string,
  ) {
    const trimmed = value.trim();

    return trimmed.length > 0
      ? trimmed
      : null;
  }

  // =====================================================
  // EMPLOYER PROFILE
  // =====================================================

  async getMyEmployerProfile(
    userId: string,
  ) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          userId,
        },

        include: {
          user: {
            select: {
              email: true,
              status: true,
            },
          },
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
      );
    }

    return employer;
  }

  async updateMyEmployerProfile(
    userId: string,
    dto: UpdateEmployerProfileDto,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    if (
      employer.verificationStatus ===
      'PENDING'
    ) {
      throw new BadRequestException(
        'Hồ sơ đang chờ Admin xác minh. Không thể chỉnh sửa lúc này.',
      );
    }

    const newCompanyName =
      dto.companyName !== undefined
        ? dto.companyName.trim()
        : employer.companyName;

    const newTaxCode =
      dto.taxCode !== undefined
        ? this.normalizeNullableText(
            dto.taxCode,
          )
        : employer.taxCode;

    const newBusinessLicense =
      dto.businessLicense !== undefined
        ? this.normalizeNullableText(
            dto.businessLicense,
          )
        : employer.businessLicense;

    const identityChanged =
      newCompanyName !==
        employer.companyName ||
      newTaxCode !==
        employer.taxCode ||
      newBusinessLicense !==
        employer.businessLicense;

    await this.prisma.employerProfile.update({
      where: {
        id: employer.id,
      },

      data: {
        ...(dto.companyName !== undefined && {
          companyName:
            dto.companyName.trim(),
        }),

        ...(dto.contactName !== undefined && {
          contactName:
            this.normalizeNullableText(
              dto.contactName,
            ),
        }),

        ...(dto.phone !== undefined && {
          phone:
            this.normalizeNullableText(
              dto.phone,
            ),
        }),

        ...(dto.description !== undefined && {
          description:
            this.normalizeNullableText(
              dto.description,
            ),
        }),

        ...(dto.address !== undefined && {
          address:
            this.normalizeNullableText(
              dto.address,
            ),
        }),

        ...(dto.logoUrl !== undefined && {
          logoUrl:
            this.normalizeNullableText(
              dto.logoUrl,
            ),
        }),

        ...(dto.businessLicense !== undefined && {
          businessLicense:
            this.normalizeNullableText(
              dto.businessLicense,
            ),
        }),

        ...(dto.taxCode !== undefined && {
          taxCode:
            this.normalizeNullableText(
              dto.taxCode,
            ),
        }),

        // Nếu Employer đã VERIFIED nhưng thay đổi
        // thông tin pháp lý thì yêu cầu xác minh lại.
        ...(employer.verificationStatus ===
            'VERIFIED' &&
          identityChanged && {
          verificationStatus:
            'UNVERIFIED',
          rejectionReason:
            null,
        }),
      },
    });

    return this.getMyEmployerProfile(
      userId,
    );
  }

  async submitEmployerVerification(
    userId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    if (
      employer.verificationStatus ===
      'VERIFIED'
    ) {
      throw new BadRequestException(
        'Employer đã được xác minh',
      );
    }

    if (
      employer.verificationStatus ===
      'PENDING'
    ) {
      throw new BadRequestException(
        'Yêu cầu xác minh đang chờ Admin xử lý',
      );
    }

    if (
      !employer.companyName?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật tên doanh nghiệp',
      );
    }

    if (
      !employer.contactName?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật người liên hệ',
      );
    }

    if (
      !employer.phone?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật số điện thoại',
      );
    }

    if (
      !employer.address?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật địa chỉ doanh nghiệp',
      );
    }

    if (
      !employer.taxCode?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật mã số thuế',
      );
    }

    if (
      !employer.businessLicense?.trim()
    ) {
      throw new BadRequestException(
        'Vui lòng cập nhật thông tin giấy phép kinh doanh',
      );
    }

    await this.prisma.employerProfile.update({
      where: {
        id: employer.id,
      },

      data: {
        verificationStatus:
          'PENDING',

        rejectionReason:
          null,
      },
    });

    return this.getMyEmployerProfile(
      userId,
    );
  }

  // =====================================================
  // CATEGORY
  // =====================================================

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

  // =====================================================
  // SKILL
  // =====================================================

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

    if (
      skills.length !==
      skillIds.length
    ) {
      throw new NotFoundException(
        'Có kỹ năng không tồn tại hoặc đã bị vô hiệu hóa',
      );
    }
  }

  // =====================================================
  // DISTANCE
  // =====================================================

  private calculateDistanceKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) {
    const earthRadius = 6371;

    const toRad = (
      value: number,
    ) =>
      (value * Math.PI) / 180;

    const dLat =
      toRad(
        lat2 - lat1,
      );

    const dLon =
      toRad(
        lon2 - lon1,
      );

    const a =
      Math.sin(dLat / 2) *
        Math.sin(dLat / 2) +
      Math.cos(
        toRad(lat1),
      ) *
        Math.cos(
          toRad(lat2),
        ) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c =
      2 *
      Math.atan2(
        Math.sqrt(a),
        Math.sqrt(
          1 - a,
        ),
      );

    return earthRadius * c;
  }

  private timeStringToDate(
    value: string,
  ) {
    return new Date(
      `1970-01-01T${value}:00.000Z`,
    );
  }

  private validateJobSchedule(
    startTime: string,
    endTime: string,
    workDays: string[],
  ) {
    if (
      startTime ===
      endTime
    ) {
      throw new BadRequestException(
        'Giờ bắt đầu và giờ kết thúc không được giống nhau',
      );
    }

    if (
      workDays.length ===
      0
    ) {
      throw new BadRequestException(
        'Phải chọn ít nhất một ngày làm việc',
      );
    }
  }

  private formatTimeValue(
    value: Date,
  ) {
    const hours =
      value
        .getUTCHours()
        .toString()
        .padStart(
          2,
          '0',
        );

    const minutes =
      value
        .getUTCMinutes()
        .toString()
        .padStart(
          2,
          '0',
        );

    return `${hours}:${minutes}`;
  }

  // =====================================================
  // CREATE JOB
  // =====================================================

  async createJob(
    userId: string,
    dto: CreateJobDto,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    // =====================================================
    // CATEGORY
    // =====================================================

    await this.validateCategory(
      dto.categoryId,
    );

    // =====================================================
    // SKILLS
    // =====================================================

    const skillIds =
      dto.skillIds ?? [];

    await this.validateSkills(
      skillIds,
    );

    // =====================================================
    // LOCATION
    // =====================================================

    if (
      (dto.latitude === undefined) !==
      (dto.longitude === undefined)
    ) {
      throw new BadRequestException(
        'Phải cung cấp đầy đủ latitude và longitude',
      );
    }

    // =====================================================
    // SCHEDULE
    // =====================================================

    this.validateJobSchedule(
      dto.startTime,
      dto.endTime,
      dto.workDays,
    );

    // =====================================================
    // DEADLINE
    // =====================================================

    if (
      dto.deadline &&
      new Date(dto.deadline) <=
        new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển phải lớn hơn thời điểm hiện tại',
      );
    }

    // =====================================================
    // URGENT
    // =====================================================

    const urgent =
      dto.urgent ?? false;

    if (
      urgent &&
      !dto.urgentUntil
    ) {
      throw new BadRequestException(
        'Tin tuyển gấp phải có thời gian kết thúc tuyển gấp',
      );
    }

    if (
      dto.urgentUntil &&
      new Date(dto.urgentUntil) <=
        new Date()
    ) {
      throw new BadRequestException(
        'Thời gian tuyển gấp phải lớn hơn thời điểm hiện tại',
      );
    }

    // =====================================================
    // CREATE
    // =====================================================

    return this.prisma.$transaction(
      async (tx) => {
        const job =
          await tx.job.create({
            data: {
              employerId:
                employer.id,

              categoryId:
                dto.categoryId,

              title:
                dto.title.trim(),

              description:
                dto.description.trim(),

              // ===========================================
              // SALARY
              // ===========================================

              salary:
                dto.salary,

              salaryType:
                dto.salaryType,

              // ===========================================
              // LOCATION
              // ===========================================

              location:
                dto.location.trim(),

              latitude:
                dto.latitude ??
                null,

              longitude:
                dto.longitude ??
                null,

              // ===========================================
              // SCHEDULE
              // ===========================================

              shiftType:
                dto.shiftType,

              startTime:
                this.timeStringToDate(
                  dto.startTime,
                ),

              endTime:
                this.timeStringToDate(
                  dto.endTime,
                ),

              workDays:
                dto.workDays,

              // ===========================================
              // URGENT
              // ===========================================

              urgent,

              urgentUntil:
                urgent &&
                dto.urgentUntil
                  ? new Date(
                      dto.urgentUntil,
                    )
                  : null,

              // ===========================================
              // CV
              // ===========================================

              cvRequired:
                dto.cvRequired ??
                false,

              // ===========================================
              // DEADLINE
              // ===========================================

              deadline:
                dto.deadline
                  ? new Date(
                      dto.deadline,
                    )
                  : null,

              status:
                'DRAFT',
            },
          });

        // =================================================
        // SKILLS
        // =================================================

        if (
          skillIds.length >
          0
        ) {
          await tx.jobSkill.createMany({
            data:
              skillIds.map(
                (skillId) => ({
                  jobId:
                    job.id,

                  skillId,
                }),
              ),
          });
        }

        return tx.job.findUnique({
          where: {
            id:
              job.id,
          },

          include: {
            category:
              true,

            jobSkills: {
              include: {
                skill:
                  true,
              },
            },
          },
        });
      },
    );
  }
  // =====================================================
  // EMPLOYER JOB LIST
  // =====================================================

  async getMyJobs(
    userId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    return this.prisma.job.findMany({
      where: {
        employerId:
          employer.id,
      },

      include: {
        category:
          true,

        jobSkills: {
          include: {
            skill:
              true,
          },
        },

        _count: {
          select: {
            applications:
              true,
          },
        },
      },

      orderBy: {
        createdAt:
          'desc',
      },
    });
  }

  // =====================================================
  // EMPLOYER JOB DETAIL
  // =====================================================

  async getMyJobById(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    const job =
      await this.prisma.job.findFirst({
        where: {
          id:
            jobId,

          employerId:
            employer.id,
        },

        include: {
          category:
            true,

          jobSkills: {
            include: {
              skill:
                true,
            },
          },

          _count: {
            select: {
              applications:
                true,
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

  // =====================================================
  // UPDATE JOB
  // =====================================================

  async updateJob(
    userId: string,
    jobId: string,
    dto: UpdateJobDto,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          employerId:
            employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (
      job.status ===
      'HIDDEN'
    ) {
      throw new BadRequestException(
        'Tin tuyển dụng đang bị Admin ẩn',
      );
    }

    // =====================================================
    // CATEGORY
    // =====================================================

    if (
      dto.categoryId !==
      undefined
    ) {
      await this.validateCategory(
        dto.categoryId,
      );
    }

    // =====================================================
    // SKILLS
    // =====================================================

    if (
      dto.skillIds !==
      undefined
    ) {
      await this.validateSkills(
        dto.skillIds,
      );
    }

    // =====================================================
    // LOCATION
    // =====================================================

    const nextLatitude =
      dto.latitude !== undefined
        ? dto.latitude
        : job.latitude === null
          ? null
          : Number(
              job.latitude,
            );

    const nextLongitude =
      dto.longitude !== undefined
        ? dto.longitude
        : job.longitude === null
          ? null
          : Number(
              job.longitude,
            );

    if (
      (nextLatitude === null) !==
      (nextLongitude === null)
    ) {
      throw new BadRequestException(
        'Latitude và longitude phải được cập nhật cùng nhau',
      );
    }

    // =====================================================
    // SCHEDULE
    // Dùng dữ liệu mới nếu có,
    // nếu không thì lấy dữ liệu hiện tại.
    // =====================================================

    const nextStartTime =
      dto.startTime ??
      (
        job.startTime
          ? this.formatTimeValue(
              job.startTime,
            )
          : null
      );

    const nextEndTime =
      dto.endTime ??
      (
        job.endTime
          ? this.formatTimeValue(
              job.endTime,
            )
          : null
      );

    const nextWorkDays =
      dto.workDays ??
      job.workDays;

    if (
      dto.startTime !== undefined ||
      dto.endTime !== undefined ||
      dto.workDays !== undefined
    ) {
      if (
        !nextStartTime ||
        !nextEndTime
      ) {
        throw new BadRequestException(
          'Phải có đầy đủ giờ bắt đầu và giờ kết thúc',
        );
      }

      if (
        nextStartTime ===
        nextEndTime
      ) {
        throw new BadRequestException(
          'Giờ bắt đầu và giờ kết thúc không được giống nhau',
        );
      }

      if (
        nextWorkDays.length ===
        0
      ) {
        throw new BadRequestException(
          'Phải chọn ít nhất một ngày làm việc',
        );
      }
    }

    // =====================================================
    // DEADLINE
    // =====================================================

    if (
      dto.deadline !== undefined &&
      dto.deadline !== null &&
      new Date(
        dto.deadline,
      ) <= new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển phải lớn hơn thời điểm hiện tại',
      );
    }

    // =====================================================
    // URGENT
    // =====================================================

    const nextUrgent =
      dto.urgent ??
      job.urgent;

    let nextUrgentUntil:
      Date | null =
        job.urgentUntil;

    if (
      dto.urgentUntil !==
      undefined
    ) {
      nextUrgentUntil =
        dto.urgentUntil === null
          ? null
          : new Date(
              dto.urgentUntil,
            );
    }

    if (!nextUrgent) {
      nextUrgentUntil =
        null;
    }

    if (
      nextUrgent &&
      nextUrgentUntil === null
    ) {
      throw new BadRequestException(
        'Tin tuyển gấp phải có thời gian kết thúc tuyển gấp',
      );
    }

    if (
      nextUrgentUntil &&
      nextUrgentUntil <=
        new Date()
    ) {
      throw new BadRequestException(
        'Thời gian tuyển gấp phải lớn hơn thời điểm hiện tại',
      );
    }

    // =====================================================
    // UPDATE
    // =====================================================

    return this.prisma.$transaction(
      async (tx) => {
        await tx.job.update({
          where: {
            id: jobId,
          },

          data: {
            // =============================================
            // BASIC
            // =============================================

            ...(
              dto.title !==
                undefined && {
                title:
                  dto.title.trim(),
              }
            ),

            ...(
              dto.description !==
                undefined && {
                description:
                  dto.description.trim(),
              }
            ),

            ...(
              dto.categoryId !==
                undefined && {
                categoryId:
                  dto.categoryId,
              }
            ),

            // =============================================
            // SALARY
            // =============================================

            ...(
              dto.salary !==
                undefined && {
                salary:
                  dto.salary,
              }
            ),

            ...(
              dto.salaryType !==
                undefined && {
                salaryType:
                  dto.salaryType,
              }
            ),

            // =============================================
            // LOCATION
            // =============================================

            ...(
              dto.location !==
                undefined && {
                location:
                  dto.location.trim(),
              }
            ),

            ...(
              dto.latitude !==
                undefined && {
                latitude:
                  dto.latitude,
              }
            ),

            ...(
              dto.longitude !==
                undefined && {
                longitude:
                  dto.longitude,
              }
            ),

            // =============================================
            // SCHEDULE
            // =============================================

            ...(
              dto.shiftType !==
                undefined && {
                shiftType:
                  dto.shiftType,
              }
            ),

            ...(
              dto.startTime !==
                undefined && {
                startTime:
                  this.timeStringToDate(
                    dto.startTime,
                  ),
              }
            ),

            ...(
              dto.endTime !==
                undefined && {
                endTime:
                  this.timeStringToDate(
                    dto.endTime,
                  ),
              }
            ),

            ...(
              dto.workDays !==
                undefined && {
                workDays:
                  dto.workDays,
              }
            ),

            // =============================================
            // URGENT
            // =============================================

            ...(
              dto.urgent !==
                undefined && {
                urgent:
                  dto.urgent,
              }
            ),

            ...(
              (
                dto.urgent !==
                  undefined ||
                dto.urgentUntil !==
                  undefined
              ) && {
                urgentUntil:
                  nextUrgentUntil,
              }
            ),

            // =============================================
            // CV
            // =============================================

            ...(
              dto.cvRequired !==
                undefined && {
                cvRequired:
                  dto.cvRequired,
              }
            ),

            // =============================================
            // DEADLINE
            // =============================================

            ...(
              dto.deadline !==
                undefined && {
                deadline:
                  dto.deadline ===
                    null
                    ? null
                    : new Date(
                        dto.deadline,
                      ),
              }
            ),
          },
        });

        // =================================================
        // REPLACE SKILLS
        // =================================================

        if (
          dto.skillIds !==
          undefined
        ) {
          await tx.jobSkill.deleteMany({
            where: {
              jobId,
            },
          });

          if (
            dto.skillIds.length >
            0
          ) {
            await tx.jobSkill.createMany({
              data:
                dto.skillIds.map(
                  (skillId) => ({
                    jobId,
                    skillId,
                  }),
                ),
            });
          }
        }

        // =================================================
        // RESULT
        // =================================================

        return tx.job.findUnique({
          where: {
            id:
              jobId,
          },

          include: {
            category:
              true,

            jobSkills: {
              include: {
                skill:
                  true,
              },
            },

            _count: {
              select: {
                applications:
                  true,
              },
            },
          },
        });
      },
    );
  }

  // =====================================================
  // PUBLISH JOB
  // =====================================================

  async publishJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

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
          id:
            jobId,

          employerId:
            employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (
      job.status !==
      'DRAFT'
    ) {
      throw new BadRequestException(
        'Chỉ tin DRAFT mới có thể được đăng',
      );
    }

    if (
      job.deadline &&
      job.deadline <=
        new Date()
    ) {
      throw new BadRequestException(
        'Hạn ứng tuyển đã hết',
      );
    }

    return this.prisma.job.update({
      where: {
        id:
          jobId,
      },

      data: {
        status:
          'PUBLISHED',
      },
    });
  }

  // =====================================================
  // CLOSE JOB
  // =====================================================

  async closeJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

    const job =
      await this.prisma.job.findFirst({
        where: {
          id:
            jobId,

          employerId:
            employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (
      job.status !==
      'PUBLISHED'
    ) {
      throw new BadRequestException(
        'Chỉ tin đang PUBLISHED mới có thể đóng',
      );
    }

    return this.prisma.job.update({
      where: {
        id:
          jobId,
      },

      data: {
        status:
          'CLOSED',
      },
    });
  }

  // =====================================================
  // REPUBLISH JOB
  // =====================================================

  async republishJob(
    userId: string,
    jobId: string,
  ) {
    const employer =
      await this.getEmployer(
        userId,
      );

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
          id:
            jobId,

          employerId:
            employer.id,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
      );
    }

    if (
      job.status !==
      'CLOSED'
    ) {
      throw new BadRequestException(
        'Chỉ tin CLOSED mới có thể đăng lại',
      );
    }

    if (
      job.deadline &&
      job.deadline <=
        new Date()
    ) {
      throw new BadRequestException(
        'Hãy cập nhật hạn ứng tuyển mới trước khi đăng lại',
      );
    }

    return this.prisma.job.update({
      where: {
        id:
          jobId,
      },

      data: {
        status:
          'PUBLISHED',
      },
    });
  }

  // =====================================================
  // ACTIVE CATEGORIES
  // =====================================================

  async getActiveCategories() {
    return this.prisma.category.findMany({
      where: {
        status:
          true,
      },

      orderBy: {
        name:
          'asc',
      },
    });
  }

  // =====================================================
  // ACTIVE SKILLS
  // =====================================================

  async getActiveSkills() {
    return this.prisma.skill.findMany({
      where: {
        status:
          true,
      },

      orderBy: {
        name:
          'asc',
      },
    });
  }

  // =====================================================
  // WORKER SEARCH JOBS
  // =====================================================

  async searchJobs(
    userId: string,
    dto: SearchJobsDto,
  ) {
    // =====================================================
    // WORKER PROFILE
    //
    // WorkerProfile KHÔNG bắt buộc để xem / tìm Job.
    // Nếu có profile thì dùng vị trí đã lưu làm fallback
    // cho filter khoảng cách.
    // =====================================================

    const worker =
      await this.prisma.workerProfile.findUnique({
        where: {
          userId,
        },
      });

    // =====================================================
    // VALIDATION - SALARY
    // =====================================================

    if (
      dto.minSalary !== undefined &&
      dto.maxSalary !== undefined &&
      dto.minSalary > dto.maxSalary
    ) {
      throw new BadRequestException(
        'Mức lương tối thiểu không được lớn hơn mức lương tối đa',
      );
    }

    // =====================================================
    // VALIDATION - LOCATION
    //
    // Nếu client tự truyền tọa độ thì phải có đủ cả 2.
    // =====================================================

    if (
      (dto.latitude === undefined) !==
      (dto.longitude === undefined)
    ) {
      throw new BadRequestException(
        'Phải cung cấp đầy đủ latitude và longitude',
      );
    }

    // =====================================================
    // LOCATION ORIGIN
    //
    // Thứ tự ưu tiên:
    // 1. Tọa độ Flutter truyền lên
    // 2. Tọa độ lưu trong WorkerProfile
    // 3. undefined nếu chưa có vị trí
    // =====================================================

    const workerLatitude =
      worker?.latitude != null
        ? Number(worker.latitude)
        : undefined;

    const workerLongitude =
      worker?.longitude != null
        ? Number(worker.longitude)
        : undefined;

    const latitude =
      dto.latitude ??
      workerLatitude;

    const longitude =
      dto.longitude ??
      workerLongitude;

    // Chỉ khi Worker thực sự lọc theo khoảng cách
    // mới bắt buộc phải có vị trí.
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

    // =====================================================
    // BASE CONDITIONS
    // =====================================================

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

    // =====================================================
    // KEYWORD
    //
    // Tìm trong:
    // - tên Job
    // - mô tả
    // - địa điểm
    // - tên lĩnh vực
    // =====================================================

    const keyword =
      dto.keyword?.trim();

    if (
      keyword &&
      keyword.length > 0
    ) {
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
          {
            category: {
              name: {
                contains: keyword,
                mode: 'insensitive',
              },
            },
          },
        ],
      });
    }

    // =====================================================
    // LOCATION TEXT
    // =====================================================

    const locationText =
      dto.location?.trim();

    if (
      locationText &&
      locationText.length > 0
    ) {
      andConditions.push({
        location: {
          contains: locationText,
          mode: 'insensitive',
        },
      });
    }

    // =====================================================
    // SALARY TYPE
    //
    // HOURLY
    // DAILY
    // SHIFT
    // MONTHLY
    // FIXED
    // =====================================================

    if (
      dto.salaryType !== undefined
    ) {
      andConditions.push({
        salaryType:
          dto.salaryType,
      });
    }

    // =====================================================
    // SHIFT TYPE
    //
    // MORNING
    // AFTERNOON
    // EVENING
    // NIGHT
    // FLEXIBLE
    // =====================================================

    if (
      dto.shiftType !== undefined
    ) {
      andConditions.push({
        shiftType:
          dto.shiftType,
      });
    }

    // =====================================================
    // WORK DAYS
    //
    // Chỉ cần Job chứa ÍT NHẤT 1 ngày Worker chọn.
    //
    // Ví dụ Worker chọn:
    // SATURDAY, SUNDAY
    //
    // Job làm:
    // FRIDAY, SATURDAY
    //
    // => vẫn match vì có SATURDAY.
    // =====================================================

    if (
      dto.workDays !== undefined &&
      dto.workDays.length > 0
    ) {
      andConditions.push({
        workDays: {
          hasSome:
            dto.workDays,
        },
      });
    }

    // =====================================================
    // SKILLS
    //
    // Job có ít nhất một skill nằm trong danh sách lọc.
    // =====================================================

    if (
      dto.skillIds !== undefined &&
      dto.skillIds.length > 0
    ) {
      andConditions.push({
        jobSkills: {
          some: {
            skillId: {
              in:
                dto.skillIds,
            },
          },
        },
      });
    }

    // =====================================================
    // QUERY DATABASE
    //
    // Chỉ lấy:
    // - PUBLISHED
    // - chưa hết deadline
    // =====================================================

    const jobs =
      await this.prisma.job.findMany({
        where: {
          status:
            'PUBLISHED',

          // ===============================================
          // CATEGORY
          // ===============================================

          ...(
            dto.categoryId
              ? {
                  categoryId:
                    dto.categoryId,
                }
              : {}
          ),

          // ===============================================
          // CV
          // ===============================================

          ...(
            dto.cvRequired !== undefined
              ? {
                  cvRequired:
                    dto.cvRequired,
                }
              : {}
          ),

          // ===============================================
          // SALARY RANGE
          // ===============================================

          ...(
            dto.minSalary !== undefined ||
            dto.maxSalary !== undefined
              ? {
                  salary: {
                    ...(
                      dto.minSalary !== undefined
                        ? {
                            gte:
                              dto.minSalary,
                          }
                        : {}
                    ),

                    ...(
                      dto.maxSalary !== undefined
                        ? {
                            lte:
                              dto.maxSalary,
                          }
                        : {}
                    ),
                  },
                }
              : {}
          ),

          AND:
            andConditions,
        },

        include: {
          // ===============================================
          // CATEGORY
          // ===============================================

          category:
            true,

          // ===============================================
          // EMPLOYER
          // ===============================================

          employer: {
            select: {
              id:
                true,

              companyName:
                true,

              logoUrl:
                true,

              address:
                true,

              verificationStatus:
                true,
            },
          },

          // ===============================================
          // SKILLS
          // ===============================================

          jobSkills: {
            include: {
              skill:
                true,
            },
          },

          // ===============================================
          // APPLICATION COUNT
          // ===============================================

          _count: {
            select: {
              applications:
                true,
            },
          },
        },

        // Mặc định newest trước.
        orderBy: {
          createdAt:
            'desc',
        },
      });

    // =====================================================
    // CALCULATE EXTRA VALUES
    // =====================================================

    const now =
      new Date();

    let result =
      jobs.map(
        (job) => {
          // ===============================================
          // DISTANCE
          // ===============================================

          let distanceKm:
            number | null = null;

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
                Number(
                  job.latitude,
                ),
                Number(
                  job.longitude,
                ),
              );

            distanceKm =
              Math.round(
                distanceKm * 10,
              ) / 10;
          }

          // ===============================================
          // EFFECTIVE URGENT
          //
          // urgent=true nhưng urgentUntil đã qua
          // thì Worker không còn thấy là tuyển gấp.
          // ===============================================

          const isUrgent =
            job.urgent &&
            (
              job.urgentUntil === null ||
              job.urgentUntil > now
            );

          return {
            ...job,

            distanceKm,

            isUrgent,
          };
        },
      );

    // =====================================================
    // DISTANCE FILTER
    // =====================================================

    if (
      dto.maxDistanceKm !== undefined
    ) {
      result =
        result.filter(
          (job) =>
            job.distanceKm !== null &&
            job.distanceKm <=
              dto.maxDistanceKm!,
        );
    }

    // =====================================================
    // URGENT FILTER
    // =====================================================

    if (
      dto.urgent !== undefined
    ) {
      result =
        result.filter(
          (job) =>
            job.isUrgent ===
            dto.urgent,
        );
    }

    // =====================================================
    // SORT
    // =====================================================

    switch (
      dto.sort
    ) {
      // ===================================================
      // SALARY LOW -> HIGH
      // ===================================================

    case JobSortDto.SALARY_ASC:
      result.sort(
        (a, b) => {
          if (
            a.salary === null &&
            b.salary === null
          ) {
            return 0;
          }

          if (
            a.salary === null
          ) {
            return 1;
          }

          if (
            b.salary === null
          ) {
            return -1;
          }

          return (
            Number(a.salary) -
            Number(b.salary)
          );
        },
      );

      break;

      // ===================================================
      // SALARY HIGH -> LOW
      // ===================================================

      case JobSortDto.SALARY_DESC:
        result.sort((a, b) => {
            if (
              a.salary === null &&
              b.salary === null
            ) {
              return 0;
            }

            if (
              a.salary === null
            ) {
              return 1;
            }

            if (
              b.salary === null
            ) {
              return -1;
            }

            return (
              Number(b.salary) -
              Number(a.salary)
            );
          });

        break;

      // ===================================================
      // DISTANCE
      // ===================================================

      case JobSortDto.DISTANCE:
        result.sort(
          (a, b) => {
            if (
              a.distanceKm === null &&
              b.distanceKm === null
            ) {
              return 0;
            }

            if (
              a.distanceKm === null
            ) {
              return 1;
            }

            if (
              b.distanceKm === null
            ) {
              return -1;
            }

            return (
              a.distanceKm -
              b.distanceKm
            );
          });

        break;

      // ===================================================
      // NEWEST
      // ===================================================

      case JobSortDto.NEWEST:
      default:
        // Prisma đã orderBy createdAt DESC.
        break;
    }

    // =====================================================
    // PAGINATION
    // =====================================================

    const page =
      dto.page ?? 1;

    const limit =
      dto.limit ?? 20;

    const total =
      result.length;

    const totalPages =
      total === 0
        ? 0
        : Math.ceil(
            total / limit,
          );

    const start =
      (page - 1) *
      limit;

    const items =
      result.slice(
        start,
        start + limit,
      );

    // =====================================================
    // RESPONSE
    // =====================================================

    return {
      page,

      limit,

      total,

      totalPages,

      items,
    };
  }

  // =====================================================
  // WORKER JOB DETAIL
  // =====================================================

  async getPublishedJobById(
    jobId: string,
  ) {
    const job =
      await this.prisma.job.findFirst({
        where: {
          id:
            jobId,

          status:
            'PUBLISHED',

          OR: [
            {
              deadline:
                null,
            },

            {
              deadline: {
                gt:
                  new Date(),
              },
            },
          ],
        },

        include: {
          category:
            true,

          employer: {
            select: {
              id:
                true,

              companyName:
                true,

              description:
                true,

              logoUrl:
                true,

              address:
                true,

              verificationStatus:
                true,
            },
          },

          jobSkills: {
            include: {
              skill:
                true,
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