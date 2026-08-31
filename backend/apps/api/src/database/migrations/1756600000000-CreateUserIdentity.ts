import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUserIdentity1756600000000 implements MigrationInterface {
  name = 'CreateUserIdentity1756600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "user_identity" (
        "id" uuid NOT NULL,
        "provider" character varying NOT NULL,
        "providerUid" character varying NOT NULL,
        "userId" integer NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_user_identity_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_user_identity_provider_uid" ON "user_identity" ("provider", "providerUid")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_user_identity_userId" ON "user_identity" ("userId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_identity" ADD CONSTRAINT "FK_user_identity_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_identity" DROP CONSTRAINT "FK_user_identity_userId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_user_identity_userId"`);
    await queryRunner.query(`DROP INDEX "uq_user_identity_provider_uid"`);
    await queryRunner.query(`DROP TABLE "user_identity"`);
  }
}
