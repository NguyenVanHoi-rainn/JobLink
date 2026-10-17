import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminUserSafetyService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async lockUser(
    adminUserId: string,
    targetUserId: string,
  ) {
    if (adminUserId === targetUserId) {
      throw new BadRequestException(
        'Admin không thể tự khóa tài khoản của mình',
      );
    }

    const user =
      await this.prisma.user.findUnique({
        where: {
          id: targetUserId,
        },
      });

    if (!user) {
      throw new NotFoundException(
        'Không tìm thấy người dùng',
      );
    }

    if (user.role === 'ADMIN') {
      throw new ForbiddenException(
        'Không thể khóa tài khoản Admin',
      );
    }

    if (user.status === 'LOCKED') {
      throw new BadRequestException(
        'Tài khoản đã bị khóa',
      );
    }

    return this.prisma.user.update({
      where: {
        id: targetUserId,
      },

      data: {
        status: 'LOCKED',
      },

      select: {
        id: true,
        email: true,
        role: true,
        status: true,
      },
    });
  }

  async unlockUser(
    targetUserId: string,
  ) {
    const user =
      await this.prisma.user.findUnique({
        where: {
          id: targetUserId,
        },
      });

    if (!user) {
      throw new NotFoundException(
        'Không tìm thấy người dùng',
      );
    }

    if (user.role === 'ADMIN') {
      throw new ForbiddenException(
        'Không áp dụng thao tác này cho Admin',
      );
    }

    if (user.status === 'ACTIVE') {
      throw new BadRequestException(
        'Tài khoản đang hoạt động',
      );
    }

    return this.prisma.user.update({
      where: {
        id: targetUserId,
      },

      data: {
        status: 'ACTIVE',
      },

      select: {
        id: true,
        email: true,
        role: true,
        status: true,
      },
    });
  }
}