import { config } from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma';
import * as bcrypt from 'bcrypt';

config({ path: `${__dirname}/../.env` });

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter } as any);

async function hash(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

async function main() {
  console.log('🌱 Démarrage du seed Nexus...\n');

  // ─── ADMIN ────────────────────────────────────────────────────────────────
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@nexus.bj' },
    update: {},
    create: {
      firstName: 'Kofi',
      lastName: 'Mensah',
      email: 'admin@nexus.bj',
      password: await hash('Admin123!@#'),
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.admin.upsert({
    where: { id: adminUser.id },
    update: {},
    create: { id: adminUser.id, role: 'SUPER_ADMIN', permissions: [] },
  });
  console.log('✅ Admin créé         :', adminUser.email);

  // ─── IMF STAFF ────────────────────────────────────────────────────────────
  const imfUser = await prisma.user.upsert({
    where: { email: 'imf@nexus.bj' },
    update: {},
    create: {
      firstName: 'Brice',
      lastName: 'Ahouansou',
      email: 'imf@nexus.bj',
      password: await hash('Imf123!@#'),
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.imfStaff.upsert({
    where: { id: imfUser.id },
    update: {},
    create: {
      id: imfUser.id,
      imf_name: 'CLCAM Bénin',
      license_number: 'CLCAM-BJ-2024-001',
      bceao_agreement_ref: 'BCEAO-AGR-2024-042',
    },
  });
  console.log('✅ IMF Staff créé     :', imfUser.email);

  // ─── AGENT ────────────────────────────────────────────────────────────────
  const agentUser = await prisma.user.upsert({
    where: { email: 'agent@nexus.bj' },
    update: {},
    create: {
      firstName: 'Théodore',
      lastName: 'Gbaguidi',
      email: 'agent@nexus.bj',
      password: await hash('Agent123!@#'),
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.agent.upsert({
    where: { id: agentUser.id },
    update: {},
    create: {
      id: agentUser.id,
      zone: 'Cadjehoun, Cotonou',
      agency_code: 'AGT-COT-001',
    },
  });
  console.log('✅ Agent créé         :', agentUser.email);

  // ─── INVESTISSEUR RETAIL ──────────────────────────────────────────────────
  const investorUser = await prisma.user.upsert({
    where: { email: 'investor@nexus.bj' },
    update: {},
    create: {
      firstName: 'Fernand',
      lastName: 'Adomou',
      email: 'investor@nexus.bj',
      password: await hash('Invest123!@#'),
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.investor.upsert({
    where: { id: investorUser.id },
    update: {},
    create: {
      id: investorUser.id,
      wallet_balance: 500000.0,
      risk_profile: 'BALANCED',
      investor_type: 'RETAIL',
      retailInvestor: {
        create: { max_investment_cap: 5000000.0, preferred_sectors: [] },
      },
    },
  });
  console.log('✅ Investisseur retail:', investorUser.email);

  // ─── INVESTISSEUR INSTITUTIONNEL ──────────────────────────────────────────
  const boadUser = await prisma.user.upsert({
    where: { email: 'boad@nexus.bj' },
    update: {},
    create: {
      firstName: 'Direction',
      lastName: 'BOAD',
      email: 'boad@nexus.bj',
      password: await hash('Boad123!@#'),
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.investor.upsert({
    where: { id: boadUser.id },
    update: {},
    create: {
      id: boadUser.id,
      wallet_balance: 5000000.0,
      investor_type: 'INSTITUTIONAL',
      institutionalInvestor: {
        create: {
          organization_name: 'Banque Ouest Africaine de Développement',
          regulatory_license: 'BOAD-LIC-2024',
        },
      },
    },
  });
  console.log('✅ Investisseur instit:', boadUser.email);

  // ─── EMPRUNTEUR 1 — bon profil ────────────────────────────────────────────
  const borrower1User = await prisma.user.upsert({
    where: { email: 'borrower1@nexus.bj' },
    update: {},
    create: {
      firstName: 'Celestine',
      lastName: 'Zannou',
      email: 'borrower1@nexus.bj',
      password: await hash('Borrow123!@#'),
      phone: '+22961000001',
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.borrower.upsert({
    where: { id: borrower1User.id },
    update: {},
    create: {
      id: borrower1User.id,
      mobile_money_number: '+22961000001',
      momo_provider: 'MTN_MOMO',
      credit_score: 85.0,
      tontine_score: 82.0,
      has_tontine_history: true,
    },
  });
  console.log('✅ Emprunteur 1 créé  :', borrower1User.email);

  // ─── EMPRUNTEUR 2 — profil moyen ─────────────────────────────────────────
  const borrower2User = await prisma.user.upsert({
    where: { email: 'borrower2@nexus.bj' },
    update: {},
    create: {
      firstName: 'Moussa',
      lastName: 'Seidou',
      email: 'borrower2@nexus.bj',
      password: await hash('Borrow123!@#'),
      phone: '+22961000002',
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'VALIDATED',
    },
  });
  await prisma.borrower.upsert({
    where: { id: borrower2User.id },
    update: {},
    create: {
      id: borrower2User.id,
      mobile_money_number: '+22961000002',
      momo_provider: 'MOOV_FLOOZ',
      credit_score: 67.5,
      tontine_score: 0.0,
      has_tontine_history: false,
    },
  });
  console.log('✅ Emprunteur 2 créé  :', borrower2User.email);

  // ─── EMPRUNTEUR 3 — KYC en cours ─────────────────────────────────────────
  const borrower3User = await prisma.user.upsert({
    where: { email: 'borrower3@nexus.bj' },
    update: {},
    create: {
      firstName: 'Adjoua',
      lastName: 'Akakpo',
      email: 'borrower3@nexus.bj',
      password: await hash('Borrow123!@#'),
      phone: '+22961000003',
      status: 'ACTIVE',
      isEmailVerified: true,
      kyc_status: 'SESSION2_DONE',
      kycSubmittedAt: new Date(),
    },
  });
  await prisma.borrower.upsert({
    where: { id: borrower3User.id },
    update: {},
    create: {
      id: borrower3User.id,
      mobile_money_number: '+22961000003',
      momo_provider: 'MTN_MOMO',
      credit_score: 0.0,
    },
  });
  console.log('✅ Emprunteur 3 créé  :', borrower3User.email);

  // ─── GROUPE TONTINE ───────────────────────────────────────────────────────
  const tontineGroup = await prisma.tontineGroup.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Tontine Cadjehoun',
      leader_user_id: borrower1User.id,
      leader_phone: '+22961000001',
      monthly_contribution: 25000,
      member_count: 4,
      completed_cycles: 3,
      status: 'ACTIVE',
    },
  });
  // Celestine membre de son propre groupe
  await prisma.tontineMember.upsert({
    where: {
      group_id_borrower_id: {
        group_id: tontineGroup.id,
        borrower_id: borrower1User.id,
      },
    },
    update: {},
    create: { group_id: tontineGroup.id, borrower_id: borrower1User.id },
  });
  console.log('✅ Tontine créée      :', tontineGroup.name);

  // ─── PRÊT 1 — FUNDING ────────────────────────────────────────────────────
  const loan1 = await prisma.loan.upsert({
    where: { id: '00000000-0000-0000-0000-000000000010' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000010',
      borrower_id: borrower1User.id,
      amount: 300000,
      interest_rate: 0.14,
      duration_months: 6,
      status: 'FUNDING',
      monthly_installment: 57000,
      outstanding_balance: 300000,
      purpose: 'Achat stock mercerie Dantokpa',
      validated_by_imf: true,
      imf_validated_by: imfUser.id,
    },
  });
  console.log('✅ Prêt 1 créé        : FUNDING —', loan1.purpose);

  // ─── PRÊT 2 — PENDING_IMF ────────────────────────────────────────────────
  const loan2 = await prisma.loan.upsert({
    where: { id: '00000000-0000-0000-0000-000000000011' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000011',
      borrower_id: borrower2User.id,
      amount: 150000,
      interest_rate: 0.16,
      duration_months: 3,
      status: 'PENDING_IMF',
      monthly_installment: 58000,
      outstanding_balance: 150000,
      purpose: 'Fonds de roulement commerce',
    },
  });
  console.log('✅ Prêt 2 créé        : PENDING_IMF —', loan2.purpose);

  // ─── INVESTISSEMENT ───────────────────────────────────────────────────────
  const maturityDate = new Date();
  maturityDate.setMonth(maturityDate.getMonth() + 6);

  const investment = await prisma.investment.upsert({
    where: { id: '00000000-0000-0000-0000-000000000020' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000020',
      investor_id: investorUser.id,
      loan_id: loan1.id,
      amount: 150000,
      expected_return: 163500,
      status: 'ACTIVE',
      is_guaranteed: true,
      guarantee_tier: 1,
      maturity_date: maturityDate,
    },
  });
  console.log('✅ Investissement créé:', investment.amount.toString(), 'XOF → prêt Celestine');

  // ─── RÉSUMÉ ───────────────────────────────────────────────────────────────
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Seed terminé — comptes créés :

  admin@nexus.bj       / Admin123!@#
  imf@nexus.bj         / Imf123!@#
  agent@nexus.bj       / Agent123!@#
  investor@nexus.bj    / Invest123!@#
  boad@nexus.bj        / Boad123!@#
  borrower1@nexus.bj   / Borrow123!@#
  borrower2@nexus.bj   / Borrow123!@#
  borrower3@nexus.bj   / Borrow123!@#

  Tontine  : Tontine Cadjehoun (4 membres, 3 cycles)
  Prêt 1   : 300 000 XOF — FUNDING (Celestine Zannou)
  Prêt 2   : 150 000 XOF — PENDING_IMF (Moussa Seidou)
  Invest   : 150 000 XOF → Prêt 1 (Fernand Adomou)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`);
}

main()
  .catch((e) => {
    console.error('❌ Seed échoué :', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
