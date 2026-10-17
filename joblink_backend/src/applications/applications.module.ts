import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { ApplicationsController } from './applications.controller.js';
import { EmployerApplicationsController } from './employer-applications.controller.js';
import { ApplicationsService } from './applications.service.js';
import { AiModule } from '../ai/ai.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [
    AuthModule,
    AiModule,
    NotificationsModule,
  ],

  controllers: [
    ApplicationsController,
    EmployerApplicationsController,
  ],

  providers: [
    ApplicationsService,
  ],

  exports: [
    ApplicationsService,
  ],
})
export class ApplicationsModule {}