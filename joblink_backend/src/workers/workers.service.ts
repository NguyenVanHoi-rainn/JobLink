import {
    BadRequestException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';
import { UpdateWorkerProfileDto } from './dto/update-worker-profile.dto.js';
import { CreateWorkExperienceDto } from './dto/create-work-experience.dto.js';
import { CreateAvailabilityDto } from './dto/create-availability.dto.js';
import { UpdateCategoriesDto } from './dto/update-categories.dto.js';
import { CreateCvDto } from './dto/create-cv.dto.js';
import { unlink } from 'fs/promises';
import { join } from 'path';
import { UpdateWorkExperienceDto } from './dto/update-work-experience.dto.js';

@Injectable()
export class WorkersService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  async getMyProfile(userId: string) {
    const profile = await this.prisma.workerProfile.findUnique({
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
        cvs: true,
      },
    });

    if (!profile) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    return profile;
  }

  async updateMyProfile(
    userId: string,
    dto: UpdateWorkerProfileDto,
  ) {
    const profile = await this.prisma.workerProfile.findUnique({
      where: {
        userId,
      },
    });

    if (!profile) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
      );
    }

    return this.prisma.workerProfile.update({
      where: {
        userId,
      },
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        bio: dto.bio,
        searchArea: dto.searchArea,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    });
  }

  async updateSkills(
    userId: string,
    skillIds: string[],
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: {
        userId,
        },
    });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const skills = await this.prisma.skill.findMany({
        where: {
        id: {
            in: skillIds,
        },
        status: true,
        },
    });

    if (skills.length !== skillIds.length) {
        throw new NotFoundException(
        'Có kỹ năng không tồn tại hoặc đã bị vô hiệu hóa',
        );
    }

    await this.prisma.$transaction([
        this.prisma.workerSkill.deleteMany({
        where: {
            workerId: worker.id,
        },
        }),

        this.prisma.workerSkill.createMany({
        data: skillIds.map((skillId) => ({
            workerId: worker.id,
            skillId,
        })),
        }),
    ]);

    return this.prisma.workerProfile.findUnique({
        where: {
        id: worker.id,
        },
        include: {
        workerSkills: {
            include: {
            skill: true,
            },
        },
        },
    });
    }

    async getWorkExperiences(userId: string) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    return this.prisma.workExperience.findMany({
        where: {
        workerId: worker.id,
        },
        orderBy: {
        startDate: 'desc',
        },
    });
    }

    async createWorkExperience(
    userId: string,
    dto: CreateWorkExperienceDto,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    return this.prisma.workExperience.create({
        data: {
        workerId: worker.id,
        companyName: dto.companyName,
        position: dto.position,
        description: dto.description,
        startDate: new Date(dto.startDate),
        endDate: dto.endDate
            ? new Date(dto.endDate)
            : null,
        isCurrent: dto.isCurrent ?? false,
        },
    });
    }
    async getAvailabilities(userId: string) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    return this.prisma.workerAvailability.findMany({
        where: {
        workerId: worker.id,
        },
        orderBy: {
        dayOfWeek: 'asc',
        },
    });
    }

    async createAvailability(
    userId: string,
    dto: CreateAvailabilityDto,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    const startTime = new Date(`1970-01-01T${dto.startTime}:00.000Z`);
    const endTime = new Date(`1970-01-01T${dto.endTime}:00.000Z`);

    if (startTime >= endTime) {
        throw new BadRequestException(
        'Giờ bắt đầu phải nhỏ hơn giờ kết thúc',
        );
    }

    return this.prisma.workerAvailability.create({
        data: {
        workerId: worker.id,
        dayOfWeek: dto.dayOfWeek,
        startTime,
        endTime,
        },
    });
    }

    async updateCategories(
    userId: string,
    dto: UpdateCategoriesDto,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException('Không tìm thấy hồ sơ Worker');
    }

    const categories = await this.prisma.category.findMany({
        where: {
        id: {
            in: dto.categoryIds,
        },
        status: true,
        },
    });

    if (categories.length !== dto.categoryIds.length) {
        throw new NotFoundException(
        'Có ngành nghề không tồn tại hoặc đã bị vô hiệu hóa',
        );
    }

    await this.prisma.$transaction([
        this.prisma.workerCategory.deleteMany({
        where: {
            workerId: worker.id,
        },
        }),

        this.prisma.workerCategory.createMany({
        data: dto.categoryIds.map((categoryId) => ({
            workerId: worker.id,
            categoryId,
        })),
        }),
    ]);

    return this.prisma.workerProfile.findUnique({
        where: {
        id: worker.id,
        },
        include: {
        workerCategories: {
            include: {
            category: true,
            },
        },
        },
    });
    }

    async getCvs(userId: string) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    return this.prisma.cV.findMany({
        where: {
        workerId: worker.id,
        },
        orderBy: {
        uploadedAt: 'desc',
        },
    });
    }

    async createCv(
    userId: string,
    dto: CreateCvDto,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    return this.prisma.cV.create({
        data: {
        workerId: worker.id,
        fileName: dto.fileName,
        fileUrl: dto.fileUrl,
        },
    });
    }

    async deleteCv(
    userId: string,
    cvId: string,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const cv = await this.prisma.cV.findFirst({
        where: {
        id: cvId,
        workerId: worker.id,
        },
    });

    if (!cv) {
        throw new NotFoundException(
        'Không tìm thấy CV',
        );
    }

    await this.prisma.cV.delete({
        where: {
        id: cvId,
        },
    });

    if (cv.fileUrl.startsWith('uploads/cvs/')) {
        const filePath = join(
        process.cwd(),
        cv.fileUrl,
        );

        try {
        await unlink(filePath);
        } catch (error: any) {
        if (error?.code !== 'ENOENT') {
            console.error(
            'Không thể xóa file CV:',
            error,
            );
        }
        }
    }

    return {
        message: 'Xóa CV thành công',
    };
    }

    async getCvById(
    userId: string,
    cvId: string,
    ) {
    const worker = await this.prisma.workerProfile.findUnique({
        where: { userId },
    });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const cv = await this.prisma.cV.findFirst({
        where: {
        id: cvId,
        workerId: worker.id,
        },
    });

    if (!cv) {
        throw new NotFoundException(
        'Không tìm thấy CV',
        );
    }

    return cv;
    }

    async updateWorkExperience(
    userId: string,
    experienceId: string,
    dto: UpdateWorkExperienceDto,
    ) {
    const worker =
        await this.prisma.workerProfile.findUnique({
        where: { userId },
        });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const experience =
        await this.prisma.workExperience.findFirst({
        where: {
            id: experienceId,
            workerId: worker.id,
        },
        });

    if (!experience) {
        throw new NotFoundException(
        'Không tìm thấy kinh nghiệm làm việc',
        );
    }

    const startDate = dto.startDate
        ? new Date(dto.startDate)
        : experience.startDate;

    let endDate =
        dto.endDate !== undefined
        ? dto.endDate === null
            ? null
            : new Date(dto.endDate)
        : experience.endDate;

    if (dto.isCurrent === true) {
        endDate = null;
    }

    if (
        endDate &&
        startDate.getTime() > endDate.getTime()
    ) {
        throw new BadRequestException(
        'Ngày bắt đầu không được sau ngày kết thúc',
        );
    }

    return this.prisma.workExperience.update({
        where: {
        id: experienceId,
        },

        data: {
        ...(dto.companyName !== undefined && {
            companyName: dto.companyName,
        }),

        ...(dto.position !== undefined && {
            position: dto.position,
        }),

        ...(dto.description !== undefined && {
            description: dto.description,
        }),

        ...(dto.startDate !== undefined && {
            startDate,
        }),

        ...(dto.endDate !== undefined && {
            endDate,
        }),

        ...(dto.isCurrent !== undefined && {
            isCurrent: dto.isCurrent,
        }),

        ...(dto.isCurrent === true && {
            endDate: null,
        }),
        },
    });
    }

    async deleteWorkExperience(
    userId: string,
    experienceId: string,
    ) {
    const worker =
        await this.prisma.workerProfile.findUnique({
        where: { userId },
        });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const experience =
        await this.prisma.workExperience.findFirst({
        where: {
            id: experienceId,
            workerId: worker.id,
        },
        });

    if (!experience) {
        throw new NotFoundException(
        'Không tìm thấy kinh nghiệm làm việc',
        );
    }

    await this.prisma.workExperience.delete({
        where: {
        id: experienceId,
        },
    });

    return {
        message: 'Xóa kinh nghiệm làm việc thành công',
    };
    }

    async deleteAvailability(
    userId: string,
    availabilityId: string,
    ) {
    const worker =
        await this.prisma.workerProfile.findUnique({
        where: { userId },
        });

    if (!worker) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker',
        );
    }

    const availability =
        await this.prisma.workerAvailability.findFirst({
        where: {
            id: availabilityId,
            workerId: worker.id,
        },
        });

    if (!availability) {
        throw new NotFoundException(
        'Không tìm thấy thời gian rảnh',
        );
    }

    await this.prisma.workerAvailability.delete({
        where: {
        id: availabilityId,
        },
    });

    return {
        message: 'Xóa thời gian rảnh thành công',
    };
    }

    
}