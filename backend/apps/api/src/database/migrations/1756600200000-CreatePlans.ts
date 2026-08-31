import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePlans1756600200000 implements MigrationInterface {
  name = 'CreatePlans1756600200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "training_plan" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "status" character varying NOT NULL DEFAULT 'active',
        "plannerVersion" character varying NOT NULL,
        "generatedBy" character varying NOT NULL,
        "currentVersionNumber" integer NOT NULL DEFAULT 0,
        "currentVersionId" uuid,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_training_plan_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_training_plan_userId" ON "training_plan" ("userId")`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_training_plan_one_active" ON "training_plan" ("userId") WHERE "status" = 'active'`,
    );
    await queryRunner.query(
      `ALTER TABLE "training_plan" ADD CONSTRAINT "FK_training_plan_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "plan_version" (
        "id" uuid NOT NULL,
        "planId" uuid NOT NULL,
        "versionNumber" integer NOT NULL,
        "plannerVersion" character varying NOT NULL,
        "generatedBy" character varying NOT NULL,
        "inputSnapshot" jsonb NOT NULL,
        "planJson" jsonb NOT NULL,
        "changeReason" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_plan_version_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_plan_version_planId" ON "plan_version" ("planId")`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_plan_version_plan_number" ON "plan_version" ("planId", "versionNumber")`,
    );
    await queryRunner.query(
      `ALTER TABLE "plan_version" ADD CONSTRAINT "FK_plan_version_planId" FOREIGN KEY ("planId") REFERENCES "training_plan"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "plan_version" DROP CONSTRAINT "FK_plan_version_planId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_plan_version_plan_number"`);
    await queryRunner.query(`DROP INDEX "IDX_plan_version_planId"`);
    await queryRunner.query(`DROP TABLE "plan_version"`);
    await queryRunner.query(
      `ALTER TABLE "training_plan" DROP CONSTRAINT "FK_training_plan_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_training_plan_one_active"`);
    await queryRunner.query(`DROP INDEX "IDX_training_plan_userId"`);
    await queryRunner.query(`DROP TABLE "training_plan"`);
  }
}
