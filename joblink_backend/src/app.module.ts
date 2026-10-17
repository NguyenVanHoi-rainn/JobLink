import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { WorkersModule } from './workers/workers.module.js';
import { EmployersModule } from './employers/employers.module.js';
import { AdminModule } from './admin/admin.module.js';
import { JobsModule } from './jobs/jobs.module.js';
import { ApplicationsModule } from './applications/applications.module.js';
import { ChatModule } from './chat/chat.module.js';
import { AppointmentsModule } from './appointments/appointments.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { SavedJobsModule } from './saved-jobs/saved-jobs.module.js';
import { ReportsModule } from './reports/reports.module.js';
import { JobRecommendationsModule } from './job-recommendations/job-recommendations.module.js';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    ApplicationsModule,
    JobsModule,
    WorkersModule,
    EmployersModule,
    AdminModule,
    ReportsModule,
    ChatModule,
    AppointmentsModule,
    NotificationsModule,
    SavedJobsModule,
    JobRecommendationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}