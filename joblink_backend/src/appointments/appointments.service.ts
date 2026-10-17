import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreateWorkAppointmentDto } from './dto/create-work-appointment.dto.js';
import { UpdateWorkAppointmentDto } from './dto/update-work-appointment.dto.js';
import { NotificationsService } from '../notifications/notifications.service.js';

@Injectable()
export class AppointmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

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

  async createAppointment(
    employerUserId: string,
    applicationId: string,
    dto: CreateWorkAppointmentDto,
  ) {
    const employer =
      await this.getEmployer(
        employerUserId,
      );

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
      application.job.employerId !==
      employer.id
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền tạo lịch cho đơn ứng tuyển này',
      );
    }

    if (
      application.status !==
      'ACCEPTED'
    ) {
      throw new BadRequestException(
        'Chỉ có thể tạo lịch cho ứng viên đã được ACCEPTED',
      );
    }

    const existing =
    await this.prisma.workAppointment.findUnique({
        where: {
        applicationId,
        },
    });

    if (
    existing &&
    (
        existing.status === 'PENDING' ||
        existing.status === 'CONFIRMED'
    )
    ) {
    throw new BadRequestException(
        'Đơn ứng tuyển này đang có lịch nhận việc',
    );
    }

    const appointmentDate =
      new Date(dto.appointmentDate);

    if (
      appointmentDate.getTime() <=
      Date.now()
    ) {
      throw new BadRequestException(
        'Thời gian nhận việc phải ở tương lai',
      );
    }

    let createdAppointment;

    if (
    existing &&
    (
        existing.status === 'CANCELLED' ||
        existing.status === 'DECLINED'
    )
    ) {
    createdAppointment =
        await this.prisma.workAppointment.update({
        where: {
            id: existing.id,
        },

        data: {
            appointmentDate,

            location:
            dto.location.trim(),

            instruction:
            dto.instruction?.trim() ||
            null,

            status:
            'PENDING',
        },
        });
    } else {
    createdAppointment =
        await this.prisma.workAppointment.create({
        data: {
            applicationId,

            appointmentDate,

            location:
            dto.location.trim(),

            instruction:
            dto.instruction?.trim() ||
            null,

            status:
            'PENDING',
        },
        });
    }

    const worker =
    await this.prisma.workerProfile.findUnique({
        where: {
        id: application.workerId,
        },

        select: {
        userId: true,
        },
    });

    if (worker) {
    await this.safeNotify({
        userId:
        worker.userId,

        title:
        'Bạn có lịch nhận việc mới',

        content:
        `Nhà tuyển dụng đã tạo lịch nhận việc cho "${application.job.title}".`,

        type:
        'APPOINTMENT_CREATED',

        referenceType:
        'WORK_APPOINTMENT',

        referenceId:
        createdAppointment.id,
    });
    }

    return createdAppointment;
    }

  async getEmployerAppointments(
    userId: string,
  ) {
    const employer =
      await this.getEmployer(userId);

    return this.prisma.workAppointment.findMany({
      where: {
        application: {
          job: {
            employerId:
              employer.id,
          },
        },
      },

      include: {
        application: {
          include: {
            job: {
              include: {
                category: true,
              },
            },

            worker: {
              include: {
                user: true,
              },
            },
          },
        },
      },

      orderBy: {
        appointmentDate: 'asc',
      },
    });
  }

  async getWorkerAppointments(
    userId: string,
  ) {
    const worker =
      await this.getWorker(userId);

    return this.prisma.workAppointment.findMany({
      where: {
        application: {
          workerId:
            worker.id,
        },
      },

      include: {
        application: {
          include: {
            job: {
              include: {
                category: true,
                employer: {
                  include: {
                    user: true,
                  },
                },
              },
            },
          },
        },
      },

      orderBy: {
        appointmentDate: 'asc',
      },
    });
  }

  async updateAppointment(
    employerUserId: string,
    appointmentId: string,
    dto: UpdateWorkAppointmentDto,
  ) {
    const employer =
      await this.getEmployer(
        employerUserId,
      );

    const appointment =
      await this.prisma.workAppointment.findUnique({
        where: {
          id: appointmentId,
        },

        include: {
          application: {
            include: {
              job: true,
            },
          },
        },
      });

    if (!appointment) {
      throw new NotFoundException(
        'Không tìm thấy lịch nhận việc',
      );
    }

    if (
      appointment.application.job.employerId !==
      employer.id
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền chỉnh sửa lịch này',
      );
    }

    if (
      appointment.status !==
      'PENDING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể chỉnh sửa lịch đang PENDING',
      );
    }

    if (dto.appointmentDate) {
      const newDate =
        new Date(
          dto.appointmentDate,
        );

      if (
        newDate.getTime() <=
        Date.now()
      ) {
        throw new BadRequestException(
          'Thời gian nhận việc phải ở tương lai',
        );
      }
    }

    return this.prisma.workAppointment.update({
      where: {
        id: appointmentId,
      },

      data: {
        ...(dto.appointmentDate !==
          undefined && {
          appointmentDate:
            new Date(
              dto.appointmentDate,
            ),
        }),

        ...(dto.location !==
          undefined && {
          location:
            dto.location.trim(),
        }),

        ...(dto.instruction !==
          undefined && {
          instruction:
            dto.instruction.trim() ||
            null,
        }),
      },
    });
  }

  async confirmAppointment(
    workerUserId: string,
    appointmentId: string,
  ) {
    const worker =
      await this.getWorker(
        workerUserId,
      );

    const appointment =
      await this.prisma.workAppointment.findUnique({
        where: {
          id: appointmentId,
        },

        include: {
        application: {
            include: {
            job: true,
            },
        },
        },
      });

    if (!appointment) {
      throw new NotFoundException(
        'Không tìm thấy lịch nhận việc',
      );
    }

    if (
      appointment.application.workerId !==
      worker.id
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền xác nhận lịch này',
      );
    }

    if (
      appointment.status !==
      'PENDING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể xác nhận lịch đang PENDING',
      );
    }

    const updated =
    await this.prisma.workAppointment.update({
        where: {
        id: appointmentId,
        },

        data: {
        status:
            'CONFIRMED',
        },
    });

    const employer =
    await this.prisma.employerProfile.findUnique({
        where: {
        id:
            appointment.application.job.employerId,
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
        'Worker đã xác nhận lịch',

        content:
        `Worker đã xác nhận lịch nhận việc cho "${appointment.application.job.title}".`,

        type:
        'APPOINTMENT_CONFIRMED',

        referenceType:
        'WORK_APPOINTMENT',

        referenceId:
        appointmentId,
    });
    }

    return updated;

  }

  async declineAppointment(
    workerUserId: string,
    appointmentId: string,
  ) {
    const worker =
      await this.getWorker(
        workerUserId,
      );

    const appointment =
      await this.prisma.workAppointment.findUnique({
        where: {
          id: appointmentId,
        },

        include: {
        application: {
            include: {
            job: true,
            },
        },
        },
      });

    if (!appointment) {
      throw new NotFoundException(
        'Không tìm thấy lịch nhận việc',
      );
    }

    if (
      appointment.application.workerId !==
      worker.id
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền từ chối lịch này',
      );
    }

    if (
      appointment.status !==
      'PENDING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể từ chối lịch đang PENDING',
      );
    }

    const updated =
    await this.prisma.workAppointment.update({
        where: {
        id: appointmentId,
        },

        data: {
        status:
            'DECLINED',
        },
    });

    const employer =
    await this.prisma.employerProfile.findUnique({
        where: {
        id:
            appointment.application.job.employerId,
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
        'Worker đã từ chối lịch',

        content:
        `Worker đã từ chối lịch nhận việc cho "${appointment.application.job.title}".`,

        type:
        'APPOINTMENT_DECLINED',

        referenceType:
        'WORK_APPOINTMENT',

        referenceId:
        appointmentId,
    });
    }

    return updated;

  }

  async cancelAppointment(
    employerUserId: string,
    appointmentId: string,
  ) {
    const employer =
      await this.getEmployer(
        employerUserId,
      );

    const appointment =
      await this.prisma.workAppointment.findUnique({
        where: {
          id: appointmentId,
        },

        include: {
          application: {
            include: {
              job: true,
            },
          },
        },
      });

    if (!appointment) {
      throw new NotFoundException(
        'Không tìm thấy lịch nhận việc',
      );
    }

    if (
      appointment.application.job.employerId !==
      employer.id
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền hủy lịch này',
      );
    }

    if (
      appointment.status ===
        'CANCELLED' ||
      appointment.status ===
        'DECLINED'
    ) {
      throw new BadRequestException(
        'Lịch này không thể hủy',
      );
    }

    const updated =
    await this.prisma.workAppointment.update({
        where: {
        id: appointmentId,
        },

        data: {
        status:
            'CANCELLED',
        },
    });

    const worker =
    await this.prisma.workerProfile.findUnique({
        where: {
        id:
            appointment.application.workerId,
        },

        select: {
        userId: true,
        },
    });

    if (worker) {
    await this.safeNotify({
        userId:
        worker.userId,

        title:
        'Lịch nhận việc đã bị hủy',

        content:
        `Nhà tuyển dụng đã hủy lịch nhận việc cho "${appointment.application.job.title}".`,

        type:
        'APPOINTMENT_CANCELLED',

        referenceType:
        'WORK_APPOINTMENT',

        referenceId:
        appointmentId,
    });
    }

    return updated;

  }
}