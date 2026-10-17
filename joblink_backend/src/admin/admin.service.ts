import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';
import { RejectEmployerDto } from './dto/reject-employer.dto.js';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async getPendingEmployerVerifications() {
    return this.prisma.employerProfile.findMany({
      where: {
        verificationStatus: 'PENDING',
      },

      select: {
        id: true,
        companyName: true,
        description: true,
        address: true,
        logoUrl: true,

        taxCode: true,
        businessLicense: true,

        verificationStatus: true,
        rejectionReason: true,

        user: {
          select: {
            id: true,
            email: true,
            status: true,
            createdAt: true,
          },
        },
      },

      orderBy: {
        id: 'desc',
      },
    });
  }

  async getEmployerVerification(
    employerId: string,
  ) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id: employerId,
        },

        select: {
          id: true,
          companyName: true,
          description: true,
          address: true,
          logoUrl: true,

          taxCode: true,
          businessLicense: true,

          verificationStatus: true,
          rejectionReason: true,

          user: {
            select: {
              id: true,
              email: true,
              status: true,
              createdAt: true,
            },
          },
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy Employer',
      );
    }

    return employer;
  }

  async getEmployerVerificationFile(
    employerId: string,
  ) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id: employerId,
        },

        select: {
          businessLicense: true,
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy Employer',
      );
    }

    if (!employer.businessLicense) {
      throw new NotFoundException(
        'Employer chưa có giấy phép kinh doanh',
      );
    }

    if (
      !employer.businessLicense.startsWith(
        'uploads/business-licenses/',
      )
    ) {
      throw new NotFoundException(
        'Không tìm thấy file giấy phép trên hệ thống',
      );
    }

    return employer.businessLicense;
  }

  async approveEmployer(
    employerId: string,
  ) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id: employerId,
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy Employer',
      );
    }

    if (
      employer.verificationStatus !== 'PENDING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể duyệt yêu cầu đang ở trạng thái PENDING',
      );
    }

    return this.prisma.employerProfile.update({
      where: {
        id: employerId,
      },

      data: {
        verificationStatus: 'VERIFIED',
        rejectionReason: null,
      },

      select: {
        id: true,
        companyName: true,
        taxCode: true,
        verificationStatus: true,
        rejectionReason: true,
      },
    });
  }

  async rejectEmployer(
    employerId: string,
    dto: RejectEmployerDto,
  ) {
    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          id: employerId,
        },
      });

    if (!employer) {
      throw new NotFoundException(
        'Không tìm thấy Employer',
      );
    }

    if (
      employer.verificationStatus !== 'PENDING'
    ) {
      throw new BadRequestException(
        'Chỉ có thể từ chối yêu cầu đang ở trạng thái PENDING',
      );
    }

    return this.prisma.employerProfile.update({
      where: {
        id: employerId,
      },

      data: {
        verificationStatus: 'REJECTED',
        rejectionReason: dto.reason,
      },

      select: {
        id: true,
        companyName: true,
        taxCode: true,
        verificationStatus: true,
        rejectionReason: true,
      },
    });
  }
}