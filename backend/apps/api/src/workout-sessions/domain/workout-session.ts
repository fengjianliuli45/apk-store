import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { WorkoutSet } from '../../workout-sets/domain/workout-set';

export type WorkoutSessionStatus =
  | 'planned'
  | 'in_progress'
  | 'completed'
  | 'skipped';

/** 一次训练。关联到某个 plan_version 的某一天（可空，允许自由训练）。 */
export class WorkoutSession {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiPropertyOptional({ type: String })
  planVersionId: string | null;

  @ApiPropertyOptional({ type: Number, example: 0 })
  planDayIndex: number | null;

  @ApiProperty({ type: String, example: 'strength' })
  sessionType: string;

  @ApiPropertyOptional({ type: String, format: 'date' })
  scheduledDate: string | null;

  @ApiProperty({ type: String, example: 'in_progress' })
  status: WorkoutSessionStatus;

  @ApiPropertyOptional({ type: Date })
  startedAt: Date | null;

  @ApiPropertyOptional({ type: Date })
  completedAt: Date | null;

  @ApiPropertyOptional({ type: String })
  notes: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class WorkoutSessionWithSets {
  @ApiProperty({ type: () => WorkoutSession })
  session: WorkoutSession;

  @ApiProperty({ type: () => WorkoutSet, isArray: true })
  sets: WorkoutSet[];
}
