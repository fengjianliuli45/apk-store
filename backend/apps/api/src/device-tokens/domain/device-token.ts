import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const DEVICE_PLATFORMS = [
  'ios',
  'android_fcm',
  'android_vendor',
] as const;
export type DevicePlatform = (typeof DEVICE_PLATFORMS)[number];

/**
 * 一台设备的推送 token。国内 Android 走厂商通道（vendorChannel），
 * 国际走 FCM，iOS 走 APNs（ADAPTATION_PLAN §9.4）。
 */
export class DeviceToken {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ enum: DEVICE_PLATFORMS })
  platform: DevicePlatform;

  @ApiProperty({ type: String })
  token: string;

  @ApiPropertyOptional({
    type: String,
    example: 'xiaomi',
    description:
      'android_vendor 时的厂商 / 聚合通道：xiaomi|huawei|oppo|vivo|getui|jpush',
  })
  vendorChannel: string | null;

  @ApiProperty()
  lastSeenAt: Date;

  @ApiProperty()
  createdAt: Date;
}
