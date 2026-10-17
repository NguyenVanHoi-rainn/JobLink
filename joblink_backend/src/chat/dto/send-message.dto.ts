import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export enum MessageTypeDto {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  FILE = 'FILE',
}

export class SendMessageDto {
  @IsOptional()
  @IsString()
  content?: string;

  @IsOptional()
  @IsEnum(MessageTypeDto)
  messageType?: MessageTypeDto;

  @IsOptional()
  @IsString()
  fileUrl?: string;

  @IsOptional()
  @IsUUID('4')
  replyToId?: string;
}