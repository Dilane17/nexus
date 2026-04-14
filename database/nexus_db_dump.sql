--
-- PostgreSQL database dump
--

\restrict QNpdhQrzUtFp7uCVm7b6fG7zToAFJ7TMtTo7VfLU36n5jAc6HBLUls0DRbynBSd

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: admin_role; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.admin_role AS ENUM (
    'SUPER_ADMIN',
    'OPERATIONS',
    'COMPLIANCE',
    'SUPPORT'
);


ALTER TYPE public.admin_role OWNER TO nexus_user;

--
-- Name: TYPE admin_role; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.admin_role IS 'Rôle administrateur — détermine les permissions RBAC';


--
-- Name: investment_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.investment_status AS ENUM (
    'ACTIVE',
    'COMPLETED',
    'DEFAULTED',
    'GUARANTEED'
);


ALTER TYPE public.investment_status OWNER TO nexus_user;

--
-- Name: TYPE investment_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.investment_status IS 'État d un investissement dans un prêt';


--
-- Name: investor_type; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.investor_type AS ENUM (
    'RETAIL',
    'INSTITUTIONAL'
);


ALTER TYPE public.investor_type OWNER TO nexus_user;

--
-- Name: TYPE investor_type; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.investor_type IS 'RETAIL plafonné à 5M FCFA — INSTITUTIONAL sans plafond';


--
-- Name: kyc_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.kyc_status AS ENUM (
    'NOT_STARTED',
    'SESSION1_DONE',
    'SESSION2_DONE',
    'VALIDATED',
    'REJECTED'
);


ALTER TYPE public.kyc_status OWNER TO nexus_user;

--
-- Name: TYPE kyc_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.kyc_status IS 'Progression du KYC en 3 sessions — VALIDATED requis avant toute transaction';


--
-- Name: loan_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.loan_status AS ENUM (
    'PENDING_IMF',
    'FUNDING',
    'ACTIVE',
    'OVERDUE',
    'GUARANTEE_ACTIVATED',
    'REPURCHASED',
    'REPAID',
    'CANCELLED',
    'RESTRUCTURED'
);


ALTER TYPE public.loan_status OWNER TO nexus_user;

--
-- Name: TYPE loan_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.loan_status IS 'Cycle de vie complet d un prêt — 9 états possibles';


--
-- Name: momo_provider; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.momo_provider AS ENUM (
    'MTN_MOMO',
    'MOOV_FLOOZ'
);


ALTER TYPE public.momo_provider OWNER TO nexus_user;

--
-- Name: TYPE momo_provider; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.momo_provider IS 'Provider Mobile Money — détermine la passerelle FedaPay ou KKiaPay';


--
-- Name: risk_profile; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.risk_profile AS ENUM (
    'CONSERVATIVE',
    'BALANCED',
    'DYNAMIC'
);


ALTER TYPE public.risk_profile OWNER TO nexus_user;

--
-- Name: TYPE risk_profile; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.risk_profile IS 'Profil de risque investisseur — détermine l algorithme Auto-Invest';


--
-- Name: tontine_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.tontine_status AS ENUM (
    'PENDING',
    'ACTIVE',
    'COMPLETED',
    'SUSPENDED'
);


ALTER TYPE public.tontine_status OWNER TO nexus_user;

--
-- Name: TYPE tontine_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.tontine_status IS 'État d un groupe tontine — PENDING jusqu à 2 membres minimum';


--
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.transaction_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'RECONCILED',
    'FAILED',
    'PHANTOM_DETECTED'
);


ALTER TYPE public.transaction_status OWNER TO nexus_user;

--
-- Name: TYPE transaction_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.transaction_status IS 'État d une transaction — PHANTOM_DETECTED pour les anomalies MoMo';


--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.transaction_type AS ENUM (
    'INVESTOR_DEPOSIT',
    'INVESTOR_WITHDRAWAL',
    'LOAN_DISBURSEMENT',
    'LOAN_REPAYMENT',
    'PLATFORM_COMMISSION',
    'GUARANTEE_ACTIVATION',
    'IMF_REPURCHASE',
    'AGENT_COMMISSION'
);


ALTER TYPE public.transaction_type OWNER TO nexus_user;

--
-- Name: TYPE transaction_type; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.transaction_type IS 'Nature de chaque mouvement de fonds dans le système';


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: nexus_user
--

CREATE TYPE public.user_status AS ENUM (
    'PENDING',
    'ACTIVE',
    'SUSPENDED',
    'BLOCKED'
);


ALTER TYPE public.user_status OWNER TO nexus_user;

--
-- Name: TYPE user_status; Type: COMMENT; Schema: public; Owner: nexus_user
--

COMMENT ON TYPE public.user_status IS 'Statut du cycle de vie d un utilisateur — PENDING par défaut à la création';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.admins (
    id uuid NOT NULL,
    role public.admin_role DEFAULT 'SUPPORT'::public.admin_role NOT NULL,
    permissions text[] DEFAULT '{}'::text[] NOT NULL
);


ALTER TABLE public.admins OWNER TO nexus_user;

--
-- Name: agents; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.agents (
    id uuid NOT NULL,
    zone character varying(100) NOT NULL,
    agency_code character varying(20) NOT NULL,
    commission_rate numeric(4,3) DEFAULT 0.005 NOT NULL,
    clients_assisted integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.agents OWNER TO nexus_user;

--
-- Name: borrower_scores; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.borrower_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    borrower_id uuid NOT NULL,
    momo_score numeric(5,2) NOT NULL,
    tontine_score numeric(5,2) NOT NULL,
    imf_score numeric(5,2) NOT NULL,
    hybrid_score numeric(5,2) NOT NULL,
    computed_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT borrower_scores_hybrid_score_check CHECK (((hybrid_score >= (0)::numeric) AND (hybrid_score <= (100)::numeric))),
    CONSTRAINT borrower_scores_imf_score_check CHECK (((imf_score >= (0)::numeric) AND (imf_score <= (100)::numeric))),
    CONSTRAINT borrower_scores_momo_score_check CHECK (((momo_score >= (0)::numeric) AND (momo_score <= (100)::numeric))),
    CONSTRAINT borrower_scores_tontine_score_check CHECK (((tontine_score >= (0)::numeric) AND (tontine_score <= (100)::numeric)))
);


ALTER TABLE public.borrower_scores OWNER TO nexus_user;

--
-- Name: borrowers; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.borrowers (
    id uuid NOT NULL,
    credit_score numeric(5,2) DEFAULT 0.00 NOT NULL,
    tontine_score numeric(5,2) DEFAULT 0.00 NOT NULL,
    mobile_money_number character varying(20) NOT NULL,
    momo_provider public.momo_provider NOT NULL,
    has_tontine_history boolean DEFAULT false NOT NULL,
    default_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT borrowers_credit_score_check CHECK (((credit_score >= (0)::numeric) AND (credit_score <= (100)::numeric))),
    CONSTRAINT borrowers_default_count_check CHECK ((default_count >= 0)),
    CONSTRAINT borrowers_tontine_score_check CHECK (((tontine_score >= (0)::numeric) AND (tontine_score <= (100)::numeric)))
);


ALTER TABLE public.borrowers OWNER TO nexus_user;

--
-- Name: escrow_wallet; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.escrow_wallet (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    total_balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    investor_funds numeric(15,2) DEFAULT 0.00 NOT NULL,
    pending_disbursements numeric(15,2) DEFAULT 0.00 NOT NULL,
    locked_for_guarantee numeric(15,2) DEFAULT 0.00 NOT NULL,
    platform_fees numeric(15,2) DEFAULT 0.00 NOT NULL,
    third_party_manager character varying(200) NOT NULL,
    last_audit_date date,
    CONSTRAINT escrow_wallet_investor_funds_check CHECK ((investor_funds >= (0)::numeric)),
    CONSTRAINT escrow_wallet_pending_disbursements_check CHECK ((pending_disbursements >= (0)::numeric)),
    CONSTRAINT escrow_wallet_total_balance_check CHECK ((total_balance >= (0)::numeric))
);


ALTER TABLE public.escrow_wallet OWNER TO nexus_user;

--
-- Name: guarantee_fund; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.guarantee_fund (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    total_capital numeric(15,2) DEFAULT 0.00 NOT NULL,
    active_portfolio_value numeric(15,2) DEFAULT 0.00 NOT NULL,
    coverage_ratio numeric(5,4) DEFAULT 0.00 NOT NULL,
    min_threshold numeric(5,4) DEFAULT 0.0300 NOT NULL,
    target_threshold numeric(5,4) DEFAULT 0.0500 NOT NULL,
    suspension_active boolean DEFAULT false NOT NULL,
    last_reconstitution_date date,
    CONSTRAINT guarantee_fund_total_capital_check CHECK ((total_capital >= (0)::numeric))
);


ALTER TABLE public.guarantee_fund OWNER TO nexus_user;

--
-- Name: guarantee_fund_investments; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.guarantee_fund_investments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fund_id uuid NOT NULL,
    investment_id uuid NOT NULL,
    covered_amount numeric(15,2) NOT NULL,
    activated_at timestamp without time zone,
    is_activated boolean DEFAULT false NOT NULL
);


ALTER TABLE public.guarantee_fund_investments OWNER TO nexus_user;

--
-- Name: imf_staff; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.imf_staff (
    id uuid NOT NULL,
    imf_name character varying(200) NOT NULL,
    license_number character varying(100) NOT NULL,
    bceao_agreement_ref character varying(100) NOT NULL
);


ALTER TABLE public.imf_staff OWNER TO nexus_user;

--
-- Name: institutional_investors; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.institutional_investors (
    id uuid NOT NULL,
    organization_name character varying(200) NOT NULL,
    regulatory_license character varying(100) NOT NULL,
    max_exposure_ratio numeric(5,4) DEFAULT 0.3000 NOT NULL
);


ALTER TABLE public.institutional_investors OWNER TO nexus_user;

--
-- Name: investments; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.investments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    investor_id uuid NOT NULL,
    loan_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    expected_return numeric(15,2) NOT NULL,
    actual_return numeric(15,2) DEFAULT 0.00 NOT NULL,
    status public.investment_status DEFAULT 'ACTIVE'::public.investment_status NOT NULL,
    is_guaranteed boolean DEFAULT true NOT NULL,
    guarantee_tier integer DEFAULT 1 NOT NULL,
    maturity_date date NOT NULL,
    CONSTRAINT investments_amount_check CHECK ((amount >= (5000)::numeric)),
    CONSTRAINT investments_guarantee_tier_check CHECK ((guarantee_tier = ANY (ARRAY[1, 2, 3])))
);


ALTER TABLE public.investments OWNER TO nexus_user;

--
-- Name: investors; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.investors (
    id uuid NOT NULL,
    wallet_balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    total_invested numeric(15,2) DEFAULT 0.00 NOT NULL,
    total_returns numeric(15,2) DEFAULT 0.00 NOT NULL,
    risk_profile public.risk_profile DEFAULT 'BALANCED'::public.risk_profile NOT NULL,
    investor_type public.investor_type DEFAULT 'RETAIL'::public.investor_type NOT NULL,
    CONSTRAINT investors_wallet_balance_check CHECK ((wallet_balance >= (0)::numeric))
);


ALTER TABLE public.investors OWNER TO nexus_user;

--
-- Name: loans; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.loans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    borrower_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    interest_rate numeric(5,4) NOT NULL,
    duration_months integer NOT NULL,
    status public.loan_status DEFAULT 'PENDING_IMF'::public.loan_status NOT NULL,
    monthly_installment numeric(15,2) NOT NULL,
    outstanding_balance numeric(15,2) NOT NULL,
    days_overdue integer DEFAULT 0 NOT NULL,
    validated_by_imf boolean DEFAULT false NOT NULL,
    disbursed_at timestamp without time zone,
    next_due_date date,
    imf_validated_by uuid,
    CONSTRAINT loans_amount_check CHECK (((amount >= (25000)::numeric) AND (amount <= (500000)::numeric))),
    CONSTRAINT loans_days_overdue_check CHECK ((days_overdue >= 0)),
    CONSTRAINT loans_duration_months_check CHECK ((duration_months = ANY (ARRAY[3, 6, 9, 12]))),
    CONSTRAINT loans_interest_rate_check CHECK ((interest_rate <= 0.18))
);


ALTER TABLE public.loans OWNER TO nexus_user;

--
-- Name: platform_wallet; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.platform_wallet (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    commission_balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    operating_funds numeric(15,2) DEFAULT 0.00 NOT NULL,
    last_withdrawal_date timestamp without time zone,
    CONSTRAINT platform_wallet_commission_balance_check CHECK ((commission_balance >= (0)::numeric)),
    CONSTRAINT platform_wallet_operating_funds_check CHECK ((operating_funds >= (0)::numeric))
);


ALTER TABLE public.platform_wallet OWNER TO nexus_user;

--
-- Name: retail_investors; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.retail_investors (
    id uuid NOT NULL,
    max_investment_cap numeric(15,2) DEFAULT 5000000.00 NOT NULL,
    preferred_sectors text[]
);


ALTER TABLE public.retail_investors OWNER TO nexus_user;

--
-- Name: scoring_engine; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.scoring_engine (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    momo_weight numeric(3,2) DEFAULT 0.40 NOT NULL,
    tontine_weight numeric(3,2) DEFAULT 0.35 NOT NULL,
    imf_weight numeric(3,2) DEFAULT 0.25 NOT NULL,
    warning_signal_days integer DEFAULT 45 NOT NULL,
    CONSTRAINT weights_sum CHECK ((((momo_weight + tontine_weight) + imf_weight) = 1.00))
);


ALTER TABLE public.scoring_engine OWNER TO nexus_user;

--
-- Name: tontine_cycles; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.tontine_cycles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    cycle_number integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_collected numeric(15,2) DEFAULT 0.00 NOT NULL,
    is_complete boolean DEFAULT false NOT NULL,
    beneficiary_id uuid NOT NULL,
    members_paid integer DEFAULT 0 NOT NULL,
    members_defaulted integer DEFAULT 0 NOT NULL,
    CONSTRAINT tontine_cycles_cycle_number_check CHECK ((cycle_number > 0))
);


ALTER TABLE public.tontine_cycles OWNER TO nexus_user;

--
-- Name: tontine_groups; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.tontine_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    leader_user_id uuid NOT NULL,
    leader_phone character varying(20) NOT NULL,
    member_count integer DEFAULT 1 NOT NULL,
    monthly_contribution numeric(15,2) NOT NULL,
    completed_cycles integer DEFAULT 0 NOT NULL,
    status public.tontine_status DEFAULT 'PENDING'::public.tontine_status NOT NULL,
    CONSTRAINT tontine_groups_member_count_check CHECK ((member_count >= 2)),
    CONSTRAINT tontine_groups_monthly_contribution_check CHECK ((monthly_contribution > (0)::numeric))
);


ALTER TABLE public.tontine_groups OWNER TO nexus_user;

--
-- Name: tontine_members; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.tontine_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    borrower_id uuid NOT NULL,
    joined_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tontine_members OWNER TO nexus_user;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.transaction_type NOT NULL,
    amount numeric(15,2) NOT NULL,
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status NOT NULL,
    momo_reference character varying(100),
    momo_provider public.momo_provider,
    initiated_at timestamp without time zone DEFAULT now() NOT NULL,
    confirmed_at timestamp without time zone,
    reconciled_at timestamp without time zone,
    is_reconciled boolean DEFAULT false NOT NULL,
    failure_reason character varying(300),
    created_by uuid NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.transactions OWNER TO nexus_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: nexus_user
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    email character varying(200),
    status public.user_status DEFAULT 'PENDING'::public.user_status NOT NULL,
    kyc_status public.kyc_status DEFAULT 'NOT_STARTED'::public.kyc_status NOT NULL,
    kyc_document_url character varying(500),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    last_login timestamp without time zone
);


ALTER TABLE public.users OWNER TO nexus_user;

--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.admins (id, role, permissions) FROM stdin;
00000000-0000-0000-0000-000000000001	SUPER_ADMIN	{VIEW_ESCROW,GENERATE_BCEAO_REPORT,MANAGE_USERS,VIEW_SCORING}
00000000-0000-0000-0000-000000000002	COMPLIANCE	{GENERATE_BCEAO_REPORT,VIEW_ESCROW}
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.agents (id, zone, agency_code, commission_rate, clients_assisted) FROM stdin;
00000000-0000-0000-0000-000000000005	Cotonou-Cadjehoun	AGT-COT-0001	0.005	12
00000000-0000-0000-0000-000000000006	Parakou-Centre	AGT-PAR-0001	0.005	8
\.


--
-- Data for Name: borrower_scores; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.borrower_scores (id, borrower_id, momo_score, tontine_score, imf_score, hybrid_score, computed_at) FROM stdin;
00000000-0000-0000-0000-000000000080	00000000-0000-0000-0000-000000000020	80.00	82.00	72.00	78.50	2025-01-20 07:00:00
00000000-0000-0000-0000-000000000081	00000000-0000-0000-0000-000000000021	74.00	65.00	68.00	71.00	2025-01-25 07:00:00
00000000-0000-0000-0000-000000000082	00000000-0000-0000-0000-000000000022	83.00	90.00	80.00	85.00	2025-02-01 07:00:00
00000000-0000-0000-0000-000000000083	00000000-0000-0000-0000-000000000023	72.00	0.00	58.00	67.50	2025-02-05 07:00:00
00000000-0000-0000-0000-000000000084	00000000-0000-0000-0000-000000000024	75.00	70.00	72.00	73.00	2025-02-10 07:00:00
00000000-0000-0000-0000-000000000085	00000000-0000-0000-0000-000000000025	55.00	45.00	65.00	58.00	2025-01-15 07:00:00
\.


--
-- Data for Name: borrowers; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.borrowers (id, credit_score, tontine_score, mobile_money_number, momo_provider, has_tontine_history, default_count) FROM stdin;
00000000-0000-0000-0000-000000000020	78.50	82.00	+22967200001	MTN_MOMO	t	0
00000000-0000-0000-0000-000000000021	71.00	65.00	+22967200002	MTN_MOMO	t	0
00000000-0000-0000-0000-000000000022	85.00	90.00	+22967200003	MOOV_FLOOZ	t	0
00000000-0000-0000-0000-000000000023	67.50	0.00	+22967200004	MTN_MOMO	f	0
00000000-0000-0000-0000-000000000024	73.00	70.00	+22967200005	MOOV_FLOOZ	t	0
00000000-0000-0000-0000-000000000025	58.00	45.00	+22967200006	MTN_MOMO	t	1
\.


--
-- Data for Name: escrow_wallet; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.escrow_wallet (id, total_balance, investor_funds, pending_disbursements, locked_for_guarantee, platform_fees, third_party_manager, last_audit_date) FROM stdin;
a0000000-0000-0000-0000-000000000001	15750000.00	14500000.00	875000.00	375000.00	0.00	Maître Adjonou Koffi — Notaire Cotonou	2025-03-01
\.


--
-- Data for Name: guarantee_fund; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.guarantee_fund (id, total_capital, active_portfolio_value, coverage_ratio, min_threshold, target_threshold, suspension_active, last_reconstitution_date) FROM stdin;
c0000000-0000-0000-0000-000000000001	437500.00	8750000.00	0.0500	0.0300	0.0500	f	2025-03-01
\.


--
-- Data for Name: guarantee_fund_investments; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.guarantee_fund_investments (id, fund_id, investment_id, covered_amount, activated_at, is_activated) FROM stdin;
\.


--
-- Data for Name: imf_staff; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.imf_staff (id, imf_name, license_number, bceao_agreement_ref) FROM stdin;
00000000-0000-0000-0000-000000000003	CLCAM Benin	BCEAO-SFD-BJ-2019-042	CONV-NEXUS-CLCAM-2025-001
00000000-0000-0000-0000-000000000004	CLCAM Benin	BCEAO-SFD-BJ-2019-042-B	CONV-NEXUS-CLCAM-2025-001
\.


--
-- Data for Name: institutional_investors; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.institutional_investors (id, organization_name, regulatory_license, max_exposure_ratio) FROM stdin;
00000000-0000-0000-0000-000000000013	BOAD Fonds Impact Afrique de l Ouest	LIC-INST-BJ-2020-001	0.2500
\.


--
-- Data for Name: investments; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.investments (id, investor_id, loan_id, amount, expected_return, actual_return, status, is_guaranteed, guarantee_tier, maturity_date) FROM stdin;
00000000-0000-0000-0000-000000000060	00000000-0000-0000-0000-000000000010	00000000-0000-0000-0000-000000000051	100000.00	7500.00	2500.00	ACTIVE	t	1	2025-08-01
00000000-0000-0000-0000-000000000061	00000000-0000-0000-0000-000000000013	00000000-0000-0000-0000-000000000051	100000.00	7500.00	2500.00	ACTIVE	t	1	2025-08-01
00000000-0000-0000-0000-000000000062	00000000-0000-0000-0000-000000000011	00000000-0000-0000-0000-000000000052	150000.00	15750.00	5250.00	ACTIVE	t	1	2025-11-05
00000000-0000-0000-0000-000000000063	00000000-0000-0000-0000-000000000012	00000000-0000-0000-0000-000000000052	150000.00	15750.00	5250.00	ACTIVE	t	1	2025-11-05
00000000-0000-0000-0000-000000000064	00000000-0000-0000-0000-000000000012	00000000-0000-0000-0000-000000000053	125000.00	10000.00	0.00	ACTIVE	t	1	2025-10-01
00000000-0000-0000-0000-000000000065	00000000-0000-0000-0000-000000000013	00000000-0000-0000-0000-000000000053	125000.00	10000.00	0.00	ACTIVE	t	1	2025-10-01
00000000-0000-0000-0000-000000000066	00000000-0000-0000-0000-000000000010	00000000-0000-0000-0000-000000000055	50000.00	9000.00	3000.00	ACTIVE	t	2	2025-04-20
00000000-0000-0000-0000-000000000067	00000000-0000-0000-0000-000000000011	00000000-0000-0000-0000-000000000055	50000.00	9000.00	3000.00	ACTIVE	t	2	2025-04-20
\.


--
-- Data for Name: investors; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.investors (id, wallet_balance, total_invested, total_returns, risk_profile, investor_type) FROM stdin;
00000000-0000-0000-0000-000000000010	250000.00	2000000.00	187500.00	BALANCED	RETAIL
00000000-0000-0000-0000-000000000011	150000.00	1500000.00	112500.00	CONSERVATIVE	RETAIL
00000000-0000-0000-0000-000000000012	500000.00	3500000.00	350000.00	DYNAMIC	RETAIL
00000000-0000-0000-0000-000000000013	5000000.00	8000000.00	600000.00	BALANCED	INSTITUTIONAL
\.


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.loans (id, borrower_id, amount, interest_rate, duration_months, status, monthly_installment, outstanding_balance, days_overdue, validated_by_imf, disbursed_at, next_due_date, imf_validated_by) FROM stdin;
00000000-0000-0000-0000-000000000050	00000000-0000-0000-0000-000000000020	150000.00	0.1500	6	REPAID	26318.00	0.00	0	t	2025-01-25 10:00:00	\N	00000000-0000-0000-0000-000000000003
00000000-0000-0000-0000-000000000051	00000000-0000-0000-0000-000000000021	200000.00	0.1500	6	ACTIVE	35091.00	105273.00	0	t	2025-02-01 11:00:00	2025-05-01	00000000-0000-0000-0000-000000000003
00000000-0000-0000-0000-000000000052	00000000-0000-0000-0000-000000000022	300000.00	0.1400	9	ACTIVE	36782.00	220692.00	0	t	2025-02-05 09:00:00	2025-05-05	00000000-0000-0000-0000-000000000004
00000000-0000-0000-0000-000000000053	00000000-0000-0000-0000-000000000023	250000.00	0.1600	6	FUNDING	44583.00	250000.00	0	t	\N	\N	00000000-0000-0000-0000-000000000004
00000000-0000-0000-0000-000000000054	00000000-0000-0000-0000-000000000024	175000.00	0.1500	6	ACTIVE	30704.00	153520.00	0	t	2025-02-10 10:00:00	2025-05-10	00000000-0000-0000-0000-000000000003
00000000-0000-0000-0000-000000000055	00000000-0000-0000-0000-000000000025	100000.00	0.1800	3	OVERDUE	34670.00	69340.00	35	t	2025-01-20 09:00:00	2025-03-20	00000000-0000-0000-0000-000000000003
\.


--
-- Data for Name: platform_wallet; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.platform_wallet (id, commission_balance, operating_funds, last_withdrawal_date) FROM stdin;
b0000000-0000-0000-0000-000000000001	487500.00	1200000.00	2025-03-15 10:00:00
\.


--
-- Data for Name: retail_investors; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.retail_investors (id, max_investment_cap, preferred_sectors) FROM stdin;
00000000-0000-0000-0000-000000000010	5000000.00	{Commerce,Artisanat}
00000000-0000-0000-0000-000000000011	5000000.00	{Agriculture,Elevage}
00000000-0000-0000-0000-000000000012	5000000.00	{Commerce,Transport,Restauration}
\.


--
-- Data for Name: scoring_engine; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.scoring_engine (id, momo_weight, tontine_weight, imf_weight, warning_signal_days) FROM stdin;
d0000000-0000-0000-0000-000000000001	0.40	0.35	0.25	45
\.


--
-- Data for Name: tontine_cycles; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.tontine_cycles (id, group_id, cycle_number, start_date, end_date, total_collected, is_complete, beneficiary_id, members_paid, members_defaulted) FROM stdin;
00000000-0000-0000-0000-000000000035	00000000-0000-0000-0000-000000000030	1	2025-01-20	2025-02-20	100000.00	t	00000000-0000-0000-0000-000000000020	4	0
00000000-0000-0000-0000-000000000036	00000000-0000-0000-0000-000000000030	2	2025-02-20	2025-03-20	100000.00	t	00000000-0000-0000-0000-000000000022	4	0
00000000-0000-0000-0000-000000000037	00000000-0000-0000-0000-000000000030	3	2025-03-20	2025-04-20	75000.00	t	00000000-0000-0000-0000-000000000024	3	1
00000000-0000-0000-0000-000000000042	00000000-0000-0000-0000-000000000038	1	2025-01-25	2025-02-25	150000.00	t	00000000-0000-0000-0000-000000000021	3	0
00000000-0000-0000-0000-000000000043	00000000-0000-0000-0000-000000000038	2	2025-02-25	2025-03-25	150000.00	t	00000000-0000-0000-0000-000000000023	3	0
00000000-0000-0000-0000-000000000044	00000000-0000-0000-0000-000000000038	3	2025-03-25	2025-04-25	150000.00	t	00000000-0000-0000-0000-000000000024	3	0
\.


--
-- Data for Name: tontine_groups; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.tontine_groups (id, name, leader_user_id, leader_phone, member_count, monthly_contribution, completed_cycles, status) FROM stdin;
00000000-0000-0000-0000-000000000030	Tontine Femmes Dantokpa	00000000-0000-0000-0000-000000000020	+22967200001	4	25000.00	3	ACTIVE
00000000-0000-0000-0000-000000000038	Tontine Artisans Cotonou	00000000-0000-0000-0000-000000000021	+22967200002	3	50000.00	3	ACTIVE
\.


--
-- Data for Name: tontine_members; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.tontine_members (id, group_id, borrower_id, joined_at) FROM stdin;
00000000-0000-0000-0000-000000000031	00000000-0000-0000-0000-000000000030	00000000-0000-0000-0000-000000000020	2025-01-20 08:00:00
00000000-0000-0000-0000-000000000032	00000000-0000-0000-0000-000000000030	00000000-0000-0000-0000-000000000022	2025-01-20 08:30:00
00000000-0000-0000-0000-000000000033	00000000-0000-0000-0000-000000000030	00000000-0000-0000-0000-000000000024	2025-01-20 09:00:00
00000000-0000-0000-0000-000000000034	00000000-0000-0000-0000-000000000030	00000000-0000-0000-0000-000000000025	2025-01-20 09:30:00
00000000-0000-0000-0000-000000000039	00000000-0000-0000-0000-000000000038	00000000-0000-0000-0000-000000000021	2025-01-25 09:00:00
00000000-0000-0000-0000-000000000040	00000000-0000-0000-0000-000000000038	00000000-0000-0000-0000-000000000023	2025-01-25 09:30:00
00000000-0000-0000-0000-000000000041	00000000-0000-0000-0000-000000000038	00000000-0000-0000-0000-000000000024	2025-01-25 10:00:00
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.transactions (id, type, amount, status, momo_reference, momo_provider, initiated_at, confirmed_at, reconciled_at, is_reconciled, failure_reason, created_by) FROM stdin;
00000000-0000-0000-0000-000000000070	LOAN_DISBURSEMENT	150000.00	RECONCILED	MTN-2025-0125-001	MTN_MOMO	2025-01-25 10:00:00	2025-01-25 10:02:00	2025-01-26 10:00:00	t	\N	00000000-0000-0000-0000-000000000001
00000000-0000-0000-0000-000000000071	LOAN_REPAYMENT	26318.00	RECONCILED	MTN-2025-0225-001	MTN_MOMO	2025-02-25 08:00:00	2025-02-25 08:01:00	2025-02-26 08:00:00	t	\N	00000000-0000-0000-0000-000000000020
00000000-0000-0000-0000-000000000072	PLATFORM_COMMISSION	657.95	RECONCILED	\N	\N	2025-02-25 08:05:00	2025-02-25 08:05:00	2025-02-25 08:05:00	t	\N	00000000-0000-0000-0000-000000000001
00000000-0000-0000-0000-000000000073	LOAN_REPAYMENT	26318.00	RECONCILED	MTN-2025-0325-001	MTN_MOMO	2025-03-25 08:00:00	2025-03-25 08:01:00	2025-03-26 08:00:00	t	\N	00000000-0000-0000-0000-000000000020
00000000-0000-0000-0000-000000000074	INVESTOR_DEPOSIT	500000.00	RECONCILED	MTN-2025-0115-001	MTN_MOMO	2025-01-15 09:00:00	2025-01-15 09:02:00	2025-01-16 09:00:00	t	\N	00000000-0000-0000-0000-000000000010
00000000-0000-0000-0000-000000000075	INVESTOR_DEPOSIT	300000.00	RECONCILED	MOOV-2025-0120-001	MOOV_FLOOZ	2025-01-20 10:00:00	2025-01-20 10:03:00	2025-01-21 10:00:00	t	\N	00000000-0000-0000-0000-000000000011
00000000-0000-0000-0000-000000000076	INVESTOR_DEPOSIT	1000000.00	RECONCILED	MTN-2025-0201-001	MTN_MOMO	2025-02-01 11:00:00	2025-02-01 11:01:00	2025-02-02 11:00:00	t	\N	00000000-0000-0000-0000-000000000012
00000000-0000-0000-0000-000000000077	INVESTOR_DEPOSIT	5000000.00	RECONCILED	MTN-2025-0110-001	MTN_MOMO	2025-01-10 08:00:00	2025-01-10 08:02:00	2025-01-11 08:00:00	t	\N	00000000-0000-0000-0000-000000000013
00000000-0000-0000-0000-000000000078	LOAN_REPAYMENT	35091.00	CONFIRMED	MTN-2025-0401-001	MTN_MOMO	2025-04-01 08:00:00	2025-04-01 08:01:00	\N	f	\N	00000000-0000-0000-0000-000000000021
00000000-0000-0000-0000-000000000079	LOAN_REPAYMENT	26318.00	PHANTOM_DETECTED	MTN-2025-0310-999	MTN_MOMO	2025-03-10 14:00:00	2025-03-10 14:01:00	\N	f	Confirmation MoMo recue mais montant non credite en base	00000000-0000-0000-0000-000000000020
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: nexus_user
--

COPY public.users (id, full_name, phone, email, status, kyc_status, kyc_document_url, created_at, last_login) FROM stdin;
00000000-0000-0000-0000-000000000001	Kofi Mensah	+22961000001	admin@nexus-benin.com	ACTIVE	VALIDATED	\N	2025-01-01 08:00:00	\N
00000000-0000-0000-0000-000000000002	Aissatou Traore	+22961000002	compliance@nexus-benin.com	ACTIVE	VALIDATED	\N	2025-01-01 08:30:00	\N
00000000-0000-0000-0000-000000000003	Brice Ahouansou	+22961000003	imf@clcam-benin.org	ACTIVE	VALIDATED	\N	2025-01-05 09:00:00	\N
00000000-0000-0000-0000-000000000004	Honorine Dossou	+22961000004	imf2@clcam-benin.org	ACTIVE	VALIDATED	\N	2025-01-05 09:30:00	\N
00000000-0000-0000-0000-000000000005	Theodore Gbaguidi	+22961000005	\N	ACTIVE	VALIDATED	\N	2025-01-10 10:00:00	\N
00000000-0000-0000-0000-000000000006	Rachida Idrissou	+22961000006	\N	ACTIVE	VALIDATED	\N	2025-01-10 10:30:00	\N
00000000-0000-0000-0000-000000000010	Fernand Adomou	+22966100001	fernand.adomou@gmail.com	ACTIVE	VALIDATED	\N	2025-01-15 09:00:00	\N
00000000-0000-0000-0000-000000000011	Sylvie Hounsou	+22966100002	sylvie.hounsou@yahoo.fr	ACTIVE	VALIDATED	\N	2025-01-20 10:00:00	\N
00000000-0000-0000-0000-000000000012	Pascal Agossou	+22966100003	pascal.agossou@gmail.com	ACTIVE	VALIDATED	\N	2025-02-01 11:00:00	\N
00000000-0000-0000-0000-000000000013	Direction BOAD Impact	+22921000001	impact@boad-benin.org	ACTIVE	VALIDATED	\N	2025-01-10 08:00:00	\N
00000000-0000-0000-0000-000000000020	Adjoua Akakpo	+22967200001	\N	ACTIVE	VALIDATED	\N	2025-01-20 08:00:00	\N
00000000-0000-0000-0000-000000000021	Gratien Hounkpatin	+22967200002	\N	ACTIVE	VALIDATED	\N	2025-01-25 09:00:00	\N
00000000-0000-0000-0000-000000000022	Celestine Zannou	+22967200003	\N	ACTIVE	VALIDATED	\N	2025-02-01 10:00:00	\N
00000000-0000-0000-0000-000000000023	Moussa Seidou	+22967200004	\N	ACTIVE	VALIDATED	\N	2025-02-05 11:00:00	\N
00000000-0000-0000-0000-000000000024	Victorine D`Almeida	+22967200005	\N	ACTIVE	VALIDATED	\N	2025-02-10 08:30:00	\N
00000000-0000-0000-0000-000000000025	Innocent Gbeto	+22967200006	\N	ACTIVE	VALIDATED	\N	2025-01-15 09:00:00	\N
\.


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: agents agents_agency_code_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_agency_code_key UNIQUE (agency_code);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: borrower_scores borrower_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.borrower_scores
    ADD CONSTRAINT borrower_scores_pkey PRIMARY KEY (id);


--
-- Name: borrowers borrowers_mobile_money_number_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.borrowers
    ADD CONSTRAINT borrowers_mobile_money_number_key UNIQUE (mobile_money_number);


--
-- Name: borrowers borrowers_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.borrowers
    ADD CONSTRAINT borrowers_pkey PRIMARY KEY (id);


--
-- Name: escrow_wallet escrow_wallet_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.escrow_wallet
    ADD CONSTRAINT escrow_wallet_pkey PRIMARY KEY (id);


--
-- Name: guarantee_fund_investments guarantee_fund_investments_fund_id_investment_id_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.guarantee_fund_investments
    ADD CONSTRAINT guarantee_fund_investments_fund_id_investment_id_key UNIQUE (fund_id, investment_id);


--
-- Name: guarantee_fund_investments guarantee_fund_investments_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.guarantee_fund_investments
    ADD CONSTRAINT guarantee_fund_investments_pkey PRIMARY KEY (id);


--
-- Name: guarantee_fund guarantee_fund_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.guarantee_fund
    ADD CONSTRAINT guarantee_fund_pkey PRIMARY KEY (id);


--
-- Name: imf_staff imf_staff_license_number_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.imf_staff
    ADD CONSTRAINT imf_staff_license_number_key UNIQUE (license_number);


--
-- Name: imf_staff imf_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.imf_staff
    ADD CONSTRAINT imf_staff_pkey PRIMARY KEY (id);


--
-- Name: institutional_investors institutional_investors_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.institutional_investors
    ADD CONSTRAINT institutional_investors_pkey PRIMARY KEY (id);


--
-- Name: investments investments_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (id);


--
-- Name: investors investors_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.investors
    ADD CONSTRAINT investors_pkey PRIMARY KEY (id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: platform_wallet platform_wallet_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.platform_wallet
    ADD CONSTRAINT platform_wallet_pkey PRIMARY KEY (id);


--
-- Name: retail_investors retail_investors_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.retail_investors
    ADD CONSTRAINT retail_investors_pkey PRIMARY KEY (id);


--
-- Name: scoring_engine scoring_engine_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.scoring_engine
    ADD CONSTRAINT scoring_engine_pkey PRIMARY KEY (id);


--
-- Name: tontine_cycles tontine_cycles_group_id_cycle_number_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_cycles
    ADD CONSTRAINT tontine_cycles_group_id_cycle_number_key UNIQUE (group_id, cycle_number);


--
-- Name: tontine_cycles tontine_cycles_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_cycles
    ADD CONSTRAINT tontine_cycles_pkey PRIMARY KEY (id);


--
-- Name: tontine_groups tontine_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_groups
    ADD CONSTRAINT tontine_groups_pkey PRIMARY KEY (id);


--
-- Name: tontine_members tontine_members_group_id_borrower_id_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_members
    ADD CONSTRAINT tontine_members_group_id_borrower_id_key UNIQUE (group_id, borrower_id);


--
-- Name: tontine_members tontine_members_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_members
    ADD CONSTRAINT tontine_members_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_momo_reference_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_momo_reference_key UNIQUE (momo_reference);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_borrowers_credit_score; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_borrowers_credit_score ON public.borrowers USING btree (credit_score);


--
-- Name: idx_investments_investor_id; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_investments_investor_id ON public.investments USING btree (investor_id);


--
-- Name: idx_investments_loan_id; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_investments_loan_id ON public.investments USING btree (loan_id);


--
-- Name: idx_investments_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_investments_status ON public.investments USING btree (status);


--
-- Name: idx_loans_borrower_id; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_loans_borrower_id ON public.loans USING btree (borrower_id);


--
-- Name: idx_loans_days_overdue; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_loans_days_overdue ON public.loans USING btree (days_overdue);


--
-- Name: idx_loans_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_loans_status ON public.loans USING btree (status);


--
-- Name: idx_tontine_cycles_group_id; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_tontine_cycles_group_id ON public.tontine_cycles USING btree (group_id);


--
-- Name: idx_tontine_groups_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_tontine_groups_status ON public.tontine_groups USING btree (status);


--
-- Name: idx_transactions_created_by; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_transactions_created_by ON public.transactions USING btree (created_by);


--
-- Name: idx_transactions_momo_reference; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_transactions_momo_reference ON public.transactions USING btree (momo_reference);


--
-- Name: idx_transactions_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_transactions_status ON public.transactions USING btree (status);


--
-- Name: idx_transactions_type; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_transactions_type ON public.transactions USING btree (type);


--
-- Name: idx_users_kyc_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_users_kyc_status ON public.users USING btree (kyc_status);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: nexus_user
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: admins admins_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: agents agents_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: borrower_scores borrower_scores_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.borrower_scores
    ADD CONSTRAINT borrower_scores_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(id);


--
-- Name: borrowers borrowers_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.borrowers
    ADD CONSTRAINT borrowers_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: guarantee_fund_investments guarantee_fund_investments_fund_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.guarantee_fund_investments
    ADD CONSTRAINT guarantee_fund_investments_fund_id_fkey FOREIGN KEY (fund_id) REFERENCES public.guarantee_fund(id);


--
-- Name: guarantee_fund_investments guarantee_fund_investments_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.guarantee_fund_investments
    ADD CONSTRAINT guarantee_fund_investments_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES public.investments(id);


--
-- Name: imf_staff imf_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.imf_staff
    ADD CONSTRAINT imf_staff_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: institutional_investors institutional_investors_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.institutional_investors
    ADD CONSTRAINT institutional_investors_id_fkey FOREIGN KEY (id) REFERENCES public.investors(id) ON DELETE CASCADE;


--
-- Name: investments investments_investor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_investor_id_fkey FOREIGN KEY (investor_id) REFERENCES public.investors(id);


--
-- Name: investments investments_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: investors investors_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.investors
    ADD CONSTRAINT investors_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: loans loans_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(id);


--
-- Name: loans loans_imf_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_imf_validated_by_fkey FOREIGN KEY (imf_validated_by) REFERENCES public.imf_staff(id);


--
-- Name: retail_investors retail_investors_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.retail_investors
    ADD CONSTRAINT retail_investors_id_fkey FOREIGN KEY (id) REFERENCES public.investors(id) ON DELETE CASCADE;


--
-- Name: tontine_cycles tontine_cycles_beneficiary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_cycles
    ADD CONSTRAINT tontine_cycles_beneficiary_id_fkey FOREIGN KEY (beneficiary_id) REFERENCES public.borrowers(id);


--
-- Name: tontine_cycles tontine_cycles_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_cycles
    ADD CONSTRAINT tontine_cycles_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.tontine_groups(id) ON DELETE CASCADE;


--
-- Name: tontine_groups tontine_groups_leader_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_groups
    ADD CONSTRAINT tontine_groups_leader_user_id_fkey FOREIGN KEY (leader_user_id) REFERENCES public.borrowers(id);


--
-- Name: tontine_members tontine_members_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_members
    ADD CONSTRAINT tontine_members_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(id);


--
-- Name: tontine_members tontine_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.tontine_members
    ADD CONSTRAINT tontine_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.tontine_groups(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nexus_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict QNpdhQrzUtFp7uCVm7b6fG7zToAFJ7TMtTo7VfLU36n5jAc6HBLUls0DRbynBSd

