import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsInt, IsString, Min } from 'class-validator';

const PURPOSES = ['avatar', 'post', 'chat', 'progress_photo'];

export class RequestUploadDto {
  @ApiProperty({ enum: PURPOSES })
  @IsIn(PURPOSES)
  purpose: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  contentType: string;

  @ApiProperty({ example: 204800, description: '文件字节数' })
  @IsInt()
  @Min(1)
  declaredSize: number;
}
