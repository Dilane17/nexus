-- CreateTable
CREATE TABLE "auto_invest_rules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "investor_id" UUID NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "max_amount" DECIMAL(15,2) NOT NULL,
    "max_duration" INTEGER NOT NULL,
    "min_hybrid_score" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT now(),

    CONSTRAINT "auto_invest_rules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "auto_invest_rules_investor_id_key" ON "auto_invest_rules"("investor_id");

-- AddForeignKey
ALTER TABLE "auto_invest_rules" ADD CONSTRAINT "auto_invest_rules_investor_id_fkey"
  FOREIGN KEY ("investor_id") REFERENCES "investors"("id") ON DELETE CASCADE ON UPDATE NO ACTION;
