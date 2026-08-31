import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { DEVICE_PLATFORMS } from '../domain/device-token';

export class RegisterDeviceDto {
  @ApiProperty({ enum: DEVICE_PLATFORMS })
  @IsIn(DEVICE_PLATFORMS as unknown as string[])
  platform: string;

  @ApiProperty()
  @IsString()
  @MaxLength(500)
  token: string;

  @ApiPropertyOptional({
    example: 'xiaomi',
    description: 'android_vendor 时的厂商 / 聚合通道',
  })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  vendorChannel?: string;
}
