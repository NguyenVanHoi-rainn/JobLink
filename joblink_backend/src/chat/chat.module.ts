import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';

import { ChatController } from './chat.controller.js';
import { ChatGateway } from './chat.gateway.js';
import { ChatService } from './chat.service.js';
import { GroupChatController } from './group-chat.controller.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [
    AuthModule,
    NotificationsModule,
  ],

  controllers: [
    ChatController,
    GroupChatController,
  ],

  providers: [
    ChatService,
    ChatGateway,
  ],

  exports: [
    ChatService,
  ],
})
export class ChatModule {}