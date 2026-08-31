import { Module } from '@nestjs/common';
import { DeviceTokenRepository } from '../device-token.repository';
import { DeviceTokenRelationalRepository } from './repositories/device-token.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeviceTokenEntity } from './entities/device-token.entity';

@Module({
  imports: [TypeOrmModule.forFeature([DeviceTokenEntity])],
  providers: [
    {
      provide: DeviceTokenRepository,
      useClass: DeviceTokenRelationalRepository,
    },
  ],
  exports: [DeviceTokenRepository],
})
export class RelationalDeviceTokenPersistenceModule {}
