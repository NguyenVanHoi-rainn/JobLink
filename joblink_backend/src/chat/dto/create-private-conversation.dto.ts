import { IsUUID } from 'class-validator';

export class CreatePrivateConversationDto {
  @IsUUID('4')
  targetUserId: string;
}