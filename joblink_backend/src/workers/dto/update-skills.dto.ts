import {
  ArrayNotEmpty,
  IsArray,
  IsUUID,
} from 'class-validator';

export class UpdateSkillsDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  skillIds: string[];
}