import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { RequestWithUser } from '../utils/types/request-with-user.type';
import type { JwtPayloadType } from '../auth/strategies/types/jwt-payload.type';
import { NotificationsService } from './notifications.service';
import { Notification } from './domain/notification';
import { CursorPage } from '../common/pagination/cursor';
import { NotificationPreferencesService } from '../notification-preferences/notification-preferences.service';
import { NotificationPreference } from '../notification-preferences/domain/notification-preference';
import { UpdatePreferencesDto } from '../notification-preferences/dto/update-preferences.dto';
import { DeviceTokensService } from '../device-tokens/device-tokens.service';
import { DeviceToken } from '../device-tokens/domain/device-token';
import { RegisterDeviceDto } from '../device-tokens/dto/register-device.dto';
import { MarkReadDto } from './dto/mark-read.dto';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller({
  path: 'notifications',
  version: '1',
})
export class NotificationsController {
  constructor(
    private readonly notifications: NotificationsService,
    private readonly preferences: NotificationPreferencesService,
    private readonly devices: DeviceTokensService,
  ) {}

  private uid(request: RequestWithUser<JwtPayloadType>): number {
    return Number(request.user.id);
  }

  @Get()
  @ApiOkResponse({ type: Notification, isArray: true })
  list(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Query() query: ListNotificationsQueryDto,
  ): Promise<CursorPage<Notification>> {
    return this.notifications.list(this.uid(request), {
      limit: query.limit ?? 20,
      cursor: query.cursor,
      unreadOnly: query.unreadOnly,
    });
  }

  @Get('unread-count')
  @ApiOkResponse({ schema: { properties: { count: { type: 'number' } } } })
  async unreadCount(
    @Request() request: RequestWithUser<JwtPayloadType>,
  ): Promise<{ count: number }> {
    return { count: await this.notifications.unreadCount(this.uid(request)) };
  }

  @Post('read')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ schema: { properties: { updated: { type: 'number' } } } })
  async markRead(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: MarkReadDto,
  ): Promise<{ updated: number }> {
    return {
      updated: await this.notifications.markRead(this.uid(request), dto),
    };
  }

  @Get('preferences')
  @ApiOkResponse({ type: NotificationPreference })
  getPreferences(
    @Request() request: RequestWithUser<JwtPayloadType>,
  ): Promise<NotificationPreference> {
    return this.preferences.getOrDefault(this.uid(request));
  }

  @Put('preferences')
  @ApiOkResponse({ type: NotificationPreference })
  updatePreferences(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: UpdatePreferencesDto,
  ): Promise<NotificationPreference> {
    return this.preferences.update(this.uid(request), dto);
  }

  @Get('devices')
  @ApiOkResponse({ type: DeviceToken, isArray: true })
  listDevices(
    @Request() request: RequestWithUser<JwtPayloadType>,
  ): Promise<DeviceToken[]> {
    return this.devices.list(this.uid(request));
  }

  @Post('devices')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: DeviceToken })
  registerDevice(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Body() dto: RegisterDeviceDto,
  ): Promise<DeviceToken> {
    return this.devices.register(this.uid(request), dto);
  }

  @Delete('devices/:token')
  @HttpCode(HttpStatus.NO_CONTENT)
  unregisterDevice(
    @Request() request: RequestWithUser<JwtPayloadType>,
    @Param('token') token: string,
  ): Promise<void> {
    return this.devices.unregister(this.uid(request), token);
  }
}
