import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto.js';
import { SubmitVerificationDto } from './dto/submit-verification.dto.js';

@Injectable()
export class EmployersService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async getMyProfile(userId: string) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          userId,
        },

        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              status: true,
              createdAt: true,
            },
          },
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
      );
    }

    return employer;
  }

  async updateMyProfile(
    userId: string,
    dto: UpdateEmployerProfileDto,
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

    return this.prisma.employerProfile.update({
      where: {
        id: employer.id,
      },

      data: {
        ...(dto.companyName !== undefined && {
          companyName: dto.companyName,
        }),

        ...(dto.description !== undefined && {
          description: dto.description,
        }),

        ...(dto.address !== undefined && {
          address: dto.address,
        }),

        ...(dto.logoUrl !== undefined && {
          logoUrl: dto.logoUrl,
        }),
      },
    });
  }

  async getVerification(userId: string) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          userId,
        },

        select: {
          id: true,
          companyName: true,
          taxCode: true,
          businessLicense: true,
          verificationStatus: true,
          rejectionReason: true,
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
      );
    }

    return employer;
  }

    async submitVerification(
    userId: string,
    dto: SubmitVerificationDto,
    businessLicense: string,
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

    if (
        employer.verificationStatus === 'PENDING'
    ) {
        throw new BadRequestException(
        'Yêu cầu xác minh đang chờ Admin xử lý',
        );
    }

    if (
        employer.verificationStatus === 'VERIFIED'
    ) {
        throw new BadRequestException(
        'Employer đã được xác minh',
        );
    }

    if (
        !employer.companyName ||
        !employer.address
    ) {
        throw new BadRequestException(
        'Vui lòng hoàn thiện tên doanh nghiệp và địa chỉ trước khi gửi xác minh',
        );
    }

    return this.prisma.employerProfile.update({
        where: {
        id: employer.id,
        },

        data: {
        taxCode: dto.taxCode,
        businessLicense,

        verificationStatus: 'PENDING',
        rejectionReason: null,
        },

        select: {
        id: true,
        companyName: true,
        taxCode: true,
        businessLicense: true,
        verificationStatus: true,
        rejectionReason: true,
        },
    });
    }

    async getVerificationFile(
    userId: string,
    ) {
    const employer =
        await this.prisma.employerProfile.findUnique({
        where: {
            userId,
        },

        select: {
            businessLicense: true,
        },
        });

    if (!employer) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
        );
    }

    if (!employer.businessLicense) {
        throw new NotFoundException(
        'Employer chưa có giấy phép kinh doanh',
        );
    }

    return employer.businessLicense;
    }
}