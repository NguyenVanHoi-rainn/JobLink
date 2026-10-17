import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';

import { EmployersService } from './employers.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto.js';
import { SubmitVerificationDto } from './dto/submit-verification.dto.js';
import { FileInterceptor } from '@nestjs/platform-express';

import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { unlink } from 'fs/promises';

import type { Response } from 'express';

@Controller('employers')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('EMPLOYER')
export class EmployersController {
  constructor(
    private readonly employersService: EmployersService,
  ) {}

  @Get('me')
  getMyProfile(
    @CurrentUser()
    user: any,
  ) {
    return this.employersService.getMyProfile(
      user.sub,
    );
  }

  @Patch('me')
  updateMyProfile(
    @CurrentUser()
    user: any,

    @Body()
    dto: UpdateEmployerProfileDto,
  ) {
    return this.employersService.updateMyProfile(
      user.sub,
      dto,
    );
  }

  @Get('me/verification')
  getVerification(
    @CurrentUser()
    user: any,
  ) {
    return this.employersService.getVerification(
      user.sub,
    );
  }

    @Post('me/verification')
    @UseInterceptors(
    FileInterceptor('businessLicense', {
        storage: diskStorage({
        destination:
            './uploads/business-licenses',

        filename: (
            req,
            file,
            callback,
        ) => {
            const uniqueName =
            `${Date.now()}-${Math.round(
                Math.random() * 1e9,
            )}`;

            const extension =
            extname(file.originalname);

            callback(
            null,
            `${uniqueName}${extension}`,
            );
        },
        }),

        limits: {
        fileSize: 5 * 1024 * 1024,
        },

        fileFilter: (
        req,
        file,
        callback,
        ) => {
        const allowedTypes = [
            'application/pdf',
            'image/jpeg',
            'image/png',
        ];

        if (
            !allowedTypes.includes(
            file.mimetype,
            )
        ) {
            return callback(
            new BadRequestException(
                'Giấy phép kinh doanh chỉ chấp nhận PDF, JPG hoặc PNG',
            ),
            false,
            );
        }

        callback(null, true);
        },
    }),
    )
    async submitVerification(
    @CurrentUser()
    user: any,

    @Body()
    dto: SubmitVerificationDto,

    @UploadedFile()
    file: Express.Multer.File,
    ) {
    if (!file) {
        throw new BadRequestException(
        'Vui lòng tải lên giấy phép kinh doanh',
        );
    }

    const filePath =
        `uploads/business-licenses/${file.filename}`;

    try {
        return await this.employersService.submitVerification(
        user.sub,
        dto,
        filePath,
        );
    } catch (error) {

        try {
        await unlink(
            join(
            process.cwd(),
            filePath,
            ),
        );
        } catch {}

        throw error;
    }
    }

    @Get('me/verification/file')
    async getVerificationFile(
    @CurrentUser()
    user: any,

    @Res()
    res: Response,
    ) {
    const fileUrl =
        await this.employersService.getVerificationFile(
        user.sub,
        );

    const filePath = join(
        process.cwd(),
        fileUrl,
    );

    return res.sendFile(filePath);
    }

}