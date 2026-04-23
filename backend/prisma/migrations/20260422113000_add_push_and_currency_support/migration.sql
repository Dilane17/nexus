CREATE TYPE "currency_code" AS ENUM ('XOF', 'USD', 'EUR', 'NGN');

ALTER TABLE "users"
ADD COLUMN "preferred_currency" "currency_code" NOT NULL DEFAULT 'XOF',
ADD COLUMN "push_tokens" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

ALTER TABLE "loans"
ADD COLUMN "currency" "currency_code" NOT NULL DEFAULT 'XOF';

ALTER TABLE "investments"
ADD COLUMN "currency" "currency_code" NOT NULL DEFAULT 'XOF';

ALTER TABLE "transactions"
ADD COLUMN "currency" "currency_code" NOT NULL DEFAULT 'XOF';
