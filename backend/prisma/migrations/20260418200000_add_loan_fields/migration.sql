-- AlterTable
ALTER TABLE "loans" ADD COLUMN "purpose" VARCHAR(500);
ALTER TABLE "loans" ADD COLUMN "rejection_reason" VARCHAR(500);
ALTER TABLE "loans" ADD COLUMN "created_at" TIMESTAMP(6) NOT NULL DEFAULT now();
