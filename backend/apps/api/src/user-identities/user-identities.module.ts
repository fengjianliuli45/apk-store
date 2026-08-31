import { Module } from '@nestjs/common';
import { UserIdentitiesService } from './user-identities.service';
import { RelationalUserIdentityPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';

@Module({
  imports: [RelationalUserIdentityPersistenceModule],
  providers: [UserIdentitiesService],
  exports: [UserIdentitiesService, RelationalUserIdentityPersistenceModule],
})
export class UserIdentitiesModule {}
