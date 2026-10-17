import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
  BadRequestException,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';


import { ChatService } from './chat.service.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

import { CreatePrivateConversationDto } from './dto/create-private-conversation.dto.js';
import { SendMessageDto,
        MessageTypeDto,
    } from './dto/send-message.dto.js';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller('conversations')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private readonly chatService:
      ChatService,
  ) {}

  @Post('private')
  createPrivateConversation(
    @CurrentUser()
    user: any,

    @Body()
    dto: CreatePrivateConversationDto,
  ) {
    return this.chatService.createPrivateConversation(
      user.sub,
      dto,
    );
  }

  @Get()
  getMyConversations(
    @CurrentUser()
    user: any,
  ) {
    return this.chatService.getMyConversations(
      user.sub,
    );
  }

  @Get(':id/messages')
  getMessages(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,

    @Query(
      'page',
      new DefaultValuePipe(1),
      ParseIntPipe,
    )
    page: number,

    @Query(
      'limit',
      new DefaultValuePipe(50),
      ParseIntPipe,
    )
    limit: number,
  ) {
    return this.chatService.getMessages(
      user.sub,
      id,
      page,
      limit,
    );
  }

  @Post(':id/messages')
  sendMessage(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,

    @Body()
    dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(
      user.sub,
      id,
      dto,
    );
  }

    @Post(':id/files')
    @UseInterceptors(
    FileInterceptor('file', {
        storage: diskStorage({
        destination: './uploads/chat',

        filename: (
            req,
            file,
            callback,
        ) => {
            const uniqueName =
            `${Date.now()}-${Math.round(
                Math.random() * 1e9,
            )}`;

            callback(
            null,
            `${uniqueName}${extname(file.originalname)}`,
            );
        },
        }),

        limits: {
        fileSize: 10 * 1024 * 1024,
        },
    }),
    )
    async sendFile(
    @CurrentUser()
    user: any,

    @Param('id', ParseUUIDPipe)
    id: string,

    @UploadedFile()
    file: Express.Multer.File,
    ) {
    if (!file) {
        throw new BadRequestException(
        'Vui lòng chọn file',
        );
    }

    const imageTypes = [
        'image/jpeg',
        'image/png',
        'image/webp',
    ];

    const messageType: MessageTypeDto =
        imageTypes.includes(file.mimetype)
            ? MessageTypeDto.IMAGE
            : MessageTypeDto.FILE;

    return this.chatService.sendMessage(
        user.sub,
        id,
        {
        messageType,
        fileUrl:
            `uploads/chat/${file.filename}`,
        },
    );
    }

}