import {
  BadRequestException,
  Injectable,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { ApplyJobDto } from './dto/apply-job.dto.js';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';
import { CandidateMatchingService } from '../ai/candidate-matching.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';

@Injectable()
export class ApplicationsService {
constructor(
  private readonly prisma: PrismaService,
  private readonly candidateMatchingService: CandidateMatchingService,
  private readonly notificationsService: NotificationsService,
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

  private async validateCv(
    workerId: string,
    cvId?: string,
  ) {
    if (!cvId) {
      return null;
    }

    const cv =
      await this.prisma.cV.findFirst({
        where: {
          id: cvId,
          workerId,
        },
      });

    if (!cv) {
      throw new NotFoundException(
        'CV không tồn tại hoặc không thuộc Worker hiện tại',
      );
    }

    return cv;
  }

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

  private async safeNotify(data: {
    userId: string;
    title: string;
    content: string;
    type: string;
    referenceType?: string;
    referenceId?: string;
  }) {
    try {
      await this.notificationsService.create(data);
    } catch (error) {
      console.error(
        'Notification failed:',
        error,
      );
    }
  }  

  async applyJob(
    userId: string,
    jobId: string,
    dto: ApplyJobDto,
  ) {
    const worker =
      await this.getWorker(userId);

    const job =
      await this.prisma.job.findFirst({
        where: {
          id: jobId,
          status: 'PUBLISHED',
        },

        include: {
          employer: true,
        },
      });

    if (!job) {
      throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng đang mở',
      );
    }

    if (
      job.deadline &&
      job.deadline <= new Date()
    ) {
      throw new BadRequestException(
        'Tin tuyển dụng đã hết hạn ứng tuyển',
      );
    }

    if (
      job.cvRequired &&
      !dto.cvId
    ) {
      throw new BadRequestException(
        'Tin tuyển dụng này yêu cầu CV',
      );
    }

    await this.validateCv(
      worker.id,
      dto.cvId,
    );

    const existing =
      await this.prisma.application.findFirst({
        where: {
          jobId,
          workerId: worker.id,
        },
      });

    if (
      existing &&
      existing.status !== 'WITHDRAWN'
    ) {
      throw new BadRequestException(
        'Bạn đã ứng tuyển công việc này',
      );
    }

  const createdApplication =
    await this.prisma.$transaction(
      async (tx) => {
        let application;

        // Nếu trước đó đã rút đơn thì dùng lại record,
        // vì DB có unique(jobId, workerId).
        if (
          existing &&
          existing.status === 'WITHDRAWN'
        ) {
          application =
            await tx.application.update({
              where: {
                id: existing.id,
              },

              data: {
                cvId:
                  dto.cvId ?? null,

                note:
                  dto.note ?? null,

                status: 'APPLIED',

                appliedAt:
                  new Date(),
              },
            });
        } else {
          application =
            await tx.application.create({
              data: {
                jobId,

                workerId:
                  worker.id,

                cvId:
                  dto.cvId ?? null,

                note:
                  dto.note ?? null,

                status: 'APPLIED',
              },
            });
        }

        // Tìm Applicant Group của Job.
        let applicantGroup =
          await tx.conversation.findFirst({
            where: {
              jobId,
              type: 'APPLICANT_GROUP',
            },
          });

        // Job chưa có Applicant Group thì tạo.
        if (!applicantGroup) {
          applicantGroup =
            await tx.conversation.create({
              data: {
                jobId,

                createdBy:
                  job.employer.userId,

                type:
                  'APPLICANT_GROUP',

                name:
                  `Ứng viên - ${job.title}`,
              },
            });

          // Employer là OWNER của group.
          await tx.conversationMember.create({
            data: {
              conversationId:
                applicantGroup.id,

              userId:
                job.employer.userId,

              memberRole: 'OWNER',
            },
          });
        }

        // Thêm Worker vào Applicant Group.
        await tx.conversationMember.createMany({
          data: [
            {
              conversationId:
                applicantGroup.id,

              userId,

              memberRole: 'MEMBER',
            },
          ],

          skipDuplicates: true,
        });

        return tx.application.findUnique({
          where: {
            id: application.id,
          },

          include: {
            cv: true,

            job: {
              include: {
                category: true,

                employer: {
                  select: {
                    id: true,
                    companyName: true,
                    logoUrl: true,
                    address: true,
                  },
                },
              },
            },
          },
        });
      },
    );

    if (!createdApplication) {
      throw new InternalServerErrorException(
        'Không thể tạo đơn ứng tuyển',
      );
    }

    try {
      await this.candidateMatchingService
        .calculateForApplication(
          createdApplication.id,
        );
    } catch (error) {
      console.error(
        'Candidate Matching failed:',
        error,
      );
    }

    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id: job.employerId,
        },

        select: {
          userId: true,
        },
      });

    if (employer) {
      await this.safeNotify({
        userId:
          employer.userId,

        title:
          'Có ứng viên mới',

        content:
          `Có Worker vừa ứng tuyển vào "${job.title}".`,

        type:
          'APPLICATION_CREATED',

        referenceType:
          'APPLICATION',

        referenceId:
          createdApplication.id,
      });
    }

    return createdApplication;
  }

  async getMyApplications(
    userId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    return this.prisma.application.findMany({
      where: {
        workerId:
          worker.id,
      },

      include: {
        cv: true,

        job: {
          include: {
            category: true,

            employer: {
              select: {
                id: true,
                companyName: true,
                logoUrl: true,
                address: true,
              },
            },
          },
        },
      },

      orderBy: {
        appliedAt: 'desc',
      },
    });
  }

  async getMyApplicationById(
    userId: string,
    applicationId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    const application =
      await this.prisma.application.findFirst({
        where: {
          id: applicationId,
          workerId: worker.id,
        },

        include: {
          cv: true,

          job: {
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
          },
        },
      });

    if (!application) {
      throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
      );
    }

    return application;
  }

  async withdrawApplication(
    userId: string,
    applicationId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    const application =
      await this.prisma.application.findFirst({
        where: {
          id: applicationId,
          workerId: worker.id,
        },

        include: {
          job: true,
        },
      });

    if (!application) {
      throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
      );
    }

    if (
      application.status !== 'APPLIED' &&
      application.status !== 'REVIEWING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể rút đơn khi đang APPLIED hoặc REVIEWING',
      );
    }

    const updated =
      await this.prisma.$transaction(
        async (tx) => {
          const updatedApplication =
            await tx.application.update({
              where: {
                id: applicationId,
              },

              data: {
                status: 'WITHDRAWN',
              },
            });

          // Worker rút đơn thì rời Applicant Group.
          const applicantGroup =
            await tx.conversation.findFirst({
              where: {
                jobId:
                  application.jobId,

                type:
                  'APPLICANT_GROUP',
              },
            });

          if (applicantGroup) {
            await tx.conversationMember.deleteMany({
              where: {
                conversationId:
                  applicantGroup.id,

                userId,
              },
            });
          }

          return updatedApplication;
        },
      );

    // Tìm tài khoản Employer sở hữu Job.
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id:
            application.job.employerId,
        },

        select: {
          userId: true,
        },
      });

    // Gửi notification cho Employer.
    if (employer) {
      await this.safeNotify({
        userId:
          employer.userId,

        title:
          'Ứng viên đã rút hồ sơ',

        content:
          `Một Worker đã rút ứng tuyển khỏi "${application.job.title}".`,

        type:
          'APPLICATION_WITHDRAWN',

        referenceType:
          'APPLICATION',

        referenceId:
          application.id,
      });
    }

    return updated;
  }

    async getJobApplications(
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

    return this.prisma.application.findMany({
        where: {
        jobId,
        },

        include: {
        cv: true,

        candidateMatch: true,

        worker: {
            include: {
            user: {
                select: {
                id: true,
                email: true,
                status: true,
                },
            },

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
            },
        },
        },

        orderBy: {
        appliedAt: 'desc',
        },
    });
    }

    async getApplicationForEmployer(
    userId: string,
    applicationId: string,
    ) {
    const employer =
        await this.getEmployer(userId);

    const application =
        await this.prisma.application.findFirst({
        where: {
            id: applicationId,

            job: {
            employerId: employer.id,
            },
        },

        include: {
            cv: true,

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
                user: {
                select: {
                    id: true,
                    email: true,
                    status: true,
                },
                },

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
                availabilities: true,
            },
            },
        },
        });

    if (!application) {
        throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
        );
    }

    return application;
    }

    async getApplicationCv(
    userId: string,
    applicationId: string,
    ) {
    const employer =
        await this.getEmployer(userId);

    const application =
        await this.prisma.application.findFirst({
        where: {
            id: applicationId,

            job: {
            employerId: employer.id,
            },
        },

        include: {
            cv: true,
        },
        });

    if (!application) {
        throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
        );
    }

    if (!application.cv) {
        throw new NotFoundException(
        'Ứng viên không gửi CV',
        );
    }

    if (
        !application.cv.fileUrl.startsWith(
        'uploads/cvs/',
        )
    ) {
        throw new BadRequestException(
        'CV hiện tại không phải file được lưu trên hệ thống',
        );
    }

    return application.cv;
    }

    async updateApplicationStatus(
    userId: string,
    applicationId: string,
    dto: UpdateApplicationStatusDto,
    ) {
    const employer =
        await this.getEmployer(userId);

    const application =
      await this.prisma.application.findUnique({
        where: {
          id: applicationId,
        },

        include: {
          job: true,
        },
      });

    if (!application) {
        throw new NotFoundException(
        'Không tìm thấy đơn ứng tuyển',
        );
    }

    if (
        application.status === 'WITHDRAWN'
    ) {
        throw new BadRequestException(
        'Ứng viên đã rút đơn',
        );
    }

    if (
        application.status === 'ACCEPTED' ||
        application.status === 'REJECTED'
    ) {
        throw new BadRequestException(
        'Đơn ứng tuyển đã có kết quả cuối cùng',
        );
    }

    if (
        dto.status === 'REVIEWING' &&
        application.status !== 'APPLIED'
    ) {
        throw new BadRequestException(
        'Chỉ đơn APPLIED mới chuyển sang REVIEWING',
        );
    }

    if (
        (dto.status === 'ACCEPTED' ||
        dto.status === 'REJECTED') &&
        application.status !== 'REVIEWING'
    ) {
        throw new BadRequestException(
        'Phải chuyển đơn sang REVIEWING trước khi đưa ra kết quả',
        );
    }

    const updated =
      await this.prisma.application.update({
        where: {
          id: applicationId,
        },

        data: {
          status: dto.status,
        },
      });

    const worker =
      await this.prisma.workerProfile.findUnique({
        where: {
          id: application.workerId,
        },

        select: {
          userId: true,
        },
      });

    const statusMessages: Record<
      string,
      {
        title: string;
        content: string;
      }
    > = {
      REVIEWING: {
        title:
          'Hồ sơ đang được xem xét',

        content:
          `Nhà tuyển dụng đang xem xét hồ sơ của bạn cho "${application.job.title}".`,
      },

      ACCEPTED: {
        title:
          'Bạn đã được chấp nhận',

        content:
          `Bạn đã được chấp nhận cho công việc "${application.job.title}".`,
      },

      REJECTED: {
        title:
          'Kết quả ứng tuyển',

        content:
          `Ứng tuyển của bạn cho "${application.job.title}" chưa được chấp nhận.`,
      },
    };

    const notification =
      statusMessages[dto.status];

    if (
      worker &&
      notification
    ) {
      await this.safeNotify({
        userId:
          worker.userId,

        title:
          notification.title,

        content:
          notification.content,

        type:
          `APPLICATION_${dto.status}`,

        referenceType:
          'APPLICATION',

        referenceId:
          application.id,
      });
    }

    return updated;

    }

    async getCandidateMatch(
      userId: string,
      applicationId: string,
    ) {
      const employer =
        await this.getEmployer(userId);

      const application =
        await this.prisma.application.findFirst({
          where: {
            id: applicationId,

            job: {
              employerId:
                employer.id,
            },
          },

          include: {
            candidateMatch: true,
          },
        });

      if (!application) {
        throw new NotFoundException(
          'Không tìm thấy đơn ứng tuyển',
        );
      }

      if (!application.candidateMatch) {
        throw new NotFoundException(
          'Chưa có kết quả AI Matching cho ứng viên này',
        );
      }

      let reasons: string[] = [];

      try {
        reasons = application.candidateMatch.reasons
          ? JSON.parse(
              application.candidateMatch.reasons,
            )
          : [];
      } catch {
        reasons = application.candidateMatch.reasons
          ? [application.candidateMatch.reasons]
          : [];
      }

      return {
        ...application.candidateMatch,
        reasons,
      };
    }

}