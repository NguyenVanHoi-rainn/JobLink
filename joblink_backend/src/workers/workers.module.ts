import { Module } from '@nestjs/common';

import { WorkersController } from './workers.controller.js';
import { WorkersService } from './workers.service.js';

import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [
    AuthModule,
  ],
  controllers: [
    WorkersController,
  ],
  providers: [
    WorkersService,
  ],
  exports: [
    WorkersService,
  ],
})
export class WorkersModule {}