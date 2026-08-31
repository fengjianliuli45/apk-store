import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
} from 'class-validator';

export class MarkReadDto {
  @ApiPropertyOptional({ type: [String], description: '要标已读的通知 id' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(500)
  @IsString({ each: true })
  ids?: string[];

  @ApiPropertyOptional({ description: 'true = 全部标已读（忽略 ids）' })
  @IsOptional()
  @IsBoolean()
  all?: boolean;
}
