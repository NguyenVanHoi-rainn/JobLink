import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
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
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  /**
   * Một user có thể mở nhiều socket cùng lúc
   * (ví dụ app reconnect hoặc nhiều thiết bị).
   * Chỉ báo offline khi socket cuối cùng của user đóng.
   */
  private readonly onlineSocketsByUser =
    new Map<string, Set<string>>();

  constructor(
    private readonly jwtService:
      JwtService,

    private readonly chatService:
      ChatService,
  ) {}

  // ============================
  // CONNECTION / PRESENCE
  // ============================

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
        await this.jwtService
          .verifyAsync(token);

      client.data.user = payload;

      const conversationIds =
        await this.chatService
          .getConversationIdsForUser(
            payload.sub,
          );

      client.data.conversationIds =
        conversationIds;

      for (
        const conversationId
        of conversationIds
      ) {
        await client.join(
          `conversation:${conversationId}`,
        );
      }

      const becameOnline =
        this.addOnlineSocket(
          payload.sub,
          client.id,
        );

      if (becameOnline) {
        this.emitPresenceToConversations(
          conversationIds,
          payload.sub,
          true,
        );
      }
    } catch {
      client.disconnect();
    }
  }

  async handleDisconnect(
    client: Socket,
  ) {
    const userId =
      client.data.user?.sub as
        | string
        | undefined;

    if (!userId) {
      return;
    }

    const conversationIds =
      Array.isArray(
        client.data.conversationIds,
      )
        ? (client.data
            .conversationIds as string[])
        : await this.chatService
            .getConversationIdsForUser(
              userId,
            )
            .catch(() => []);

    // Nếu mất kết nối khi đang gõ,
    // phía còn lại phải tắt "đang nhập...".
    for (
      const conversationId
      of conversationIds
    ) {
      this.server
        .to(
          `conversation:${conversationId}`,
        )
        .emit(
          'typing',
          {
            conversationId,
            userId,
            isTyping: false,
          },
        );
    }

    const becameOffline =
      this.removeOnlineSocket(
        userId,
        client.id,
      );

    if (becameOffline) {
      this.emitPresenceToConversations(
        conversationIds,
        userId,
        false,
      );
    }
  }

  // ============================
  // JOIN CONVERSATION
  // ============================

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

    await this.chatService
      .assertMember(
        user.sub,
        data.conversationId,
      );

    await client.join(
      `conversation:${data.conversationId}`,
    );

    await this.emitPresenceSnapshot(
      client,
      data.conversationId,
    );

    return {
      success: true,
      conversationId:
        data.conversationId,
    };
  }

  // ============================
  // TYPING
  // ============================

  @SubscribeMessage('typing')
  async typing(
    @ConnectedSocket()
    client: Socket,

    @MessageBody()
    data: {
      conversationId: string;
      isTyping: boolean;
    },
  ) {
    const user =
      client.data.user;

    await this.chatService
      .assertMember(
        user.sub,
        data.conversationId,
      );

    // Gửi cho người khác trong room,
    // không gửi ngược lại chính socket đang gõ.
    client
      .to(
        `conversation:${data.conversationId}`,
      )
      .emit(
        'typing',
        {
          conversationId:
            data.conversationId,
          userId:
            user.sub,
          isTyping:
            data.isTyping === true,
        },
      );

    return {
      success: true,
    };
  }

  // ============================
  // SEND MESSAGE
  // ============================

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
      await this.chatService
        .sendMessage(
          user.sub,
          data.conversationId,
          data,
        );

    this.emitNewMessage(
      data.conversationId,
      message,
    );

    return message;
  }

  // ============================
  // PUBLIC HELPERS
  // ============================

  emitNewMessage(
    conversationId: string,
    message: unknown,
  ) {
    this.server
      .to(
        `conversation:${conversationId}`,
      )
      .emit(
        'newMessage',
        message,
      );
  }

  emitConversationRead(
    conversationId: string,
    userId: string,
    lastReadAt: Date,
  ) {
    this.server
      .to(
        `conversation:${conversationId}`,
      )
      .emit(
        'conversationRead',
        {
          conversationId,
          userId,
          lastReadAt:
            lastReadAt.toISOString(),
        },
      );
  }

  // ============================
  // PRESENCE HELPERS
  // ============================

  private addOnlineSocket(
    userId: string,
    socketId: string,
  ) {
    let sockets =
      this.onlineSocketsByUser
        .get(userId);

    const wasOffline =
      !sockets ||
      sockets.size === 0;

    if (!sockets) {
      sockets = new Set<string>();
      this.onlineSocketsByUser.set(
        userId,
        sockets,
      );
    }

    sockets.add(socketId);

    return wasOffline;
  }

  private removeOnlineSocket(
    userId: string,
    socketId: string,
  ) {
    const sockets =
      this.onlineSocketsByUser
        .get(userId);

    if (!sockets) {
      return false;
    }

    sockets.delete(socketId);

    if (sockets.size > 0) {
      return false;
    }

    this.onlineSocketsByUser
      .delete(userId);

    return true;
  }

  private emitPresenceToConversations(
    conversationIds: string[],
    userId: string,
    isOnline: boolean,
  ) {
    for (
      const conversationId
      of conversationIds
    ) {
      this.server
        .to(
          `conversation:${conversationId}`,
        )
        .emit(
          'presence',
          {
            conversationId,
            userId,
            isOnline,
          },
        );
    }
  }

  private async emitPresenceSnapshot(
    client: Socket,
    conversationId: string,
  ) {
    const room =
      `conversation:${conversationId}`;

    const sockets =
      await this.server
        .in(room)
        .fetchSockets();

    const onlineUserIds =
      [
        ...new Set(
          sockets
            .map(
              (socket) =>
                socket.data.user?.sub as
                  | string
                  | undefined,
            )
            .filter(
              (
                userId,
              ): userId is string =>
                Boolean(userId),
            ),
        ),
      ];

    client.emit(
      'presenceSnapshot',
      {
        conversationId,
        onlineUserIds,
      },
    );
  }
}
