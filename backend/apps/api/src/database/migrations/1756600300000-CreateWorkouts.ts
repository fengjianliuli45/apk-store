import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateWorkouts1756600300000 implements MigrationInterface {
  name = 'CreateWorkouts1756600300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "workout_session" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "planVersionId" uuid,
        "planDayIndex" integer,
        "sessionType" character varying NOT NULL,
        "scheduledDate" date,
        "status" character varying NOT NULL DEFAULT 'planned',
        "startedAt" TIMESTAMP,
        "completedAt" TIMESTAMP,
        "notes" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workout_session_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_workout_session_user_created" ON "workout_session" ("userId", "createdAt")`,
    );
    await queryRunner.query(
      `ALTER TABLE "workout_session" ADD CONSTRAINT "FK_workout_session_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "workout_set" (
        "id" uuid NOT NULL,
        "sessionId" uuid NOT NULL,
        "exerciseKey" character varying NOT NULL,
        "exerciseName" character varying NOT NULL,
        "setIndex" integer NOT NULL,
        "reps" integer,
        "weightKg" real,
        "rir" real,
        "isWarmup" boolean NOT NULL DEFAULT false,
        "completedAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workout_set_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_workout_set_sessionId" ON "workout_set" ("sessionId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "workout_set" ADD CONSTRAINT "FK_workout_set_sessionId" FOREIGN KEY ("sessionId") REFERENCES "workout_session"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "workout_set" DROP CONSTRAINT "FK_workout_set_sessionId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_workout_set_sessionId"`);
    await queryRunner.query(`DROP TABLE "workout_set"`);
    await queryRunner.query(
      `ALTER TABLE "workout_session" DROP CONSTRAINT "FK_workout_session_userId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_workout_session_user_created"`);
    await queryRunner.query(`DROP TABLE "workout_session"`);
  }
}
