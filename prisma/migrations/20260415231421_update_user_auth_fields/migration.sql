-- AlterTable
ALTER TABLE "users" DROP COLUMN "full_name",
ADD COLUMN     "avatar" TEXT,
ADD COLUMN     "city" TEXT,
ADD COLUMN     "district" TEXT,
ADD COLUMN     "firstName" VARCHAR(150) NOT NULL DEFAULT '',
ADD COLUMN     "googleId" TEXT,
ADD COLUMN     "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isPhoneVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "lastName" VARCHAR(150) NOT NULL DEFAULT '',
ADD COLUMN     "otpCode" TEXT,
ADD COLUMN     "otpExpiry" TIMESTAMP(3),
ADD COLUMN     "otpType" TEXT;

-- Remove temporary defaults after backfill
ALTER TABLE "users" ALTER COLUMN "firstName" DROP DEFAULT;
ALTER TABLE "users" ALTER COLUMN "lastName" DROP DEFAULT;

-- CreateIndex
CREATE UNIQUE INDEX "users_googleId_key" ON "users"("googleId");
