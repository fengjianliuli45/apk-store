import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/** 一组。属于一个 workout_session。修正靠新增/替换，不做隐式合并。 */
export class WorkoutSet {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  sessionId: string;

  @ApiProperty({ type: String, example: 'horizontal_push' })
  exerciseKey: string;

  @ApiProperty({ type: String, example: '杠铃卧推' })
  exerciseName: string;

  @ApiProperty({ type: Number, example: 1 })
  setIndex: number;

  @ApiPropertyOptional({ type: Number, example: 8 })
  reps: number | null;

  @ApiPropertyOptional({ type: Number, example: 60 })
  weightKg: number | null;

  @ApiPropertyOptional({
    type: Number,
    example: 2,
    description: 'reps in reserve',
  })
  rir: number | null;

  @ApiProperty({ type: Boolean, default: false })
  isWarmup: boolean;

  @ApiPropertyOptional({ type: Date })
  completedAt: Date | null;

  @ApiProperty()
  createdAt: Date;
}
