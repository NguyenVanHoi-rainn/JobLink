import {
  Injectable,
  Logger,
} from '@nestjs/common';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import {
  getMessaging,
} from 'firebase-admin/messaging';

interface PushPayload {
  title: string;
  body: string;
  data?: Record<
    string,
    string
  >;
}

@Injectable()
export class FirebaseAdminService {
  private readonly logger =
    new Logger(
      FirebaseAdminService.name,
    );

  constructor() {
    if (getApps().length === 0) {
      initializeApp({
        credential:
          applicationDefault(),
      });
    }
  }

  async sendToTokens(
    tokens: string[],
    payload: PushPayload,
  ) {
    const uniqueTokens = [
      ...new Set(
        tokens.filter(
          (token) =>
            token.trim().length > 0,
        ),
      ),
    ];

    if (
      uniqueTokens.length === 0
    ) {
      return {
        invalidTokens:
          [] as string[],
      };
    }

    try {
      const response =
        await getMessaging()
          .sendEachForMulticast({
            fids: uniqueTokens,
  
            notification: {
              title:
                payload.title,
              body:
                payload.body,
            },

            data:
              payload.data,

            android: {
              priority:
                'high',
            },
          });

      const invalidTokens:
          string[] = [];

      response.responses
          .forEach(
        (
          item,
          index,
         ) => {
          if (item.success) {
            return;
          }

          const code =
              item.error?.code;

          if (
            code ===
                'messaging/registration-token-not-registered' ||
            code ===
                'messaging/invalid-registration-token'
          ) {
            invalidTokens.push(
              uniqueTokens[index],
            );
          }
        },
      );

      this.logger.log(
        `FCM: ${response.successCount} thành công, ${response.failureCount} thất bại`,
      );

      return {
        invalidTokens,
      };
    } catch (error) {
      this.logger.error(
        'Gửi FCM thất bại',
        error instanceof Error
            ? error.stack
            : String(error),
      );

      return {
        invalidTokens:
          [] as string[],
      };
    }
  }
}
