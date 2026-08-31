import { Module } from '@nestjs/common';
import { ProfileRepository } from '../profile.repository';
import { ProfileRelationalRepository } from './repositories/profile.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProfileEntity } from './entities/profile.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ProfileEntity])],
  providers: [
    {
      provide: ProfileRepository,
      useClass: ProfileRelationalRepository,
    },
  ],
  exports: [ProfileRepository],
})
export class RelationalProfilePersistenceModule {}
