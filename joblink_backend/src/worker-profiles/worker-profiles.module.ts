import {
  Module,
} from '@nestjs/common';

import {
  AuthModule,
} from '../auth/auth.module.js';

import {
  WorkerProfilesController,
} from './worker-profiles.controller.js';

import {
  WorkerProfilesService,
} from './worker-profiles.service.js';

@Module({
  imports: [
    AuthModule,
  ],

  controllers: [
    WorkerProfilesController,
  ],

  providers: [
    WorkerProfilesService,
  ],

  exports: [
    WorkerProfilesService,
  ],
})
export class WorkerProfilesModule {}