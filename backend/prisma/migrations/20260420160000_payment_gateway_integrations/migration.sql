DO $$
BEGIN
  CREATE TYPE "payment_gateway" AS ENUM ('FEDAPAY', 'KKIAPAY');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "transactions"
  ADD COLUMN IF NOT EXISTS "payment_gateway" "payment_gateway",
  ADD COLUMN IF NOT EXISTS "provider_transaction_id" VARCHAR(191),
  ADD COLUMN IF NOT EXISTS "provider_status" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "provider_payload" JSONB,
  ADD COLUMN IF NOT EXISTS "webhook_received_at" TIMESTAMP(6),
  ADD COLUMN IF NOT EXISTS "signature_verified" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "idx_transactions_payment_gateway"
  ON "transactions"("payment_gateway");

CREATE INDEX IF NOT EXISTS "idx_transactions_provider_transaction_id"
  ON "transactions"("provider_transaction_id");
