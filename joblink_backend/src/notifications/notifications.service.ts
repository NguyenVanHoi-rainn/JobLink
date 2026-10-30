import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';
import { FirebaseAdminService } from './firebase-admin.service.js';
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
    private readonly prisma:
      PrismaService,

    private readonly firebaseAdmin:
      FirebaseAdminService,
  ) {}

  async create(
    data: CreateNotificationData,
  ) {
    const notification =
      await this.prisma.notification.create({
        data: {
          userId:
            data.userId,

          title:
            data.title,

          content:
            data.content,

          type:
            data.type,

          referenceType:
            data.referenceType ?? null,

          referenceId:
            data.referenceId ?? null,
        },
      });

    void this.sendPushNotification(
      notification,
    );

    return notification;
  }

  private async sendPushNotification(
    notification: {
      id: string;
      userId: string;
      title: string;
      content: string;
      type: string;
      referenceType:
        string | null;
      referenceId:
        string | null;
    },
  ) {
    try {
      const tokenRecords =
        await this.prisma.pushToken.findMany({
          where: {
            userId:
              notification.userId,
          },

          select: {
            token:
              true,
          },
        });

      if (
        tokenRecords.length === 0
      ) {
        return;
      }

      const result =
        await this.firebaseAdmin.sendToTokens(
          tokenRecords.map(
            (item) =>
              item.token,
          ),
          {
            title:
              notification.title,

            body:
              notification.content,

            data: {
              notificationId:
                notification.id,

              type:
                notification.type,

              referenceType:
                notification.referenceType ??
                '',

              referenceId:
                notification.referenceId ??
                '',
            },
          },
        );

      if (
        result.invalidTokens.length >
        0
      ) {
        await this.prisma.pushToken.deleteMany({
          where: {
            token: {
              in:
                result.invalidTokens,
            },
          },
        });
      }
    } catch (error) {
      console.error(
        'Push notification failed:',
        error,
      );
    }
  }

  async registerDeviceToken(
    userId: string,
    token: string,
    platform = 'android',
  ) {
    const savedToken =
      await this.prisma.pushToken.upsert({
        where: {
          token,
        },

        update: {
          userId,
          platform,
        },

        create: {
          userId,
          token,
          platform,
        },
      });

    return {
      success: true,
      id:
        savedToken.id,
    };
  }

  async removeDeviceToken(
    userId: string,
    token: string,
  ) {
    const result =
      await this.prisma.pushToken.deleteMany({
        where: {
          userId,
          token,
        },
      });

    return {
      success: true,
      removedCount:
        result.count,
    };
  }

  async getMyNotifications(
    userId: string,
    query: NotificationQueryDto,
  ) {
    const page =
      query.page ?? 1;

    const limit =
      query.limit ?? 20;

    const skip =
      (page - 1) * limit;

    const where = {
      userId,

      ...(query.isRead !==
        undefined && {
        isRead:
          query.isRead ===
          'true',
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
            createdAt:
              'desc',
          },

          skip,
          take:
            limit,
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
          isRead:
            false,
        },
      });

    return {
      unreadCount:
        count,
    };
  }

  async getNotificationById(
    userId: string,
    notificationId: string,
  ) {
    const notification =
      await this.prisma.notification.findUnique({
        where: {
          id:
            notificationId,
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
        id:
          notificationId,
      },

      data: {
        isRead:
          true,
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
          isRead:
            false,
        },

        data: {
          isRead:
            true,
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
