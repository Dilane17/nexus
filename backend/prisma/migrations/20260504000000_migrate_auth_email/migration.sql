-- Migration: auth phone+SMS → email+password
-- phone devient nullable, email devient requis, isPhoneVerified supprimé

-- Rendre phone nullable
ALTER TABLE "users" ALTER COLUMN "phone" DROP NOT NULL;

-- Backfill des anciens comptes créés avec auth téléphone uniquement
UPDATE "users"
SET "email" = CONCAT('legacy+', "id"::text, '@nexus.local')
WHERE "email" IS NULL;

-- Rendre email NOT NULL (les users existants de dev doivent avoir un email)
ALTER TABLE "users" ALTER COLUMN "email" SET NOT NULL;

-- Supprimer isPhoneVerified
ALTER TABLE "users" DROP COLUMN IF EXISTS "isPhoneVerified";
