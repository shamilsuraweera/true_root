import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1795279906501 implements MigrationInterface {
  name = 'InitialSchema1795279906501';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "batch_events" ("id" SERIAL NOT NULL, "batch_id" integer NOT NULL, "type" character varying(50) NOT NULL, "stage_id" integer, "description" text, "quantity_before" numeric(14,3), "quantity_after" numeric(14,3), "status_before" character varying(50), "status_after" character varying(50), "grade_before" character varying(50), "grade_after" character varying(50), "actor_user_id" integer, "metadata" jsonb, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_43754047a56220bd40ed3e8a658" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "batches" ("id" SERIAL NOT NULL, "product_id" integer, "is_item" boolean NOT NULL DEFAULT false, "item_name" text, "owner_id" integer, "batch_code" character varying NOT NULL, "quantity" numeric(14,3) NOT NULL, "unit" character varying NOT NULL DEFAULT 'kg', "status" character varying(50) NOT NULL, "grade" character varying(50), "stage_id" integer, "qr_payload" text, "is_disqualified" boolean NOT NULL DEFAULT false, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_41bcb247f312ad786d1048be910" UNIQUE ("batch_code"), CONSTRAINT "UQ_a4cd55b3930105aab378515192c" UNIQUE ("qr_payload"), CONSTRAINT "PK_55e7ff646e969b61d37eea5be7a" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "batch_relations" ("id" SERIAL NOT NULL, "parent_batch_id" integer NOT NULL, "child_batch_id" integer NOT NULL, "relation_type" character varying NOT NULL, "quantity" numeric(14,3), "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_2242fc1a2b1c6a7899d2c44bf5a" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "ownership_requests" ("id" SERIAL NOT NULL, "batch_id" integer NOT NULL, "requester_id" integer NOT NULL, "owner_id" integer NOT NULL, "quantity" numeric(14,3) NOT NULL, "status" character varying(20) NOT NULL, "note" text, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_e1ee524ebaba61b8bf22bad24e0" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "products" ("id" SERIAL NOT NULL, "name" text NOT NULL, "owner_id" integer, "is_merged_product" boolean NOT NULL DEFAULT false, "source_product_ids" integer array, "created_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_4c9fb58de893725258746385e16" UNIQUE ("name"), CONSTRAINT "PK_0806c755e0aca124e67c0cf6d7d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "stages" ("id" SERIAL NOT NULL, "name" character varying NOT NULL, "sequence" integer NOT NULL, "active" boolean NOT NULL DEFAULT true, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_62914e6926ccc4850911e89ee1a" UNIQUE ("name"), CONSTRAINT "PK_16efa0f8f5386328944769b9e6d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "users" ("id" SERIAL NOT NULL, "email" character varying NOT NULL, "password" text NOT NULL, "role" character varying NOT NULL, "name" text, "organization" text, "location" text, "account_type" text, "members" jsonb, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "users"`);
    await queryRunner.query(`DROP TABLE "stages"`);
    await queryRunner.query(`DROP TABLE "products"`);
    await queryRunner.query(`DROP TABLE "ownership_requests"`);
    await queryRunner.query(`DROP TABLE "batch_relations"`);
    await queryRunner.query(`DROP TABLE "batches"`);
    await queryRunner.query(`DROP TABLE "batch_events"`);
  }
}
