import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

interface CandidateMatchAiResponse {
  matchingScore: number;
  semanticScore: number;
  skillScore: number;
  categoryScore: number;
  reasons: string[];
}

@Injectable()
export class CandidateMatchingService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async calculateForApplication(
    applicationId: string,
  ) {
    const application =
      await this.prisma.application.findUnique({
        where: {
          id: applicationId,
        },

        include: {
          job: {
            include: {
              category: true,

              jobSkills: {
                include: {
                  skill: true,
                },
              },
            },
          },

          worker: {
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
          },
        },
      });

    if (!application) {
      throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
      );
    }

    const payload = {
      jobTitle:
        application.job.title,

      jobDescription:
        application.job.description,

      jobCategory:
        application.job.category?.name ?? null,

      requiredSkills:
        application.job.jobSkills.map(
          (item) => item.skill.name,
        ),

      workerBio:
        application.worker.bio ?? null,

      workerSkills:
        application.worker.workerSkills.map(
          (item) => item.skill.name,
        ),

      workerCategories:
        application.worker.workerCategories.map(
          (item) => item.category.name,
        ),

      experiences:
        application.worker.workExperiences.map(
          (experience) =>
            [
              experience.position,
              experience.companyName,
              experience.description ?? '',
            ]
              .filter(Boolean)
              .join(' - '),
        ),
    };

    const aiServiceUrl =
      process.env.AI_SERVICE_URL ??
      'http://127.0.0.1:8000';

    let response: Response;

    try {
      response = await fetch(
        `${aiServiceUrl}/candidate-match`,
        {
          method: 'POST',

          headers: {
            'Content-Type':
              'application/json',
          },

          body: JSON.stringify(payload),
        },
      );
    } catch (error) {
      console.error(
        'Không kết nối được AI Service:',
        error,
      );

      throw new InternalServerErrorException(
        'Không thể kết nối AI Service',
      );
    }

    if (!response.ok) {
      const errorText =
        await response.text();

      console.error(
        'AI Service error:',
        errorText,
      );

      throw new InternalServerErrorException(
        'AI Service xử lý thất bại',
      );
    }

    const result =
      (await response.json()) as CandidateMatchAiResponse;

    return this.prisma.candidateMatch.upsert({
    where: {
        applicationId,
    },

    update: {
        matchingScore: result.matchingScore,

        reasons: JSON.stringify(
        result.reasons,
        ),
    },

    create: {
        applicationId,

        matchingScore: result.matchingScore,

        reasons: JSON.stringify(
        result.reasons,
        ),
    },
    });
  }
}