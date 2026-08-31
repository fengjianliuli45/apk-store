import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSyncEvent1756600400000 implements MigrationInterface {
  name = 'CreateSyncEvent1756600400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "sync_event" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "serverSeq" integer NOT NULL,
        "entityType" character varying NOT NULL,
        "entityId" character varying,
        "op" character varying NOT NULL,
        "payload" jsonb NOT NULL,
        "clientEventId" character varying,
        "occurredAt" TIMESTAMP NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sync_event_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_sync_event_user_seq" ON "sync_event" ("userId", "serverSeq")`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_sync_event_user_client" ON "sync_event" ("userId", "clientEventId") WHERE "clientEventId" IS NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "sync_event" ADD CONSTRAINT "FK_sync_event_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sync_event" DROP CONSTRAINT "FK_sync_event_userId"`,
    );
    await queryRunner.query(`DROP INDEX "uq_sync_event_user_client"`);
    await queryRunner.query(`DROP INDEX "uq_sync_event_user_seq"`);
    await queryRunner.query(`DROP TABLE "sync_event"`);
  }
}
