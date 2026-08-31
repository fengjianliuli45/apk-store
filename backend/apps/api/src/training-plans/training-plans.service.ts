import { Injectable, NotFoundException } from '@nestjs/common';
import { TrainingPlanRepository } from './infrastructure/persistence/training-plan.repository';
import { PlanVersionRepository } from '../plan-versions/infrastructure/persistence/plan-version.repository';
import { TrainingPlan, TrainingPlanWithVersion } from './domain/training-plan';
import { PlanVersion } from '../plan-versions/domain/plan-version';
import { CursorPage } from '../common/pagination/cursor';
import { SavePlanDto } from './dto/save-plan.dto';

@Injectable()
export class TrainingPlansService {
  constructor(
    private readonly planRepository: TrainingPlanRepository,
    private readonly versionRepository: PlanVersionRepository,
  ) {}

  /**
   * 保存一份计划：用户已有 active 计划 → 追加新版本；否则新建计划 + 版本 1。
   * 版本只增不改。
   */
  async savePlan(
    userId: number,
    dto: SavePlanDto,
  ): Promise<TrainingPlanWithVersion> {
    const active = await this.planRepository.findActiveByUserId(userId);

    const plan =
      active ??
      (await this.planRepository.create({
        userId,
        status: 'active',
        plannerVersion: dto.plannerVersion,
        generatedBy: dto.generatedBy,
        currentVersionNumber: 0,
        currentVersionId: null,
      }));

    const versionNumber = plan.currentVersionNumber + 1;

    const version = await this.versionRepository.create({
      planId: plan.id,
      versionNumber,
      plannerVersion: dto.plannerVersion,
      generatedBy: dto.generatedBy,
      inputSnapshot: dto.inputSnapshot,
      planJson: dto.planJson,
      changeReason: dto.changeReason ?? null,
    });

    const updatedPlan = await this.planRepository.update(plan.id, {
      currentVersionNumber: versionNumber,
      currentVersionId: version.id,
      plannerVersion: dto.plannerVersion,
      generatedBy: dto.generatedBy,
    });

    return { plan: updatedPlan ?? plan, currentVersion: version };
  }

  async getCurrent(userId: number): Promise<TrainingPlanWithVersion> {
    const plan = await this.planRepository.findActiveByUserId(userId);
    if (!plan || !plan.currentVersionId) {
      throw new NotFoundException({ errors: { plan: 'noActivePlan' } });
    }
    const currentVersion = await this.versionRepository.findById(
      plan.currentVersionId,
    );
    if (!currentVersion) {
      throw new NotFoundException({
        errors: { plan: 'currentVersionMissing' },
      });
    }
    return { plan, currentVersion };
  }

  async listVersions(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PlanVersion>> {
    const plan = await this.planRepository.findActiveByUserId(userId);
    if (!plan) {
      throw new NotFoundException({ errors: { plan: 'noActivePlan' } });
    }
    return this.versionRepository.listByPlan(plan.id, limit, cursor);
  }

  async getVersion(userId: number, versionId: string): Promise<PlanVersion> {
    const version = await this.versionRepository.findById(versionId);
    if (!version) {
      throw new NotFoundException({ errors: { version: 'notFound' } });
    }
    const plan = await this.planRepository.findById(version.planId);
    if (!plan || plan.userId !== userId) {
      // 不暴露「存在但不属于你」——按 404 处理
      throw new NotFoundException({ errors: { version: 'notFound' } });
    }
    return version;
  }

  async archiveCurrent(userId: number): Promise<TrainingPlan> {
    const plan = await this.planRepository.findActiveByUserId(userId);
    if (!plan) {
      throw new NotFoundException({ errors: { plan: 'noActivePlan' } });
    }
    const updated = await this.planRepository.update(plan.id, {
      status: 'archived',
    });
    return updated ?? plan;
  }
}
