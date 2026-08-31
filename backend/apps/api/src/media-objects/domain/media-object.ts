import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type MediaStatus = 'pending' | 'ready' | 'rejected';
export type MediaPurpose = 'avatar' | 'post' | 'chat' | 'progress_photo';

/**
 * 一个用户上传的媒体对象。大文件不经过 API —— 客户端拿预签名 URL 直传对象存储，
 * 传完回调 complete，服务端 HEAD 校验后置 ready（ADAPTATION_PLAN §9.13）。
 */
export class MediaObject {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: String, example: 'post' })
  purpose: MediaPurpose;

  @ApiProperty({ type: String, description: '对象存储里的 key' })
  storageKey: string;

  @ApiProperty({ type: String, example: 'image/jpeg' })
  contentType: string;

  @ApiProperty({ type: Number, description: '声明的字节数' })
  declaredSize: number;

  @ApiPropertyOptional({
    type: Number,
    description: 'complete 时 HEAD 到的实际字节数',
  })
  actualSize: number | null;

  @ApiProperty({ type: String, example: 'pending' })
  status: MediaStatus;

  @ApiProperty({
    type: String,
    example: 'pending',
    description: '内容审核：pending | approved | rejected（异步）',
  })
  moderationStatus: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
