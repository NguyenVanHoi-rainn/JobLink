import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { NotificationQueryDto } from './dto/notification-query.dto.js';

interface CreateNotificationData {
  userId: string;
  title: string;
  content: string;
  type: string;

  referenceType?: string;
  referenceId?: string;
}

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async create(
    data: CreateNotificationData,
  ) {
    return this.prisma.notification.create({
      data: {
        userId: data.userId,

        title: data.title,

        content: data.content,

        type: data.type,

        referenceType:
          data.referenceType ?? null,

        referenceId:
          data.referenceId ?? null,
      },
    });
  }

  async getMyNotifications(
    userId: string,
    query: NotificationQueryDto,
  ) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const skip =
      (page - 1) * limit;

    const where = {
      userId,

      ...(query.isRead !== undefined && {
        isRead:
          query.isRead === 'true',
      }),

      ...(query.type && {
        type:
          query.type,
      }),
    };

    const [
      items,
      total,
    ] =
      await this.prisma.$transaction([
        this.prisma.notification.findMany({
          where,

          orderBy: {
            createdAt: 'desc',
          },

          skip,
          take: limit,
        }),

        this.prisma.notification.count({
          where,
        }),
      ]);

    return {
      items,

      pagination: {
        page,
        limit,
        total,

        totalPages:
          Math.ceil(
            total / limit,
          ),
      },
    };
  }

  async getUnreadCount(
    userId: string,
  ) {
    const count =
      await this.prisma.notification.count({
        where: {
          userId,
          isRead: false,
        },
      });

    return {
      unreadCount: count,
    };
  }

  async getNotificationById(
    userId: string,
    notificationId: string,
  ) {
    const notification =
      await this.prisma.notification.findUnique({
        where: {
          id: notificationId,
        },
      });

    if (!notification) {
      throw new NotFoundException(
        'Không tìm thấy thông báo',
      );
    }

    if (
      notification.userId !==
      userId
    ) {
      throw new ForbiddenException(
        'Bạn không có quyền xem thông báo này',
      );
    }

    return notification;
  }

  async markAsRead(
    userId: string,
    notificationId: string,
  ) {
    await this.getNotificationById(
      userId,
      notificationId,
    );

    return this.prisma.notification.update({
      where: {
        id: notificationId,
      },

      data: {
        isRead: true,
      },
    });
  }

  async markAllAsRead(
    userId: string,
  ) {
    const result =
      await this.prisma.notification.updateMany({
        where: {
          userId,
          isRead: false,
        },

        data: {
          isRead: true,
        },
      });

    return {
      message:
        'Đã đánh dấu tất cả thông báo là đã đọc',

      updatedCount:
        result.count,
    };
  }
}