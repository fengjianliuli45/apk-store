import { Module } from '@nestjs/common';
import { SyncEmitterService } from './sync-emitter.service';
import { RelationalSyncEventPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';

/**
 * 变更流基础设施：领域模块 import 它并注入 SyncEmitterService。
 * 不含 HTTP —— /api/v1/sync 端点在 SyncModule。
 */
@Module({
  imports: [RelationalSyncEventPersistenceModule],
  providers: [SyncEmitterService],
  exports: [SyncEmitterService, RelationalSyncEventPersistenceModule],
})
export class SyncEventsModule {}
