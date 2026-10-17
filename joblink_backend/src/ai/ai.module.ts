import { Module } from '@nestjs/common';

import { CandidateMatchingService } from './candidate-matching.service.js';

@Module({
  providers: [
    CandidateMatchingService,
  ],

  exports: [
    CandidateMatchingService,
  ],
})
export class AiModule {}