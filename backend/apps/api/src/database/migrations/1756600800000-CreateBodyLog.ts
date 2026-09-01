import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateBodyLog1756600800000 implements MigrationInterface {
  name = 'CreateBodyLog1756600800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "body_log" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "measuredOn" date NOT NULL,
        "weightKg" real,
        "bodyFatPct" real,
        "waistCm" real,
        "armCm" real,
        "thighCm" real,
        "note" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_body_log_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_body_log_user_date" ON "body_log" ("userId", "measuredOn")`,
    );
    await queryRunner.query(
      `ALTER TABLE "body_log" ADD CONSTRAINT "FK_body_log_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "body_log" DROP CONSTRAINT "FK_body_log_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_body_log_user_date"`);
    await queryRunner.query(`DROP TABLE "body_log"`);
  }
}
