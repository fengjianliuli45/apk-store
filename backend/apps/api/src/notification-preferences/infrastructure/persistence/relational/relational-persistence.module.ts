import { Module } from '@nestjs/common';
import { NotificationPreferenceRepository } from '../notification-preference.repository';
import { NotificationPreferenceRelationalRepository } from './repositories/notification-preference.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationPreferenceEntity } from './entities/notification-preference.entity';

@Module({
  imports: [TypeOrmModule.forFeature([NotificationPreferenceEntity])],
  providers: [
    {
      provide: NotificationPreferenceRepository,
      useClass: NotificationPreferenceRelationalRepository,
    },
  ],
  exports: [NotificationPreferenceRepository],
})
export class RelationalNotificationPreferencePersistenceModule {}
