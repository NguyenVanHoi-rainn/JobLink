import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { AdminController } from './admin.controller.js';
import { AdminService } from './admin.service.js';
import { AdminUserSafetyController } from './admin-user-safety.controller.js';
import { AdminUserSafetyService } from './admin-user-safety.service.js';
import { AdminDashboardController } from './admin-dashboard.controller.js';
import { AdminDashboardService } from './admin-dashboard.service.js';

@Module({
  imports: [
    AuthModule,
  ],

  controllers: [
    AdminController,
    AdminDashboardController,
    AdminUserSafetyController,
  ],

  providers: [
    AdminService,
    AdminDashboardService,
    AdminUserSafetyService,
  ],

  exports: [
    AdminService,
  ],
})
export class AdminModule {}