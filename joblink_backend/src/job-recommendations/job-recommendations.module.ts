import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { JobRecommendationsController } from './job-recommendations.controller.js';
import { JobRecommendationsService } from './job-recommendations.service.js';

@Module({
  imports: [
    AuthModule,
  ],

  controllers: [
    JobRecommendationsController,
  ],

  providers: [
    JobRecommendationsService,
  ],

  exports: [
    JobRecommendationsService,
  ],
})
export class JobRecommendationsModule {}