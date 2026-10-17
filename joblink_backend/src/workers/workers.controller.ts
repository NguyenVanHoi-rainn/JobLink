import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  UseGuards,
  UploadedFile,
  UseInterceptors,
  Res,
  ParseUUIDPipe,
} from '@nestjs/common';

import { WorkersService } from './workers.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

import { UpdateWorkerProfileDto } from './dto/update-worker-profile.dto.js';
import { UpdateSkillsDto } from './dto/update-skills.dto.js';
import { CreateWorkExperienceDto } from './dto/create-work-experience.dto.js';
import { CreateAvailabilityDto } from './dto/create-availability.dto.js';
import { UpdateCategoriesDto } from './dto/update-categories.dto.js';
import { CreateCvDto } from './dto/create-cv.dto.js';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import type { Response } from 'express';
import { join } from 'path'
import { UpdateWorkExperienceDto } from './dto/update-work-experience.dto.js';

@Controller('workers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('WORKER')
export class WorkersController {
  constructor(
    private readonly workersService: WorkersService,
  ) {}

  @Get('me')
  getMyProfile(
    @CurrentUser() user: any,
  ) {
    return this.workersService.getMyProfile(user.sub);
  }

  @Patch('me')
  updateMyProfile(
    @CurrentUser() user: any,
    @Body() dto: UpdateWorkerProfileDto,
  ) {
    return this.workersService.updateMyProfile(
      user.sub,
      dto,
    );
  }

  @Put('me/skills')
    updateSkills(
    @CurrentUser() user: any,
    @Body() dto: UpdateSkillsDto,
    ) {
    return this.workersService.updateSkills(
        user.sub,
        dto.skillIds,
    );
  }
  @Get('me/experiences')
    getWorkExperiences(
    @CurrentUser() user: any,
    ) {
    return this.workersService.getWorkExperiences(
        user.sub,
    );
    }

    @Post('me/experiences')
    createWorkExperience(
    @CurrentUser() user: any,
    @Body() dto: CreateWorkExperienceDto,
    ) {
    return this.workersService.createWorkExperience(
        user.sub,
        dto,
    );
    }

    @Get('me/availability')
    getAvailabilities(
    @CurrentUser() user: any,
    ) {
    return this.workersService.getAvailabilities(
        user.sub,
    );
    }

    @Post('me/availability')
    createAvailability(
    @CurrentUser() user: any,
    @Body() dto: CreateAvailabilityDto,
    ) {
    return this.workersService.createAvailability(
        user.sub,
        dto,
    );
    }

    @Put('me/categories')
    updateCategories(
    @CurrentUser() user: any,
    @Body() dto: UpdateCategoriesDto,
    ) {
    return this.workersService.updateCategories(
        user.sub,
        dto,
    );
    }

    @Get('me/cvs')
    getCvs(
      @CurrentUser() user: any,
    ) {
      return this.workersService.getCvs(
        user.sub,
      );
    }

    @Post('me/cvs')
    @UseInterceptors(
      FileInterceptor('file', {
        storage: diskStorage({
          destination: './uploads/cvs',

          filename: (
            req,
            file,
            callback,
          ) => {
            const uniqueName =
              `${Date.now()}-${Math.round(Math.random() * 1e9)}`;

            const extension = extname(
              file.originalname,
            );

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
          if (
            file.mimetype !==
            'application/pdf'
          ) {
            return callback(
              new Error(
                'Chỉ cho phép upload file PDF',
              ),
              false,
            );
          }

          callback(null, true);
        },
      }),
    )
    async uploadCv(
      @CurrentUser() user: any,
      @UploadedFile()
      file: Express.Multer.File,
    ) {
      const uploaded = {
        fileName: file.originalname,

        fileUrl:
          `uploads/cvs/${file.filename}`,
      };

      return this.workersService.createCv(
        user.sub,
        uploaded,
      );
    }

    @Delete('me/cvs/:id')
    deleteCv(
      @CurrentUser() user: any,

      @Param('id', ParseUUIDPipe)
      id: string,
    ) {
      return this.workersService.deleteCv(
        user.sub,
        id,
      );
    }

    @Get('me/cvs/:id/file')
    async getCvFile(
      @CurrentUser() user: any,

      @Param('id', ParseUUIDPipe)
      id: string,

      @Res()
      res: Response,
    ) {
      const cv =
        await this.workersService.getCvById(
          user.sub,
          id,
        );

      const filePath = join(
        process.cwd(),
        cv.fileUrl,
      );

      return res.sendFile(filePath);
    }

    @Patch('me/experiences/:id')
    updateWorkExperience(
      @CurrentUser() user: any,

      @Param('id', ParseUUIDPipe)
      id: string,

      @Body()
      dto: UpdateWorkExperienceDto,
    ) {
      return this.workersService.updateWorkExperience(
        user.sub,
        id,
        dto,
      );
    }

    @Delete('me/experiences/:id')
    deleteWorkExperience(
      @CurrentUser() user: any,

      @Param('id', ParseUUIDPipe)
      id: string,
    ) {
      return this.workersService.deleteWorkExperience(
        user.sub,
        id,
      );
    }

    @Delete('me/availability/:id')
    deleteAvailability(
      @CurrentUser() user: any,

      @Param('id', ParseUUIDPipe)
      id: string,
    ) {
      return this.workersService.deleteAvailability(
        user.sub,
        id,
      );
    }

}