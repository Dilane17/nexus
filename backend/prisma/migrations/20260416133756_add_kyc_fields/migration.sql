
-- AlterTable
ALTER TABLE "users" ADD COLUMN     "kycDocumentType" TEXT,
ADD COLUMN     "kycDocumentUrl" TEXT,
ADD COLUMN     "kycIncomeSource" TEXT,
ADD COLUMN     "kycMomoStatement" TEXT,
ADD COLUMN     "kycMonthlyIncome" DECIMAL(65,30),
ADD COLUMN     "kycRejectionReason" TEXT,
ADD COLUMN     "kycSubmittedAt" TIMESTAMP(3),
ADD COLUMN     "kycValidatedAt" TIMESTAMP(3),
ADD COLUMN     "kycValidatedBy" TEXT;

