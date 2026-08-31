import { Module } from '@nestjs/common';
import { UserIdentityRepository } from '../user-identity.repository';
import { UserIdentityRelationalRepository } from './repositories/user-identity.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserIdentityEntity } from './entities/user-identity.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserIdentityEntity])],
  providers: [
    {
      provide: UserIdentityRepository,
      useClass: UserIdentityRelationalRepository,
    },
  ],
  exports: [UserIdentityRepository],
})
export class RelationalUserIdentityPersistenceModule {}
