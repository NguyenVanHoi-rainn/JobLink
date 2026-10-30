import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';

import {
  PrismaService,
} from '../prisma/prisma.service.js';

interface AiRecommendation {
  jobId: string;
  score: number;
  reasons: string[];
}

interface AiRecommendationResponse {
  recommendations: AiRecommendation[];
}

@Injectable()
export class JobRecommendationsService {
  constructor(
    private readonly prisma:
      PrismaService,
  ) {}

  // =====================================================
  // GET JOB RECOMMENDATIONS
  // =====================================================

  async getRecommendations(
    userId: string,
  ) {
    // ===================================================
    // WORKER PROFILE
    // ===================================================

    const worker =
      await this.prisma.workerProfile.findUnique({
        where: {
          userId,
        },

        include: {
          workerSkills: {
            include: {
              skill: true,
            },
          },

          workerCategories: {
            include: {
              category: true,
            },
          },

          availabilities: true,

          workExperiences: true,
        },
      });

    if (!worker) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    // ===================================================
    // AI READINESS
    //
    // REQUIRED:
    // - SKILLS
    // - CATEGORIES
    // - AVAILABILITY
    //
    // OPTIONAL:
    // - LOCATION
    // - SALARY
    // ===================================================

    const missingRequiredFields:
      string[] = [];

    if (
      worker.workerSkills.length ===
      0
    ) {
      missingRequiredFields.push(
        'SKILLS',
      );
    }

    if (
      worker.workerCategories.length ===
      0
    ) {
      missingRequiredFields.push(
        'CATEGORIES',
      );
    }

    if (
      worker.availabilities.length ===
      0
    ) {
      missingRequiredFields.push(
        'AVAILABILITY',
      );
    }

    if (
      missingRequiredFields.length >
      0
    ) {
      throw new BadRequestException(
        `Hồ sơ AI chưa sẵn sàng. Thiếu: ${missingRequiredFields.join(
          ', ',
        )}`,
      );
    }

    // ===================================================
    // CURRENT ACTIVE JOBS
    // ===================================================

    const now =
      new Date();

    const jobs =
      await this.prisma.job.findMany({
        where: {
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
                  now,
              },
            },
          ],
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

    // ===================================================
    // NO JOB
    // ===================================================

    if (
      jobs.length ===
      0
    ) {
      await this.prisma
        .jobRecommendation
        .deleteMany({
          where: {
            workerId:
              worker.id,
          },
        });

      return [];
    }

    // ===================================================
    // WORKER AVAILABILITY PAYLOAD
    // ===================================================

    const workerAvailabilities =
      worker.availabilities.map(
        (item) => ({
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

    // ===================================================
    // AI PAYLOAD
    // ===================================================

    const payload = {
      // ===============================================
      // WORKER CORE PROFILE
      // ===============================================

      workerSkills:
        worker.workerSkills.map(
          (item) =>
            item.skill.name,
        ),

      workerCategories:
        worker.workerCategories.map(
          (item) =>
            item.category.name,
        ),

      workerAvailabilities,

      workerExperienceText:
        JSON.stringify(
          worker.workExperiences,
        ),

      // ===============================================
      // OPTIONAL LOCATION
      // ===============================================

      workerLatitude:
        worker.latitude !==
        null
          ? Number(
              worker.latitude,
            )
          : null,

      workerLongitude:
        worker.longitude !==
        null
          ? Number(
              worker.longitude,
            )
          : null,

      // ===============================================
      // OPTIONAL SALARY
      // ===============================================

      workerPreferredMinSalary:
        worker.preferredMinSalary !==
        null
          ? Number(
              worker.preferredMinSalary,
            )
          : null,

      workerPreferredSalaryType:
        worker.preferredSalaryType ??
        null,

      // ===============================================
      // JOBS
      // ===============================================

      jobs:
        jobs.map(
          (job) => ({
            jobId:
              job.id,

            title:
              job.title,

            description:
              job.description,

            category:
              job.category?.name ??
              '',

            skills:
              job.jobSkills.map(
                (item) =>
                  item.skill.name,
              ),

            // =========================================
            // JOB LOCATION
            // =========================================

            latitude:
              job.latitude !==
              null
                ? Number(
                    job.latitude,
                  )
                : null,

            longitude:
              job.longitude !==
              null
                ? Number(
                    job.longitude,
                  )
                : null,

            // =========================================
            // JOB SALARY
            // =========================================

            salary:
              job.salary !==
              null
                ? Number(
                    job.salary,
                  )
                : null,

            salaryType:
              job.salaryType ??
              null,

            // =========================================
            // JOB SCHEDULE
            // =========================================

            shiftType:
              job.shiftType ??
              null,

            startTime:
              job.startTime
                ? this.formatTime(
                    job.startTime,
                  )
                : null,

            endTime:
              job.endTime
                ? this.formatTime(
                    job.endTime,
                  )
                : null,

            workDays:
              job.workDays ??
              [],
          }),
        ),
    };

    // ===================================================
    // AI SERVICE URL
    // ===================================================

    const aiUrl =
      process.env
        .AI_SERVICE_URL ??
      'http://127.0.0.1:8000';

    let response:
      Response;

    // ===================================================
    // CALL FASTAPI
    // ===================================================

    try {
      response =
        await fetch(
          `${aiUrl}/job-recommendations`,
          {
            method:
              'POST',

            headers: {
              'Content-Type':
                'application/json',
            },

            body:
              JSON.stringify(
                payload,
              ),
          },
        );
    } catch (error) {
      console.error(
        'AI Recommendation connection error:',
        error,
      );

      throw new ServiceUnavailableException(
        'Không thể kết nối AI Service',
      );
    }

    // ===================================================
    // AI ERROR
    // ===================================================

    if (
      !response.ok
    ) {
      const errorText =
        await response.text();

      console.error(
        'AI Recommendation error:',
        errorText,
      );

      throw new ServiceUnavailableException(
        'AI Service không thể tính gợi ý việc làm',
      );
    }

    // ===================================================
    // AI RESPONSE
    // ===================================================

    let result:
      AiRecommendationResponse;

    try {
      result =
        (
          await response.json()
        ) as AiRecommendationResponse;
    } catch {
      throw new ServiceUnavailableException(
        'AI Service trả về dữ liệu không hợp lệ',
      );
    }

    const rawRecommendations =
      Array.isArray(
        result.recommendations,
      )
        ? result.recommendations
        : [];

    // ===================================================
    // VALID CURRENT JOB IDS
    // ===================================================

    const currentJobIds =
      new Set(
        jobs.map(
          (job) =>
            job.id,
        ),
      );

    // ===================================================
    // NORMALIZE AI RESULT
    //
    // Python trả score từ 0 -> 100.
    // KHÔNG clamp 0 -> 1.
    // ===================================================

    const normalizedMap =
      new Map<
        string,
        {
          jobId: string;
          score: number;
          reasons: string[];
        }
      >();

    for (
      const recommendation
      of rawRecommendations
    ) {
      // AI không được quyền tạo jobId
      // không nằm trong tập job NestJS gửi.
      if (
        !currentJobIds.has(
          recommendation.jobId,
        )
      ) {
        continue;
      }

      const rawScore =
        Number(
          recommendation.score,
        );

      const score =
        Number.isFinite(
          rawScore,
        )
          ? Math.max(
              0,
              Math.min(
                100,
                rawScore,
              ),
            )
          : 0;

      const reasons =
        Array.isArray(
          recommendation.reasons,
        )
          ? recommendation
              .reasons
              .map(
                (reason) =>
                  String(
                    reason,
                  ).trim(),
              )
              .filter(
                (reason) =>
                  reason.length >
                  0,
              )
          : [];

      // Nếu AI vô tình trả trùng jobId,
      // lấy bản có score cao nhất.
      const existing =
        normalizedMap.get(
          recommendation.jobId,
        );

      if (
        !existing ||
        score >
          existing.score
      ) {
        normalizedMap.set(
          recommendation.jobId,
          {
            jobId:
              recommendation.jobId,

            score,

            reasons,
          },
        );
      }
    }

    const normalizedRecommendations =
      [
        ...normalizedMap.values(),
      ];

    // ===================================================
    // SAVE AI RESULT
    //
    // Mỗi lần AI chạy thành công:
    // xóa recommendation cũ và ghi bộ mới.
    // ===================================================

    await this.prisma.$transaction(
      async (tx) => {
        await tx.jobRecommendation
          .deleteMany({
            where: {
              workerId:
                worker.id,
            },
          });

        if (
          normalizedRecommendations
            .length >
          0
        ) {
          await tx.jobRecommendation
            .createMany({
              data:
                normalizedRecommendations
                  .map(
                    (
                      recommendation,
                    ) => ({
                      workerId:
                        worker.id,

                      jobId:
                        recommendation
                          .jobId,

                      score:
                        recommendation
                          .score,

                      reasons:
                        JSON.stringify(
                          recommendation
                            .reasons,
                        ),
                    }),
                  ),
            });
        }
      },
    );

    // ===================================================
    // LOAD SAVED RECOMMENDATIONS
    // ===================================================

    const recommendations =
      await this.prisma
        .jobRecommendation
        .findMany({
          where: {
            workerId:
              worker.id,

            job: {
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
          },

          include: {
            job: {
              include: {
                category:
                  true,

                employer: {
                  include: {
                    user:
                      true,
                  },
                },

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
            },
          },

          orderBy: {
            score:
              'desc',
          },
        });

    // ===================================================
    // RESPONSE
    // ===================================================

    return recommendations.map(
      (item) => {
        const job =
          item.job;

        const isUrgent =
          job.urgent &&
          (
            job.urgentUntil ===
              null ||
            job.urgentUntil >
              new Date()
          );

        return {
          ...item,

          score:
            Number(
              item.score,
            ),

          reasons:
            item.reasons
              ? this.parseReasons(
                  item.reasons,
                )
              : [],

          job: {
            ...job,

            salary:
              job.salary ===
              null
                ? null
                : Number(
                    job.salary,
                  ),

            latitude:
              job.latitude ===
              null
                ? null
                : Number(
                    job.latitude,
                  ),

            longitude:
              job.longitude ===
              null
                ? null
                : Number(
                    job.longitude,
                  ),

            isUrgent,
          },
        };
      },
    );
  }

  // =====================================================
  // FORMAT DATABASE TIME
  // =====================================================

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

  // =====================================================
  // PARSE AI REASONS
  // =====================================================

  private parseReasons(
    reasons: string,
  ): string[] {
    try {
      const parsed =
        JSON.parse(
          reasons,
        );

      if (
        !Array.isArray(
          parsed,
        )
      ) {
        return [];
      }

      return parsed
        .map(
          (reason) =>
            String(
              reason,
            ).trim(),
        )
        .filter(
          (reason) =>
            reason.length >
            0,
        );
    } catch {
      const value =
        reasons.trim();

      return value.length >
        0
        ? [
            value,
          ]
        : [];
    }
  }
}