import { ApiProperty } from '@nestjs/swagger';
import { PlanVersion } from '../../plan-versions/domain/plan-version';

export type TrainingPlanStatus = 'active' | 'archived';

/**
 * 一个用户的一份计划容器。同一时刻最多一份 active。
 * 计划内容不存这里，存 plan_version 快照（append-only）。
 */
export class TrainingPlan {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: String, example: 'active' })
  status: TrainingPlanStatus;

  @ApiProperty({ type: String, example: '1.8' })
  plannerVersion: string;

  @ApiProperty({ type: String, example: 'dart' })
  generatedBy: string;

  @ApiProperty({ type: Number, example: 3 })
  currentVersionNumber: number;

  @ApiProperty({ type: String, nullable: true })
  currentVersionId: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class TrainingPlanWithVersion {
  @ApiProperty({ type: () => TrainingPlan })
  plan: TrainingPlan;

  @ApiProperty({ type: () => PlanVersion })
  currentVersion: PlanVersion;
}
