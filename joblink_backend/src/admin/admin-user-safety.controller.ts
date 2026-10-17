import {
  Controller,
  Param,
  ParseUUIDPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';

import { AdminUserSafetyService } from './admin-user-safety.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@Controller('admin/users')
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
@Roles('ADMIN')
export class AdminUserSafetyController {
  constructor(
    private readonly adminUserSafetyService:
      AdminUserSafetyService,
  ) {}

  @Patch(':id/lock')
  lockUser(
    @CurrentUser()
    admin: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.adminUserSafetyService.lockUser(
      admin.sub,
      id,
    );
  }

  @Patch(':id/unlock')
  unlockUser(
    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.adminUserSafetyService.unlockUser(
      id,
    );
  }
}