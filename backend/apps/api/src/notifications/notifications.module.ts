import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { RelationalNotificationPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { RelationalNotificationPreferencePersistenceModule } from '../notification-preferences/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalDeviceTokenPersistenceModule } from '../device-tokens/infrastructure/persistence/relational/relational-persistence.module';
import { NotificationPreferencesService } from '../notification-preferences/notification-preferences.service';
import { DeviceTokensService } from '../device-tokens/device-tokens.service';
import { AllConfigType } from '../config/config.type';
import {
  ConsolePushService,
  OffPushService,
  PushService,
} from './push/push.service';

@Module({
  imports: [
    ConfigModule,
    RelationalNotificationPersistenceModule,
    RelationalNotificationPreferencePersistenceModule,
    RelationalDeviceTokenPersistenceModule,
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationPreferencesService,
    DeviceTokensService,
    {
      provide: PushService,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AllConfigType>) => {
        const driver = config.get('notifications.pushDriver', { infer: true });
        return driver === 'off'
          ? new OffPushService()
          : new ConsolePushService();
      },
    },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
