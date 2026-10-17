import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { ChatService } from './chat.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

import { CreateSelectedGroupDto } from './dto/create-selected-group.dto.js';
import { AddSelectedGroupMembersDto } from './dto/add-selected-group-members.dto.js';

@Controller()
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
export class GroupChatController {
  constructor(
    private readonly chatService:
      ChatService,
  ) {}

  // Worker hoặc Employer đều có thể xem
  // Applicant Group nếu họ là member.
  @Get('jobs/:jobId/applicant-group')
  getApplicantGroup(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.chatService.getApplicantGroup(
      user.sub,
      jobId,
    );
  }

  // Từ đây trở xuống chỉ Employer.
  @Get('employers/me/jobs/:jobId/groups')
  @Roles('EMPLOYER')
  getJobGroups(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,
  ) {
    return this.chatService.getJobGroups(
      user.sub,
      jobId,
    );
  }

  @Post(
    'employers/me/jobs/:jobId/selected-groups',
  )
  @Roles('EMPLOYER')
  createSelectedGroup(
    @CurrentUser()
    user: any,

    @Param(
      'jobId',
      ParseUUIDPipe,
    )
    jobId: string,

    @Body()
    dto: CreateSelectedGroupDto,
  ) {
    return this.chatService.createSelectedGroup(
      user.sub,
      jobId,
      dto,
    );
  }

  @Post(
    'employers/me/selected-groups/:groupId/members',
  )
  @Roles('EMPLOYER')
  addMembers(
    @CurrentUser()
    user: any,

    @Param(
      'groupId',
      ParseUUIDPipe,
    )
    groupId: string,

    @Body()
    dto: AddSelectedGroupMembersDto,
  ) {
    return this.chatService.addSelectedGroupMembers(
      user.sub,
      groupId,
      dto,
    );
  }

  @Delete(
    'employers/me/selected-groups/:groupId/members/:userId',
  )
  @Roles('EMPLOYER')
  removeMember(
    @CurrentUser()
    user: any,

    @Param(
      'groupId',
      ParseUUIDPipe,
    )
    groupId: string,

    @Param(
      'userId',
      ParseUUIDPipe,
    )
    memberUserId: string,
  ) {
    return this.chatService.removeSelectedGroupMember(
      user.sub,
      groupId,
      memberUserId,
    );
  }
}