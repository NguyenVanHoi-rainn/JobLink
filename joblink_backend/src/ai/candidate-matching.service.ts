import {
  Injectable,
  Logger,
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
  private readonly logger = new Logger(CandidateMatchingService.name);

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

    let result: CandidateMatchAiResponse;

    try {
      // Thiết lập Timeout 10 giây chống treo request
      const response = await fetch(
        `${aiServiceUrl}/candidate-match`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(10000), 
        },
      );

      if (!response.ok) {
        throw new Error(`AI Service HTTP error status: ${response.status}`);
      }

      result = (await response.json()) as CandidateMatchAiResponse;
    } catch (error) {
      this.logger.error('Sự cố AI Candidate Match, kích hoạt Fallback local:', error);

      // FALLBACK MECHANISM: Tự tính toán điểm cơ bản dựa trên độ trùng Skill/Category
      const reqSkills = new Set(payload.requiredSkills.map(s => s.toLowerCase()));
      const wSkills = new Set(payload.workerSkills.map(s => s.toLowerCase()));
      
      let matchedCount = 0;
      reqSkills.forEach(s => { if (wSkills.has(s)) matchedCount++; });
      
      const skillScore = reqSkills.size > 0 ? (matchedCount / reqSkills.size) * 100 : 70;
      const categoryMatch = payload.jobCategory && payload.workerCategories.includes(payload.jobCategory);
      const categoryScore = categoryMatch ? 100 : 0;
      
      const fallbackMatchingScore = Math.round(skillScore * 0.7 + categoryScore * 0.3);

      result = {
        matchingScore: fallbackMatchingScore,
        semanticScore: 50,
        skillScore: Math.round(skillScore),
        categoryScore,
        reasons: [
          `Khớp ${matchedCount}/${reqSkills.size} kỹ năng yêu cầu (Tính toán dự phòng).`,
          categoryMatch ? 'Ngành nghề phù hợp.' : 'Ngành nghề chưa trùng khớp.',
        ],
      };
    }

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