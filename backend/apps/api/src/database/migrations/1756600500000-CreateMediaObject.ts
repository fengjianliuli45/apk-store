import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateMediaObject1756600500000 implements MigrationInterface {
  name = 'CreateMediaObject1756600500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "media_object" (
        "id" uuid NOT NULL,
        "userId" integer NOT NULL,
        "purpose" character varying NOT NULL,
        "storageKey" character varying NOT NULL,
        "contentType" character varying NOT NULL,
        "declaredSize" integer NOT NULL,
        "actualSize" integer,
        "status" character varying NOT NULL DEFAULT 'pending',
        "moderationStatus" character varying NOT NULL DEFAULT 'pending',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_media_object_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_media_object_storageKey" ON "media_object" ("storageKey")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_media_object_user" ON "media_object" ("userId", "createdAt")`,
    );
    await queryRunner.query(
      `ALTER TABLE "media_object" ADD CONSTRAINT "FK_media_object_userId" FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "media_object" DROP CONSTRAINT "FK_media_object_userId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_media_object_user"`);
    await queryRunner.query(`DROP INDEX "uq_media_object_storageKey"`);
    await queryRunner.query(`DROP TABLE "media_object"`);
  }
}
