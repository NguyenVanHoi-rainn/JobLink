import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';

import { JwtService } from '@nestjs/jwt';

import {
  Server,
  Socket,
} from 'socket.io';

import { ChatService } from './chat.service.js';
import { SendMessageDto } from './dto/send-message.dto.js';

@WebSocketGateway({
  namespace: '/chat',

  cors: {
    origin: '*',
  },
})
export class ChatGateway
  implements OnGatewayConnection
{
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService:
      JwtService,

    private readonly chatService:
      ChatService,
  ) {}

  async handleConnection(
    client: Socket,
  ) {
    try {
      let token =
        client.handshake.auth?.token;

      if (!token) {
        const authorization =
          client.handshake.headers
            .authorization;

        if (
          authorization?.startsWith(
            'Bearer ',
          )
        ) {
          token =
            authorization.substring(7);
        }
      }

      if (!token) {
        client.disconnect();
        return;
      }

      const payload =
        await this.jwtService.verifyAsync(
          token,
        );

      client.data.user = payload;

      const conversationIds =
        await this.chatService
          .getConversationIdsForUser(
            payload.sub,
          );

      for (
        const conversationId
        of conversationIds
      ) {
        await client.join(
          `conversation:${conversationId}`,
        );
      }
    } catch {
      client.disconnect();
    }
  }

  @SubscribeMessage(
    'joinConversation',
  )
  async joinConversation(
    @ConnectedSocket()
    client: Socket,

    @MessageBody()
    data: {
      conversationId: string;
    },
  ) {
    const user =
      client.data.user;

    await this.chatService.assertMember(
      user.sub,
      data.conversationId,
    );

    await client.join(
      `conversation:${data.conversationId}`,
    );

    return {
      success: true,
      conversationId:
        data.conversationId,
    };
  }

  @SubscribeMessage(
    'sendMessage',
  )
  async sendMessage(
    @ConnectedSocket()
    client: Socket,

    @MessageBody()
    data: SendMessageDto & {
      conversationId: string;
    },
  ) {
    const user =
      client.data.user;

    const message =
      await this.chatService.sendMessage(
        user.sub,
        data.conversationId,
        data,
      );

    this.server
      .to(
        `conversation:${data.conversationId}`,
      )
      .emit(
        'newMessage',
        message,
      );

    return message;
  }
}