import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { ReportsController } from './reports.controller.js';
import { AdminReportsController } from './admin-reports.controller.js';

import { ReportsService } from './reports.service.js';

@Module({
  imports: [
    AuthModule,
  ],

  controllers: [
    ReportsController,
    AdminReportsController,
  ],

  providers: [
    ReportsService,
  ],

  exports: [
    ReportsService,
  ],
})
export class ReportsModule {}