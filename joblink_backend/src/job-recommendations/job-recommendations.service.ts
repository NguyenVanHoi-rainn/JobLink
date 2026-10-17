import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

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
    private readonly prisma: PrismaService,
  ) {}

  async getRecommendations(
    userId: string,
  ) {
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

        workExperiences: true,
        },

      });

    if (!worker) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    const jobs =
      await this.prisma.job.findMany({
        where: {
          status: 'PUBLISHED',

          deadline: {
            gte: new Date(),
          },
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

    if (jobs.length === 0) {
      return [];
    }

    const payload = {
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

      // Không phụ thuộc tên field bên trong WorkExperience.
        workerExperienceText:
        JSON.stringify(
            worker.workExperiences,
        ),

      workerLatitude:
        worker.latitude !== null
          ? Number(worker.latitude)
          : null,

      workerLongitude:
        worker.longitude !== null
          ? Number(worker.longitude)
          : null,

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

            latitude:
              job.latitude !== null
                ? Number(job.latitude)
                : null,

            longitude:
              job.longitude !== null
                ? Number(job.longitude)
                : null,
          }),
        ),
    };

    const aiUrl =
      process.env.AI_SERVICE_URL ??
      'http://127.0.0.1:8000';

    let response: Response;

    try {
      response =
        await fetch(
          `${aiUrl}/job-recommendations`,
          {
            method: 'POST',

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
    } catch {
      throw new ServiceUnavailableException(
        'Không thể kết nối AI Service',
      );
    }

    if (!response.ok) {
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

    const result =
    (await response.json()) as AiRecommendationResponse;

    // Xóa recommendation cũ của
    // các Job không còn nằm trong tập hiện tại.
    const currentJobIds =
      jobs.map(
        (job) => job.id,
      );

    await this.prisma.jobRecommendation.deleteMany({
      where: {
        workerId:
          worker.id,

        jobId: {
          notIn:
            currentJobIds,
        },
      },
    });

    // Lưu / cập nhật điểm AI.
    for (
      const recommendation
      of result.recommendations
    ) {
      await this.prisma.jobRecommendation.upsert({
        where: {
          workerId_jobId: {
            workerId:
              worker.id,

            jobId:
              recommendation.jobId,
          },
        },

        update: {
          score:
            recommendation.score,

          reasons:
            JSON.stringify(
              recommendation.reasons,
            ),

          createdAt:
            new Date(),
        },

        create: {
          workerId:
            worker.id,

          jobId:
            recommendation.jobId,

          score:
            recommendation.score,

          reasons:
            JSON.stringify(
              recommendation.reasons,
            ),
        },
      });
    }

    // Trả kết quả từ DB,
    // sắp xếp điểm cao xuống thấp.
    const recommendations =
      await this.prisma.jobRecommendation.findMany({
        where: {
          workerId:
            worker.id,

          job: {
            status:
              'PUBLISHED',
          },
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
          score:
            'desc',
        },
      });

    return recommendations.map(
      (item) => ({
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
          ...item.job,

          salary:
            Number(
              item.job.salary,
            ),
        },
      }),
    );
  }

  private parseReasons(
    reasons: string,
  ): string[] {
    try {
      const parsed =
        JSON.parse(
          reasons,
        );

      return Array.isArray(
        parsed,
      )
        ? parsed
        : [];
    } catch {
      return [
        reasons,
      ];
    }
  }
}