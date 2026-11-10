import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreateWorkAppointmentDto } from './dto/create-work-appointment.dto.js';
import { UpdateWorkAppointmentDto } from './dto/update-work-appointment.dto.js';
import { ConfirmWorkAppointmentDto } from './dto/confirm-work-appointment.dto.js';
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
    const formattedDate = new Intl.DateTimeFormat('vi-VN', {
      dateStyle: 'medium',
      timeStyle: 'short',
      timeZone: 'Asia/Ho_Chi_Minh',
    }).format(appointmentDate);
    const formattedShift = this.formatRecurringShift(
      application.job,
    );

    await this.safeNotify({
        userId:
        worker.userId,

        title:
        'Bạn có lịch nhận việc mới',

        content:
        `Lịch nhận việc "${application.job.title}" lúc ${formattedDate} tại ${dto.location.trim()}.${formattedShift ? ` Ca định kỳ: ${formattedShift}.` : ''}`,

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
    dto: ConfirmWorkAppointmentDto = {},
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

    const conflictingSchedules =
      await this.findScheduleConflicts(
        worker.id,
        appointment.application.job,
        appointmentId,
      );

    if (
      conflictingSchedules.length > 0 &&
      !dto.ignoreScheduleConflict
    ) {
      throw new ConflictException({
        message:
          'Lịch làm việc này trùng với ca bạn đã xác nhận.',
        code: 'WORK_SCHEDULE_CONFLICT',
        conflicts: conflictingSchedules,
      });
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

  private async findScheduleConflicts(
    workerId: string,
    targetJob: {
      id: string;
      title: string;
      workDays: string[];
      startTime: Date | null;
      endTime: Date | null;
    },
    appointmentId: string,
  ) {
    const targetShifts = this.expandWeeklyShift(targetJob);
    if (targetShifts.length === 0) {
      return [];
    }

    const existingAppointments =
      await this.prisma.workAppointment.findMany({
        where: {
          id: { not: appointmentId },
          status: 'CONFIRMED',
          application: {
            workerId,
            status: 'ACCEPTED',
          },
        },
        select: {
          id: true,
          application: {
            select: {
              job: {
                select: {
                  id: true,
                  title: true,
                  workDays: true,
                  startTime: true,
                  endTime: true,
                  employer: {
                    select: {
                      companyName: true,
                    },
                  },
                },
              },
            },
          },
        },
      });

    const conflicts = new Map<string, {
      appointmentId: string;
      jobTitle: string;
      companyName: string;
      day: string;
      startTime: string;
      endTime: string;
    }>();

    for (const existing of existingAppointments) {
      const job = existing.application.job;
      const existingShifts = this.expandWeeklyShift(job);

      for (const target of targetShifts) {
        for (const current of existingShifts) {
          if (
            target.day === current.day &&
            target.start < current.end &&
            current.start < target.end
          ) {
            conflicts.set(
              `${existing.id}:${target.day}`,
              {
                appointmentId: existing.id,
                jobTitle: job.title,
                companyName: job.employer.companyName,
                day: target.day,
                startTime: this.formatMinutes(current.start),
                endTime: this.formatMinutes(current.end),
              },
            );
          }
        }
      }
    }

    return [...conflicts.values()];
  }

  private expandWeeklyShift(job: {
    workDays: string[];
    startTime: Date | null;
    endTime: Date | null;
  }) {
    if (
      !job.startTime ||
      !job.endTime ||
      job.workDays.length === 0
    ) {
      return [];
    }

    const start = this.minutesOfDay(job.startTime);
    const end = this.minutesOfDay(job.endTime);

    if (start === end) {
      return [];
    }

    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];

    return job.workDays.flatMap((day) => {
      const dayIndex = days.indexOf(day);
      if (dayIndex < 0) {
        return [];
      }

      if (end > start) {
        return [{ day, start, end }];
      }

      const nextDay = days[(dayIndex + 1) % days.length];
      return [
        { day, start, end: 1440 },
        { day: nextDay, start: 0, end },
      ];
    });
  }

  private minutesOfDay(value: Date) {
    return value.getUTCHours() * 60 + value.getUTCMinutes();
  }

  private formatMinutes(minutes: number) {
    const normalized = minutes % 1440;
    const hours = Math.floor(normalized / 60);
    const mins = normalized % 60;
    return `${hours.toString().padStart(2, '0')}:${mins
      .toString()
      .padStart(2, '0')}`;
  }

  private formatRecurringShift(job: {
    workDays: string[];
    startTime: Date | null;
    endTime: Date | null;
  }) {
    if (!job.startTime || !job.endTime || job.workDays.length === 0) {
      return '';
    }

    const dayLabels: Record<string, string> = {
      MONDAY: 'Thứ 2',
      TUESDAY: 'Thứ 3',
      WEDNESDAY: 'Thứ 4',
      THURSDAY: 'Thứ 5',
      FRIDAY: 'Thứ 6',
      SATURDAY: 'Thứ 7',
      SUNDAY: 'Chủ nhật',
    };
    const days = job.workDays
      .map((day) => dayLabels[day])
      .filter((day): day is string => Boolean(day))
      .join(', ');

    if (!days) {
      return '';
    }

    return `${days}, ${this.formatMinutes(this.minutesOfDay(job.startTime))} - ${this.formatMinutes(this.minutesOfDay(job.endTime))}`;
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