import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateProfile1756600100000 implements MigrationInterface {
  name = 'CreateProfile1756600100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "profile" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "sex" character varying,
        "birthdate" date,
        "heightCm" real,
        "goal" character varying,
        "experienceLevel" character varying,
        "minutesPerSession" integer,
        "mealsPerDay" integer,
        "cookingAccess" character varying,
        "targetWeightKg" real,
        "injuriesText" text,
        "equipment" jsonb NOT NULL DEFAULT '[]',
        "dietaryRestrictions" jsonb NOT NULL DEFAULT '[]',
        "bodyDataConsentAt" TIMESTAMP,
        "bodyDataConsentVersion" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_profile_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_profile_userId" ON "profile" ("userId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "profile" ADD CONSTRAINT "FK_profile_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "profile" DROP CONSTRAINT "FK_profile_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_profile_userId"`);
    await queryRunner.query(`DROP TABLE "profile"`);
  }
}
