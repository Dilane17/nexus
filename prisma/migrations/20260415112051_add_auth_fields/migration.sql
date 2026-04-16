-- CreateEnum
CREATE TYPE "admin_role" AS ENUM ('SUPER_ADMIN', 'OPERATIONS', 'COMPLIANCE', 'SUPPORT');

-- CreateEnum
CREATE TYPE "investment_status" AS ENUM ('ACTIVE', 'COMPLETED', 'DEFAULTED', 'GUARANTEED');

-- CreateEnum
CREATE TYPE "investor_type" AS ENUM ('RETAIL', 'INSTITUTIONAL');

-- CreateEnum
CREATE TYPE "kyc_status" AS ENUM ('NOT_STARTED', 'SESSION1_DONE', 'SESSION2_DONE', 'VALIDATED', 'REJECTED');

-- CreateEnum
CREATE TYPE "loan_status" AS ENUM ('PENDING_IMF', 'FUNDING', 'ACTIVE', 'OVERDUE', 'GUARANTEE_ACTIVATED', 'REPURCHASED', 'REPAID', 'CANCELLED', 'RESTRUCTURED');

-- CreateEnum
CREATE TYPE "momo_provider" AS ENUM ('MTN_MOMO', 'MOOV_FLOOZ');

-- CreateEnum
CREATE TYPE "risk_profile" AS ENUM ('CONSERVATIVE', 'BALANCED', 'DYNAMIC');

-- CreateEnum
CREATE TYPE "tontine_status" AS ENUM ('PENDING', 'ACTIVE', 'COMPLETED', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "transaction_status" AS ENUM ('PENDING', 'CONFIRMED', 'RECONCILED', 'FAILED', 'PHANTOM_DETECTED');

-- CreateEnum
CREATE TYPE "transaction_type" AS ENUM ('INVESTOR_DEPOSIT', 'INVESTOR_WITHDRAWAL', 'LOAN_DISBURSEMENT', 'LOAN_REPAYMENT', 'PLATFORM_COMMISSION', 'GUARANTEE_ACTIVATION', 'IMF_REPURCHASE', 'AGENT_COMMISSION');

-- CreateEnum
CREATE TYPE "user_status" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'BLOCKED');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "full_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "email" VARCHAR(200),
    "status" "user_status" NOT NULL DEFAULT 'PENDING',
    "kyc_status" "kyc_status" NOT NULL DEFAULT 'NOT_STARTED',
    "kyc_document_url" VARCHAR(500),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_login" TIMESTAMP(6),
    "password" TEXT,
    "refresh_token" TEXT,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "investors" (
    "id" UUID NOT NULL,
    "wallet_balance" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "total_invested" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "total_returns" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "risk_profile" "risk_profile" NOT NULL DEFAULT 'BALANCED',
    "investor_type" "investor_type" NOT NULL DEFAULT 'RETAIL',

    CONSTRAINT "investors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "retail_investors" (
    "id" UUID NOT NULL,
    "max_investment_cap" DECIMAL(15,2) NOT NULL DEFAULT 5000000.00,
    "preferred_sectors" TEXT[],

    CONSTRAINT "retail_investors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institutional_investors" (
    "id" UUID NOT NULL,
    "organization_name" VARCHAR(200) NOT NULL,
    "regulatory_license" VARCHAR(100) NOT NULL,
    "max_exposure_ratio" DECIMAL(5,4) NOT NULL DEFAULT 0.3000,

    CONSTRAINT "institutional_investors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "borrowers" (
    "id" UUID NOT NULL,
    "credit_score" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    "tontine_score" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    "mobile_money_number" VARCHAR(20) NOT NULL,
    "momo_provider" "momo_provider" NOT NULL,
    "has_tontine_history" BOOLEAN NOT NULL DEFAULT false,
    "default_count" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "borrowers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admins" (
    "id" UUID NOT NULL,
    "role" "admin_role" NOT NULL DEFAULT 'SUPPORT',
    "permissions" TEXT[] DEFAULT ARRAY[]::TEXT[],

    CONSTRAINT "admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agents" (
    "id" UUID NOT NULL,
    "zone" VARCHAR(100) NOT NULL,
    "agency_code" VARCHAR(20) NOT NULL,
    "commission_rate" DECIMAL(4,3) NOT NULL DEFAULT 0.005,
    "clients_assisted" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "agents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "imf_staff" (
    "id" UUID NOT NULL,
    "imf_name" VARCHAR(200) NOT NULL,
    "license_number" VARCHAR(100) NOT NULL,
    "bceao_agreement_ref" VARCHAR(100) NOT NULL,

    CONSTRAINT "imf_staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "escrow_wallet" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "total_balance" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "investor_funds" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "pending_disbursements" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "locked_for_guarantee" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "platform_fees" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "third_party_manager" VARCHAR(200) NOT NULL,
    "last_audit_date" DATE,

    CONSTRAINT "escrow_wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "platform_wallet" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "commission_balance" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "operating_funds" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "last_withdrawal_date" TIMESTAMP(6),

    CONSTRAINT "platform_wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "loans" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "borrower_id" UUID NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "interest_rate" DECIMAL(5,4) NOT NULL,
    "duration_months" INTEGER NOT NULL,
    "status" "loan_status" NOT NULL DEFAULT 'PENDING_IMF',
    "monthly_installment" DECIMAL(15,2) NOT NULL,
    "outstanding_balance" DECIMAL(15,2) NOT NULL,
    "days_overdue" INTEGER NOT NULL DEFAULT 0,
    "validated_by_imf" BOOLEAN NOT NULL DEFAULT false,
    "disbursed_at" TIMESTAMP(6),
    "next_due_date" DATE,
    "imf_validated_by" UUID,

    CONSTRAINT "loans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "investments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "investor_id" UUID NOT NULL,
    "loan_id" UUID NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "expected_return" DECIMAL(15,2) NOT NULL,
    "actual_return" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "status" "investment_status" NOT NULL DEFAULT 'ACTIVE',
    "is_guaranteed" BOOLEAN NOT NULL DEFAULT true,
    "guarantee_tier" INTEGER NOT NULL DEFAULT 1,
    "maturity_date" DATE NOT NULL,

    CONSTRAINT "investments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "transaction_type" NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "status" "transaction_status" NOT NULL DEFAULT 'PENDING',
    "momo_reference" VARCHAR(100),
    "momo_provider" "momo_provider",
    "initiated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "confirmed_at" TIMESTAMP(6),
    "reconciled_at" TIMESTAMP(6),
    "is_reconciled" BOOLEAN NOT NULL DEFAULT false,
    "failure_reason" VARCHAR(300),
    "created_by" UUID NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tontine_groups" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(150) NOT NULL,
    "leader_user_id" UUID NOT NULL,
    "leader_phone" VARCHAR(20) NOT NULL,
    "member_count" INTEGER NOT NULL DEFAULT 1,
    "monthly_contribution" DECIMAL(15,2) NOT NULL,
    "completed_cycles" INTEGER NOT NULL DEFAULT 0,
    "status" "tontine_status" NOT NULL DEFAULT 'PENDING',

    CONSTRAINT "tontine_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tontine_members" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "group_id" UUID NOT NULL,
    "borrower_id" UUID NOT NULL,
    "joined_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tontine_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tontine_cycles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "group_id" UUID NOT NULL,
    "cycle_number" INTEGER NOT NULL,
    "start_date" DATE NOT NULL,
    "end_date" DATE NOT NULL,
    "total_collected" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "is_complete" BOOLEAN NOT NULL DEFAULT false,
    "beneficiary_id" UUID NOT NULL,
    "members_paid" INTEGER NOT NULL DEFAULT 0,
    "members_defaulted" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "tontine_cycles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guarantee_fund" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "total_capital" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "active_portfolio_value" DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    "coverage_ratio" DECIMAL(5,4) NOT NULL DEFAULT 0.00,
    "min_threshold" DECIMAL(5,4) NOT NULL DEFAULT 0.0300,
    "target_threshold" DECIMAL(5,4) NOT NULL DEFAULT 0.0500,
    "suspension_active" BOOLEAN NOT NULL DEFAULT false,
    "last_reconstitution_date" DATE,

    CONSTRAINT "guarantee_fund_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guarantee_fund_investments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "fund_id" UUID NOT NULL,
    "investment_id" UUID NOT NULL,
    "covered_amount" DECIMAL(15,2) NOT NULL,
    "activated_at" TIMESTAMP(6),
    "is_activated" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "guarantee_fund_investments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scoring_engine" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "momo_weight" DECIMAL(3,2) NOT NULL DEFAULT 0.40,
    "tontine_weight" DECIMAL(3,2) NOT NULL DEFAULT 0.35,
    "imf_weight" DECIMAL(3,2) NOT NULL DEFAULT 0.25,
    "warning_signal_days" INTEGER NOT NULL DEFAULT 45,

    CONSTRAINT "scoring_engine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "borrower_scores" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "borrower_id" UUID NOT NULL,
    "momo_score" DECIMAL(5,2) NOT NULL,
    "tontine_score" DECIMAL(5,2) NOT NULL,
    "imf_score" DECIMAL(5,2) NOT NULL,
    "hybrid_score" DECIMAL(5,2) NOT NULL,
    "computed_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "borrower_scores_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "idx_users_kyc_status" ON "users"("kyc_status");

-- CreateIndex
CREATE INDEX "idx_users_phone" ON "users"("phone");

-- CreateIndex
CREATE INDEX "idx_users_status" ON "users"("status");

-- CreateIndex
CREATE UNIQUE INDEX "borrowers_mobile_money_number_key" ON "borrowers"("mobile_money_number");

-- CreateIndex
CREATE INDEX "idx_borrowers_credit_score" ON "borrowers"("credit_score");

-- CreateIndex
CREATE UNIQUE INDEX "agents_agency_code_key" ON "agents"("agency_code");

-- CreateIndex
CREATE UNIQUE INDEX "imf_staff_license_number_key" ON "imf_staff"("license_number");

-- CreateIndex
CREATE INDEX "idx_loans_borrower_id" ON "loans"("borrower_id");

-- CreateIndex
CREATE INDEX "idx_loans_days_overdue" ON "loans"("days_overdue");

-- CreateIndex
CREATE INDEX "idx_loans_status" ON "loans"("status");

-- CreateIndex
CREATE INDEX "idx_investments_investor_id" ON "investments"("investor_id");

-- CreateIndex
CREATE INDEX "idx_investments_loan_id" ON "investments"("loan_id");

-- CreateIndex
CREATE INDEX "idx_investments_status" ON "investments"("status");

-- CreateIndex
CREATE UNIQUE INDEX "transactions_momo_reference_key" ON "transactions"("momo_reference");

-- CreateIndex
CREATE INDEX "idx_transactions_created_by" ON "transactions"("created_by");

-- CreateIndex
CREATE INDEX "idx_transactions_momo_reference" ON "transactions"("momo_reference");

-- CreateIndex
CREATE INDEX "idx_transactions_status" ON "transactions"("status");

-- CreateIndex
CREATE INDEX "idx_transactions_type" ON "transactions"("type");

-- CreateIndex
CREATE INDEX "idx_tontine_groups_status" ON "tontine_groups"("status");

-- CreateIndex
CREATE UNIQUE INDEX "tontine_members_group_id_borrower_id_key" ON "tontine_members"("group_id", "borrower_id");

-- CreateIndex
CREATE INDEX "idx_tontine_cycles_group_id" ON "tontine_cycles"("group_id");

-- CreateIndex
CREATE UNIQUE INDEX "tontine_cycles_group_id_cycle_number_key" ON "tontine_cycles"("group_id", "cycle_number");

-- CreateIndex
CREATE UNIQUE INDEX "guarantee_fund_investments_fund_id_investment_id_key" ON "guarantee_fund_investments"("fund_id", "investment_id");

-- AddForeignKey
ALTER TABLE "investors" ADD CONSTRAINT "investors_id_fkey" FOREIGN KEY ("id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "retail_investors" ADD CONSTRAINT "retail_investors_id_fkey" FOREIGN KEY ("id") REFERENCES "investors"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "institutional_investors" ADD CONSTRAINT "institutional_investors_id_fkey" FOREIGN KEY ("id") REFERENCES "investors"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "borrowers" ADD CONSTRAINT "borrowers_id_fkey" FOREIGN KEY ("id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "admins" ADD CONSTRAINT "admins_id_fkey" FOREIGN KEY ("id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "agents" ADD CONSTRAINT "agents_id_fkey" FOREIGN KEY ("id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "imf_staff" ADD CONSTRAINT "imf_staff_id_fkey" FOREIGN KEY ("id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_borrower_id_fkey" FOREIGN KEY ("borrower_id") REFERENCES "borrowers"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_imf_validated_by_fkey" FOREIGN KEY ("imf_validated_by") REFERENCES "imf_staff"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "investments" ADD CONSTRAINT "investments_investor_id_fkey" FOREIGN KEY ("investor_id") REFERENCES "investors"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "investments" ADD CONSTRAINT "investments_loan_id_fkey" FOREIGN KEY ("loan_id") REFERENCES "loans"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tontine_groups" ADD CONSTRAINT "tontine_groups_leader_user_id_fkey" FOREIGN KEY ("leader_user_id") REFERENCES "borrowers"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tontine_members" ADD CONSTRAINT "tontine_members_borrower_id_fkey" FOREIGN KEY ("borrower_id") REFERENCES "borrowers"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tontine_members" ADD CONSTRAINT "tontine_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "tontine_groups"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tontine_cycles" ADD CONSTRAINT "tontine_cycles_beneficiary_id_fkey" FOREIGN KEY ("beneficiary_id") REFERENCES "borrowers"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tontine_cycles" ADD CONSTRAINT "tontine_cycles_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "tontine_groups"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "guarantee_fund_investments" ADD CONSTRAINT "guarantee_fund_investments_fund_id_fkey" FOREIGN KEY ("fund_id") REFERENCES "guarantee_fund"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "guarantee_fund_investments" ADD CONSTRAINT "guarantee_fund_investments_investment_id_fkey" FOREIGN KEY ("investment_id") REFERENCES "investments"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "borrower_scores" ADD CONSTRAINT "borrower_scores_borrower_id_fkey" FOREIGN KEY ("borrower_id") REFERENCES "borrowers"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
