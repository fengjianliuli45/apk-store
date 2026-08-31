import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import { SocialService } from './social.service';
import { RelationalSocialPostPersistenceModule } from '../social-posts/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalPostCommentPersistenceModule } from '../post-comments/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalPostLikePersistenceModule } from '../post-likes/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalFollowPersistenceModule } from '../follows/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalBlockPersistenceModule } from '../blocks/infrastructure/persistence/relational/relational-persistence.module';
import { RelationalReportPersistenceModule } from '../reports/infrastructure/persistence/relational/relational-persistence.module';
import { MediaObjectsModule } from '../media-objects/media-objects.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    RelationalSocialPostPersistenceModule,
    RelationalPostCommentPersistenceModule,
    RelationalPostLikePersistenceModule,
    RelationalFollowPersistenceModule,
    RelationalBlockPersistenceModule,
    RelationalReportPersistenceModule,
    MediaObjectsModule,
    NotificationsModule,
  ],
  controllers: [SocialController],
  providers: [SocialService],
  exports: [SocialService],
})
export class SocialModule {}
