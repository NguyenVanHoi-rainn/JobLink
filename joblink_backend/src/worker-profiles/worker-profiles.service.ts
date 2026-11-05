import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  PrismaService,
} from '../prisma/prisma.service.js';

import {
  UpdateWorkerProfileDto,
} from './dto/update-worker-profile.dto.js';

@Injectable()
export class WorkerProfilesService {
  constructor(
    private readonly prisma:
      PrismaService,
  ) {}

  // =====================================================
  // ENSURE WORKER PROFILE
  //
  // Worker không bắt buộc hoàn thiện Profile.
  // Tuy nhiên hệ thống vẫn tạo record rỗng để các relation
  // Application / CV / Skill... hoạt động bình thường.
  // =====================================================

  async ensureProfile(
    userId: string,
  ) {
    const user =
      await this.prisma.user.findUnique({
        where: {
          id: userId,
        },

        select: {
          id: true,
          role: true,
          status: true,
        },
      });

    if (!user) {
      throw new NotFoundException(
        'Không tìm thấy tài khoản',
      );
    }

    if (user.role !== 'WORKER') {
      throw new ForbiddenException(
        'Chỉ Worker mới có hồ sơ Worker',
      );
    }

    return this.prisma.workerProfile.upsert({
      where: {
        userId,
      },

      update: {},

      create: {
        userId,
      },
    });
  }

  // =====================================================
  // GET PROFILE
  // =====================================================

  async getMyProfile(
    userId: string,
  ) {
    await this.ensureProfile(
      userId,
    );

    const profile =
      await this.prisma.workerProfile.findUnique({
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

          workerSkills: {
            include: {
              skill: true,
            },

            orderBy: {
              skill: {
                name: 'asc',
              },
            },
          },

          workerCategories: {
            include: {
              category: true,
            },

            orderBy: {
              category: {
                name: 'asc',
              },
            },
          },

          availabilities: {
            orderBy: {
              dayOfWeek: 'asc',
            },
          },

          cvs: {
            orderBy: {
              uploadedAt: 'desc',
            },
          },
        },
      });

    if (!profile) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    return this.buildProfileResponse(
      profile,
    );
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  async updateMyProfile(
    userId: string,
    dto: UpdateWorkerProfileDto,
  ) {
    const profile =
      await this.ensureProfile(
        userId,
      );

    // ===================================================
    // LOCATION VALIDATION
    // ===================================================

    const hasLatitude =
      dto.latitude !== undefined;

    const hasLongitude =
      dto.longitude !== undefined;

    if (
      hasLatitude !==
      hasLongitude
    ) {
      throw new BadRequestException(
        'Phải cập nhật latitude và longitude cùng lúc',
      );
    }

    // ===================================================
    // SKILLS
    // ===================================================

    if (
      dto.skillIds !== undefined &&
      dto.skillIds.length > 0
    ) {
      const validSkills =
        await this.prisma.skill.count({
          where: {
            id: {
              in: dto.skillIds,
            },

            status: true,
          },
        });

      if (
        validSkills !==
        dto.skillIds.length
      ) {
        throw new BadRequestException(
          'Có kỹ năng không tồn tại hoặc đã bị vô hiệu hóa',
        );
      }
    }

    // ===================================================
    // CATEGORIES
    // ===================================================

    if (
      dto.categoryIds !== undefined &&
      dto.categoryIds.length > 0
    ) {
      const validCategories =
        await this.prisma.category.count({
          where: {
            id: {
              in: dto.categoryIds,
            },

            status: true,
          },
        });

      if (
        validCategories !==
        dto.categoryIds.length
      ) {
        throw new BadRequestException(
          'Có lĩnh vực không tồn tại hoặc đã bị vô hiệu hóa',
        );
      }
    }

    // ===================================================
    // AVAILABILITY
    // ===================================================

    if (
      dto.availabilities !==
      undefined
    ) {
      for (
        const availability
        of dto.availabilities
      ) {
        if (
          availability.startTime ===
          availability.endTime
        ) {
          throw new BadRequestException(
            'Giờ bắt đầu và giờ kết thúc không được giống nhau',
          );
        }
      }
    }

    // ===================================================
    // TRANSACTION
    // ===================================================

    await this.prisma.$transaction(
      async (tx) => {
        const data: any = {};

        if (
          dto.fullName !==
          undefined
        ) {
          data.fullName =
            this.normalizeText(
              dto.fullName,
            );
        }

        if (
          dto.phone !==
          undefined
        ) {
          data.phone =
            this.normalizeText(
              dto.phone,
            );
        }

        if (
          dto.bio !==
          undefined
        ) {
          data.bio =
            this.normalizeText(
              dto.bio,
            );
        }

        if (
          dto.searchArea !==
          undefined
        ) {
          data.searchArea =
            this.normalizeText(
              dto.searchArea,
            );
        }

        if (
          dto.latitude !==
          undefined
        ) {
          data.latitude =
            dto.latitude;
        }

        if (
          dto.longitude !==
          undefined
        ) {
          data.longitude =
            dto.longitude;
        }

        if (
          dto.maxDistanceKm !==
          undefined
        ) {
          data.maxDistanceKm =
            dto.maxDistanceKm;
        }

        if (
          dto.preferredMinSalary !==
          undefined
        ) {
          data.preferredMinSalary =
            dto.preferredMinSalary;
        }

        if (
          dto.preferredSalaryType !==
          undefined
        ) {
          data.preferredSalaryType =
            dto.preferredSalaryType;
        }

        if (
          Object.keys(data).length >
          0
        ) {
          await tx.workerProfile.update({
            where: {
              id: profile.id,
            },

            data,
          });
        }

        // ===============================================
        // REPLACE SKILLS
        // ===============================================

        if (
          dto.skillIds !==
          undefined
        ) {
          await tx.workerSkill.deleteMany({
            where: {
              workerId:
                profile.id,
            },
          });

          if (
            dto.skillIds.length >
            0
          ) {
            await tx.workerSkill.createMany({
              data:
                dto.skillIds.map(
                  (skillId) => ({
                    workerId:
                      profile.id,

                    skillId,
                  }),
                ),
            });
          }
        }

        // ===============================================
        // REPLACE CATEGORIES
        // ===============================================

        if (
          dto.categoryIds !==
          undefined
        ) {
          await tx.workerCategory.deleteMany({
            where: {
              workerId:
                profile.id,
            },
          });

          if (
            dto.categoryIds.length >
            0
          ) {
            await tx.workerCategory.createMany({
              data:
                dto.categoryIds.map(
                  (categoryId) => ({
                    workerId:
                      profile.id,

                    categoryId,
                  }),
                ),
            });
          }
        }

        // ===============================================
        // REPLACE AVAILABILITY
        // ===============================================

        if (
          dto.availabilities !==
          undefined
        ) {
          await tx.workerAvailability.deleteMany({
            where: {
              workerId:
                profile.id,
            },
          });

          if (
            dto.availabilities.length >
            0
          ) {
            await tx.workerAvailability.createMany({
              data:
                dto.availabilities.map(
                  (item) => ({
                    workerId:
                      profile.id,

                    dayOfWeek:
                      item.dayOfWeek,

                    startTime:
                      this.timeToDate(
                        item.startTime,
                      ),

                    endTime:
                      this.timeToDate(
                        item.endTime,
                      ),
                  }),
                ),
            });
          }
        }
      },
    );

    return this.getMyProfile(
      userId,
    );
  }

  // =====================================================
  // AI PROFILE STATUS
  // =====================================================

    private buildProfileResponse(
    profile: any,
    ) {
    // =====================================================
    // SKILLS
    // =====================================================

    const skills =
        profile.workerSkills.map(
        (item: any) => ({
            id:
            item.skill.id,

            name:
            item.skill.name,
        }),
        );

    // =====================================================
    // CATEGORIES
    // =====================================================

    const categories =
        profile.workerCategories.map(
        (item: any) => ({
            id:
            item.category.id,

            name:
            item.category.name,
        }),
        );

    // =====================================================
    // AVAILABILITIES
    // =====================================================

    const availabilities =
        profile.availabilities.map(
        (item: any) => ({
            id:
            item.id,

            dayOfWeek:
            item.dayOfWeek,

            startTime:
            this.formatTime(
                item.startTime,
            ),

            endTime:
            this.formatTime(
                item.endTime,
            ),
        }),
        );

    // =====================================================
    // AI REQUIRED FIELDS
    //
    // Chỉ 3 phần này bắt buộc để bật AI:
    //
    // - SKILLS
    // - CATEGORIES
    // - AVAILABILITY
    //
    // LOCATION và SALARY chỉ giúp AI xếp hạng tốt hơn.
    // =====================================================

    const missingRequiredFields:
        string[] =
        [];

    if (
        skills.length ===
        0
    ) {
        missingRequiredFields.push(
        'SKILLS',
        );
    }

    if (
        categories.length ===
        0
    ) {
        missingRequiredFields.push(
        'CATEGORIES',
        );
    }

    if (
        availabilities.length ===
        0
    ) {
        missingRequiredFields.push(
        'AVAILABILITY',
        );
    }

    // =====================================================
    // AI OPTIONAL FIELDS
    // =====================================================

    const missingOptionalFields:
        string[] =
        [];

    // =====================================================
    // LOCATION
    // =====================================================

    const hasCoordinates =
        profile.latitude !==
        null &&
        profile.longitude !==
        null;

    const hasSearchArea =
        profile.searchArea !==
        null &&
        profile.searchArea
        .trim()
        .length >
        0;

    const hasLocation =
        hasCoordinates ||
        hasSearchArea;

    if (
        !hasLocation
    ) {
        missingOptionalFields.push(
        'LOCATION',
        );
    }

    // =====================================================
    // SALARY
    // =====================================================

    const hasSalaryPreference =
        profile.preferredMinSalary !==
        null &&
        profile.preferredSalaryType !==
        null;

    if (
        !hasSalaryPreference
    ) {
        missingOptionalFields.push(
        'SALARY',
        );
    }

    // =====================================================
    // AI READY
    //
    // Không yêu cầu Location hoặc Salary.
    // =====================================================

    const ready =
        missingRequiredFields.length ===
        0;

    // =====================================================
    // COMPLETION PERCENT
    //
    // Phần trăm vẫn tính cả 5 phần để thể hiện
    // mức độ hoàn thiện hồ sơ.
    //
    // Nhưng completionPercent KHÔNG quyết định ready.
    // =====================================================

    const totalAiSections =
        5;

    const missingAllFields = [
        ...missingRequiredFields,
        ...missingOptionalFields,
    ];

    const completed =
        totalAiSections -
        missingAllFields.length;

    const completionPercent =
        Math.round(
        (
            completed /
            totalAiSections
        ) *
            100,
        );

    // =====================================================
    // RESPONSE
    // =====================================================

    return {
        id:
        profile.id,

        userId:
        profile.userId,

        email:
        profile.user.email,

        fullName:
        profile.fullName,

        phone:
        profile.phone,

        bio:
        profile.bio,

        searchArea:
        profile.searchArea,

        latitude:
        profile.latitude ===
        null
            ? null
            : Number(
                profile.latitude,
            ),

        longitude:
        profile.longitude ===
        null
            ? null
            : Number(
                profile.longitude,
            ),

        preferredMinSalary:
        profile.preferredMinSalary ===
        null
            ? null
            : Number(
                profile.preferredMinSalary,
            ),

        preferredSalaryType:
        profile.preferredSalaryType,

        maxDistanceKm:
        profile.maxDistanceKm,

        skills,

        categories,

        availabilities,

        cvs:
        profile.cvs,

        // ===================================================
        // AI PROFILE
        // ===================================================

        aiProfile: {
        ready,

        completionPercent,

        // Giữ field cũ để Flutter hiện tại
        // không bị lỗi.
        //
        // missingFields chỉ chứa field BẮT BUỘC.
        missingFields:
            missingRequiredFields,

        // Field mới rõ nghĩa hơn.
        missingRequiredFields,

        missingOptionalFields,
        },

        createdAt:
        profile.createdAt,

        updatedAt:
        profile.updatedAt,
    };
    }

  // =====================================================
  // HELPERS
  // =====================================================

  private normalizeText(
    value: string | null,
  ) {
    if (value === null) {
      return null;
    }

    const trimmed =
      value.trim();

    return trimmed.length ===
      0
      ? null
      : trimmed;
  }

  private timeToDate(
    value: string,
  ) {
    return new Date(
      `1970-01-01T${value}:00.000Z`,
    );
  }

  private formatTime(
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
}