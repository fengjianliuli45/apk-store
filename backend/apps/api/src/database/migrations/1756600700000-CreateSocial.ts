import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSocial1756600700000 implements MigrationInterface {
  name = 'CreateSocial1756600700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "social_post" (
        "id" uuid NOT NULL,
        "authorId" integer NOT NULL,
        "kind" character varying NOT NULL DEFAULT 'text',
        "body" text NOT NULL DEFAULT '',
        "mediaIds" jsonb NOT NULL DEFAULT '[]',
        "refType" character varying,
        "refId" character varying,
        "visibility" character varying NOT NULL DEFAULT 'public',
        "likeCount" integer NOT NULL DEFAULT 0,
        "commentCount" integer NOT NULL DEFAULT 0,
        "moderationStatus" character varying NOT NULL DEFAULT 'pending',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "deletedAt" TIMESTAMP,
        CONSTRAINT "PK_social_post_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_social_post_author_created" ON "social_post" ("authorId", "createdAt")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_social_post_created" ON "social_post" ("createdAt")`,
    );
    await queryRunner.query(
      `ALTER TABLE "social_post" ADD CONSTRAINT "FK_social_post_authorId" FOREIGN KEY ("authorId") REFERENCES "user"("id") ON DELETE CASCADE`,
    );

    await queryRunner.query(
      `CREATE TABLE "post_comment" (
        "id" uuid NOT NULL,
        "postId" uuid NOT NULL,
        "authorId" integer NOT NULL,
        "body" text NOT NULL,
        "moderationStatus" character varying NOT NULL DEFAULT 'pending',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "deletedAt" TIMESTAMP,
        CONSTRAINT "PK_post_comment_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_post_comment_post_created" ON "post_comment" ("postId", "createdAt")`,
    );
    await queryRunner.query(
      `ALTER TABLE "post_comment" ADD CONSTRAINT "FK_post_comment_postId" FOREIGN KEY ("postId") REFERENCES "social_post"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "post_comment" ADD CONSTRAINT "FK_post_comment_authorId" FOREIGN KEY ("authorId") REFERENCES "user"("id") ON DELETE CASCADE`,
    );

    await queryRunner.query(
      `CREATE TABLE "post_like" (
        "id" uuid NOT NULL,
        "postId" uuid NOT NULL,
        "userId" integer NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_post_like_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_post_like_post_user" ON "post_like" ("postId", "userId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "post_like" ADD CONSTRAINT "FK_post_like_postId" FOREIGN KEY ("postId") REFERENCES "social_post"("id") ON DELETE CASCADE`,
    );

    await queryRunner.query(
      `CREATE TABLE "follow" (
        "id" uuid NOT NULL,
        "followerId" integer NOT NULL,
        "followeeId" integer NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_follow_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_follow_pair" ON "follow" ("followerId", "followeeId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_follow_followee" ON "follow" ("followeeId")`,
    );

    await queryRunner.query(
      `CREATE TABLE "block" (
        "id" uuid NOT NULL,
        "blockerId" integer NOT NULL,
        "blockedId" integer NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_block_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "uq_block_pair" ON "block" ("blockerId", "blockedId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_block_blockerId" ON "block" ("blockerId")`,
    );

    await queryRunner.query(
      `CREATE TABLE "report" (
        "id" uuid NOT NULL,
        "reporterId" integer NOT NULL,
        "targetType" character varying NOT NULL,
        "targetId" character varying NOT NULL,
        "reason" character varying NOT NULL,
        "detail" text,
        "status" character varying NOT NULL DEFAULT 'open',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_report_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_report_status_created" ON "report" ("status", "createdAt")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "report"`);
    await queryRunner.query(`DROP TABLE "block"`);
    await queryRunner.query(`DROP TABLE "follow"`);
    await queryRunner.query(
      `ALTER TABLE "post_like" DROP CONSTRAINT "FK_post_like_postId"`,
    );
    await queryRunner.query(`DROP TABLE "post_like"`);
    await queryRunner.query(
      `ALTER TABLE "post_comment" DROP CONSTRAINT "FK_post_comment_authorId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "post_comment" DROP CONSTRAINT "FK_post_comment_postId"`,
    );
    await queryRunner.query(`DROP TABLE "post_comment"`);
    await queryRunner.query(
      `ALTER TABLE "social_post" DROP CONSTRAINT "FK_social_post_authorId"`,
    );
    await queryRunner.query(`DROP TABLE "social_post"`);
  }
}
