import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateNotifications1756600600000 implements MigrationInterface {
  name = 'CreateNotifications1756600600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "notification" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "type" character varying NOT NULL,
        "title" character varying NOT NULL,
        "body" text NOT NULL,
        "data" jsonb NOT NULL DEFAULT '{}',
        "readAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notification_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_notification_user_created" ON "notification" ("userId", "createdAt")`,
    );
    await queryRunner.query(
      `ALTER TABLE "notification" ADD CONSTRAINT "FK_notification_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "notification_preference" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "pushEnabled" boolean NOT NULL DEFAULT true,
        "categories" jsonb NOT NULL DEFAULT '{}',
        "quietHoursStart" smallint,
        "quietHoursEnd" smallint,
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notification_preference_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_notification_preference_userId" ON "notification_preference" ("userId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "notification_preference" ADD CONSTRAINT "FK_notification_preference_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "device_token" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "platform" character varying NOT NULL,
        "token" character varying NOT NULL,
        "vendorChannel" character varying,
        "lastSeenAt" TIMESTAMP NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_device_token_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_device_token_userId" ON "device_token" ("userId")`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_device_token_user_token" ON "device_token" ("userId", "token")`,
    );
    await queryRunner.query(
      `ALTER TABLE "device_token" ADD CONSTRAINT "FK_device_token_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "device_token" DROP CONSTRAINT "FK_device_token_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_device_token_user_token"`);
    await queryRunner.query(`DROP INDEX "IDX_device_token_userId"`);
    await queryRunner.query(`DROP TABLE "device_token"`);
    await queryRunner.query(
      `ALTER TABLE "notification_preference" DROP CONSTRAINT "FK_notification_preference_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_notification_preference_userId"`);
    await queryRunner.query(`DROP TABLE "notification_preference"`);
    await queryRunner.query(
      `ALTER TABLE "notification" DROP CONSTRAINT "FK_notification_userId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_notification_user_created"`);
    await queryRunner.query(`DROP TABLE "notification"`);
  }
}
