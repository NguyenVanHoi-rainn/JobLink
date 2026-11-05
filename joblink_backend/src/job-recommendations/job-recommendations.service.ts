import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
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
  private readonly logger = new Logger(JobRecommendationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getRecommendations(userId: string) {
    // 1. Kiểm tra Hồ sơ Worker
    const worker = await this.prisma.workerProfile.findUnique({
      where: { userId },
      include: {
        workerSkills: { include: { skill: true } },
        workerCategories: { include: { category: true } },
        availabilities: true,
        workExperiences: true,
      },
    });

    if (!worker) {
      throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    // 2. Kiểm tra điều kiện AI sẵn sàng
    const missingRequiredFields: string[] = [];
    if (worker.workerSkills.length === 0) missingRequiredFields.push('SKILLS');
    if (worker.workerCategories.length === 0) missingRequiredFields.push('CATEGORIES');
    if (worker.availabilities.length === 0) missingRequiredFields.push('AVAILABILITY');

    if (missingRequiredFields.length > 0) {
      throw new BadRequestException(
        `Hồ sơ AI chưa sẵn sàng. Thiếu: ${missingRequiredFields.join(', ')}`,
      );
    }

    // 3. Lấy danh sách Job đang đăng tuyển
    const now = new Date();
    const jobs = await this.prisma.job.findMany({
      where: {
        status: 'PUBLISHED',
        OR: [{ deadline: null }, { deadline: { gt: now } }],
      },
      include: {
        category: true,
        jobSkills: { include: { skill: true } },
      },
    });

    if (jobs.length === 0) {
      await this.prisma.jobRecommendation.deleteMany({
        where: { workerId: worker.id },
      });
      return [];
    }

    // 4. Đóng gói Payload gửi sang FastAPI
    const workerAvailabilities = worker.availabilities.map((item) => ({
      dayOfWeek: item.dayOfWeek,
      startTime: this.formatTime(item.startTime),
      endTime: this.formatTime(item.endTime),
    }));

    const payload = {
      workerSkills: worker.workerSkills.map((item) => item.skill.name),
      workerCategories: worker.workerCategories.map((item) => item.category.name),
      workerAvailabilities,
      workerExperienceText: JSON.stringify(worker.workExperiences),
      workerLatitude: worker.latitude !== null ? Number(worker.latitude) : null,
      workerLongitude: worker.longitude !== null ? Number(worker.longitude) : null,
      workerPreferredMinSalary: worker.preferredMinSalary !== null ? Number(worker.preferredMinSalary) : null,
      workerPreferredSalaryType: worker.preferredSalaryType ?? null,
      jobs: jobs.map((job) => ({
        jobId: job.id,
        title: job.title,
        description: job.description,
        category: job.category?.name ?? '',
        skills: job.jobSkills.map((item) => item.skill.name),
        latitude: job.latitude !== null ? Number(job.latitude) : null,
        longitude: job.longitude !== null ? Number(job.longitude) : null,
        salary: job.salary !== null ? Number(job.salary) : null,
        salaryType: job.salaryType ?? null,
        shiftType: job.shiftType ?? null,
        startTime: job.startTime ? this.formatTime(job.startTime) : null,
        endTime: job.endTime ? this.formatTime(job.endTime) : null,
        workDays: job.workDays ?? [],
      })),
    };

    const aiUrl = process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000';

    // 5. Gọi AI Service kèm Timeout 8 giây & Fallback
    try {
      const response = await fetch(`${aiUrl}/job-recommendations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(8000),
      });

      if (!response.ok) {
        throw new Error(`AI Service HTTP error: ${response.status}`);
      }

      const result = (await response.json()) as AiRecommendationResponse;
      const rawRecommendations = Array.isArray(result.recommendations) ? result.recommendations : [];

      const currentJobIds = new Set(jobs.map((job) => job.id));
      const normalizedMap = new Map<string, { jobId: string; score: number; reasons: string[] }>();

      for (const recommendation of rawRecommendations) {
        if (!currentJobIds.has(recommendation.jobId)) continue;

        const rawScore = Number(recommendation.score);
        const score = Number.isFinite(rawScore) ? Math.max(0, Math.min(100, rawScore)) : 0;
        const reasons = Array.isArray(recommendation.reasons)
          ? recommendation.reasons.map((r) => String(r).trim()).filter((r) => r.length > 0)
          : [];

        const existing = normalizedMap.get(recommendation.jobId);
        if (!existing || score > existing.score) {
          normalizedMap.set(recommendation.jobId, {
            jobId: recommendation.jobId,
            score,
            reasons,
          });
        }
      }

      const normalizedRecommendations = [...normalizedMap.values()];

      // 6. Lưu kết quả AI vào Database Transaction
      await this.prisma.$transaction(async (tx) => {
        await tx.jobRecommendation.deleteMany({ where: { workerId: worker.id } });

        if (normalizedRecommendations.length > 0) {
          await tx.jobRecommendation.createMany({
            data: normalizedRecommendations.map((rec) => ({
              workerId: worker.id,
              jobId: rec.jobId,
              score: rec.score,
              reasons: JSON.stringify(rec.reasons),
            })),
          });
        }
      });
    } catch (error) {
      this.logger.warn('AI Service không phản hồi/timeout. Chuyển sang dữ liệu dự phòng:', error);
    }

    // 7. Lấy danh sách đã lưu từ Database
    const savedRecommendations = await this.prisma.jobRecommendation.findMany({
      where: {
        workerId: worker.id,
        job: {
          status: 'PUBLISHED',
          OR: [{ deadline: null }, { deadline: { gt: new Date() } }],
        },
      },
      include: {
        job: {
          include: {
            category: true,
            employer: { include: { user: true } },
            jobSkills: { include: { skill: true } },
            _count: { select: { applications: true } },
          },
        },
      },
      orderBy: { score: 'desc' },
    });

    if (savedRecommendations.length > 0) {
      return savedRecommendations.map((item) => {
        const job = item.job;
        const isUrgent = job.urgent && (job.urgentUntil === null || job.urgentUntil > new Date());

        return {
          ...item,
          score: Number(item.score),
          reasons: item.reasons ? this.parseReasons(item.reasons) : [],
          job: {
            ...job,
            salary: job.salary === null ? null : Number(job.salary),
            latitude: job.latitude === null ? null : Number(job.latitude),
            longitude: job.longitude === null ? null : Number(job.longitude),
            isUrgent,
          },
        };
      });
    }

    // 8. FALLBACK DỰ PHÒNG: Trả về 10 việc làm mới nhất
    const fallbackJobs = await this.prisma.job.findMany({
      where: {
        status: 'PUBLISHED',
        OR: [{ deadline: null }, { deadline: { gt: new Date() } }],
      },
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: {
        category: true,
        employer: { include: { user: true } },
        jobSkills: { include: { skill: true } },
        _count: { select: { applications: true } },
      },
    });

    return fallbackJobs.map((job) => ({
      id: `fallback-${job.id}`,
      workerId: worker.id,
      jobId: job.id,
      score: 60,
      reasons: ['Công việc mới nhất dành cho bạn (Hệ thống dự phòng)'],
      createdAt: new Date(),
      updatedAt: new Date(),
      job: {
        ...job,
        salary: job.salary === null ? null : Number(job.salary),
        latitude: job.latitude === null ? null : Number(job.latitude),
        longitude: job.longitude === null ? null : Number(job.longitude),
        isUrgent: job.urgent && (job.urgentUntil === null || job.urgentUntil > new Date()),
      },
    }));
  }

  private formatTime(value: Date) {
    const hours = value.getUTCHours().toString().padStart(2, '0');
    const minutes = value.getUTCMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private parseReasons(reasons: string): string[] {
    try {
      const parsed = JSON.parse(reasons);
      if (!Array.isArray(parsed)) return [];
      return parsed.map((reason) => String(reason).trim()).filter((reason) => reason.length > 0);
    } catch {
      const value = reasons.trim();
      return value.length > 0 ? [value] : [];
    }
  }
}