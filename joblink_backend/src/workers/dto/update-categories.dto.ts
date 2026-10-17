import {
  ArrayNotEmpty,
  IsArray,
  IsUUID,
} from 'class-validator';

export class UpdateCategoriesDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  categoryIds: string[];
}