import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';

import { NotificationsService } from './notifications.service.js';

import { NotificationQueryDto } from './dto/notification-query.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('notifications')
@UseGuards(
  JwtAuthGuard,
)
export class NotificationsController {
  constructor(
    private readonly notificationsService:
      NotificationsService,
  ) {}

  @Get()
  getMyNotifications(
    @CurrentUser()
    user: any,

    @Query()
    query: NotificationQueryDto,
  ) {
    return this.notificationsService.getMyNotifications(
      user.sub,
      query,
    );
  }

  @Get('unread-count')
  getUnreadCount(
    @CurrentUser()
    user: any,
  ) {
    return this.notificationsService.getUnreadCount(
      user.sub,
    );
  }

  // Đặt read-all trước :id
  // để tránh conflict route.
  @Patch('read-all')
  markAllAsRead(
    @CurrentUser()
    user: any,
  ) {
    return this.notificationsService.markAllAsRead(
      user.sub,
    );
  }

  @Get(':id')
  getNotificationById(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.notificationsService.getNotificationById(
      user.sub,
      id,
    );
  }

  @Patch(':id/read')
  markAsRead(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.notificationsService.markAsRead(
      user.sub,
      id,
    );
  }
}