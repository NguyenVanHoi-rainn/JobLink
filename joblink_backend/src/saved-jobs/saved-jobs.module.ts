import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { SavedJobsController } from './saved-jobs.controller.js';
import { SavedJobsService } from './saved-jobs.service.js';

@Module({
  imports: [
    AuthModule,
  ],

  controllers: [
    SavedJobsController,
  ],

  providers: [
    SavedJobsService,
  ],

  exports: [
    SavedJobsService,
  ],
})
export class SavedJobsModule {}