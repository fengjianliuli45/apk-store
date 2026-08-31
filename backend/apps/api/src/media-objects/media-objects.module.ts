import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MediaObjectsService } from './media-objects.service';
import { MediaObjectsController } from './media-objects.controller';
import { RelationalMediaObjectPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { AllConfigType } from '../config/config.type';
import { StorageService } from './storage/storage.service';
import { FakeStorageService } from './storage/fake-storage.service';
import { S3StorageService } from './storage/s3-storage.service';

@Module({
  imports: [ConfigModule, RelationalMediaObjectPersistenceModule],
  controllers: [MediaObjectsController],
  providers: [
    MediaObjectsService,
    {
      provide: StorageService,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AllConfigType>) => {
        const media = config.getOrThrow('media', { infer: true });
        return media.driver === 's3'
          ? new S3StorageService(media)
          : new FakeStorageService();
      },
    },
  ],
  exports: [MediaObjectsService],
})
export class MediaObjectsModule {}
