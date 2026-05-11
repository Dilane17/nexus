/// Enums alignés exactement sur les valeurs du backend NestJS/Prisma.
/// Chaque enum expose :
///   - toJson()          → la chaîne attendue par l'API
///   - fromJson(String)  → parsing robuste avec fallback
///   - displayName       → libellé lisible pour l'UI
library;

// ─────────────────────────────────────────────
// UserStatus
// ─────────────────────────────────────────────

enum UserStatus {
  pending,
  active,
  suspended,
  blocked;

  String toJson() => name.toUpperCase();

  static UserStatus fromJson(String value) => UserStatus.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => UserStatus.pending,
  );

  String get displayName => switch (this) {
    pending => 'En attente',
    active => 'Actif',
    suspended => 'Suspendu',
    blocked => 'Bloqué',
  };
}

// ─────────────────────────────────────────────
// KycStatus
// ─────────────────────────────────────────────

enum KycStatus {
  notStarted,
  session1Done,
  session2Done,
  submitted,
  validated,
  rejected;

  // Les valeurs backend utilisent des underscores : NOT_STARTED, SESSION1_DONE…
  String toJson() => switch (this) {
    notStarted => 'NOT_STARTED',
    session1Done => 'SESSION1_DONE',
    session2Done => 'SESSION2_DONE',
    submitted => 'SUBMITTED',
    validated => 'VALIDATED',
    rejected => 'REJECTED',
  };

  static KycStatus fromJson(String value) => KycStatus.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => KycStatus.notStarted,
  );

  String get displayName => switch (this) {
    notStarted => 'Non démarré',
    session1Done => 'Documents soumis',
    session2Done => 'Dossier complet',
    submitted => 'En cours de validation',
    validated => 'Validé',
    rejected => 'Rejeté',
  };

  bool get isComplete => this == validated;
  bool get isInProgress => this == session1Done || this == session2Done;
}

// ─────────────────────────────────────────────
// LoanStatus
// ─────────────────────────────────────────────

enum LoanStatus {
  pendingImf,
  funding,
  active,
  overdue,
  guaranteeActivated,
  repurchased,
  repaid,
  cancelled,
  restructured;

  String toJson() => switch (this) {
    pendingImf => 'PENDING_IMF',
    funding => 'FUNDING',
    active => 'ACTIVE',
    overdue => 'OVERDUE',
    guaranteeActivated => 'GUARANTEE_ACTIVATED',
    repurchased => 'REPURCHASED',
    repaid => 'REPAID',
    cancelled => 'CANCELLED',
    restructured => 'RESTRUCTURED',
  };

  static LoanStatus fromJson(String value) => LoanStatus.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => LoanStatus.pendingImf,
  );

  String get displayName => switch (this) {
    pendingImf => 'En attente IMF',
    funding => 'En financement',
    active => 'Actif',
    overdue => 'En retard',
    guaranteeActivated => 'Garantie activée',
    repurchased => 'Racheté',
    repaid => 'Remboursé',
    cancelled => 'Annulé',
    restructured => 'Restructuré',
  };
}

// ─────────────────────────────────────────────
// InvestmentStatus
// ─────────────────────────────────────────────

enum InvestmentStatus {
  active,
  completed,
  defaulted,
  guaranteed;

  String toJson() => name.toUpperCase();

  static InvestmentStatus fromJson(String value) =>
      InvestmentStatus.values.firstWhere(
        (e) => e.toJson() == value,
        orElse: () => InvestmentStatus.active,
      );

  String get displayName => switch (this) {
    active => 'Actif',
    completed => 'Terminé',
    defaulted => 'En défaut',
    guaranteed => 'Garanti',
  };
}

// ─────────────────────────────────────────────
// TontineStatus
// ─────────────────────────────────────────────

enum TontineStatus {
  pending,
  active,
  completed,
  suspended;

  String toJson() => name.toUpperCase();

  static TontineStatus fromJson(String value) =>
      TontineStatus.values.firstWhere(
        (e) => e.toJson() == value,
        orElse: () => TontineStatus.pending,
      );

  String get displayName => switch (this) {
    pending => 'En attente',
    active => 'Actif',
    completed => 'Terminé',
    suspended => 'Suspendu',
  };
}

// ─────────────────────────────────────────────
// TransactionStatus
// ─────────────────────────────────────────────

enum TransactionStatus {
  pending,
  confirmed,
  reconciled,
  failed,
  phantomDetected;

  String toJson() => switch (this) {
    pending => 'PENDING',
    confirmed => 'CONFIRMED',
    reconciled => 'RECONCILED',
    failed => 'FAILED',
    phantomDetected => 'PHANTOM_DETECTED',
  };

  static TransactionStatus fromJson(String value) =>
      TransactionStatus.values.firstWhere(
        (e) => e.toJson() == value,
        orElse: () => TransactionStatus.pending,
      );

  String get displayName => switch (this) {
    pending => 'En attente',
    confirmed => 'Confirmé',
    reconciled => 'Réconcilié',
    failed => 'Échoué',
    phantomDetected => 'Anomalie détectée',
  };
}

// ─────────────────────────────────────────────
// TransactionType
// ─────────────────────────────────────────────

enum TransactionType {
  investorDeposit,
  investorWithdrawal,
  loanDisbursement,
  loanRepayment,
  platformCommission,
  guaranteeActivation,
  imfRepurchase,
  agentCommission;

  String toJson() => switch (this) {
    investorDeposit => 'INVESTOR_DEPOSIT',
    investorWithdrawal => 'INVESTOR_WITHDRAWAL',
    loanDisbursement => 'LOAN_DISBURSEMENT',
    loanRepayment => 'LOAN_REPAYMENT',
    platformCommission => 'PLATFORM_COMMISSION',
    guaranteeActivation => 'GUARANTEE_ACTIVATION',
    imfRepurchase => 'IMF_REPURCHASE',
    agentCommission => 'AGENT_COMMISSION',
  };

  static TransactionType fromJson(String value) =>
      TransactionType.values.firstWhere(
        (e) => e.toJson() == value,
        orElse: () => TransactionType.investorDeposit,
      );

  String get displayName => switch (this) {
    investorDeposit => 'Dépôt',
    investorWithdrawal => 'Retrait',
    loanDisbursement => 'Déblocage prêt',
    loanRepayment => 'Remboursement',
    platformCommission => 'Commission plateforme',
    guaranteeActivation => 'Activation garantie',
    imfRepurchase => 'Rachat IMF',
    agentCommission => 'Commission agent',
  };
}

// ─────────────────────────────────────────────
// MomoProvider
// ─────────────────────────────────────────────

enum MomoProvider {
  mtnMomo,
  moovFlooz;

  // Backend attend : MTN_MOMO ou MOOV_FLOOZ
  String toJson() => switch (this) {
    mtnMomo => 'MTN_MOMO',
    moovFlooz => 'MOOV_FLOOZ',
  };

  static MomoProvider fromJson(String value) => MomoProvider.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => MomoProvider.mtnMomo,
  );

  String get displayName => switch (this) {
    mtnMomo => 'MTN Mobile Money',
    moovFlooz => 'Moov Flooz',
  };
}

// ─────────────────────────────────────────────
// UserRole
// ─────────────────────────────────────────────

enum UserRole {
  investor,
  borrower,
  imfStaff,
  admin,
  agent,
  user;

  String toJson() => switch (this) {
    investor => 'investor',
    borrower => 'borrower',
    imfStaff => 'imf_staff',
    admin => 'admin',
    agent => 'agent',
    user => 'user',
  };

  static UserRole fromJson(String value) => UserRole.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => UserRole.user,
  );

  String get displayName => switch (this) {
    investor => 'Investisseur',
    borrower => 'Emprunteur',
    imfStaff => 'Personnel IMF',
    admin => 'Administrateur',
    agent => 'Agent',
    user => 'Utilisateur',
  };

  bool get isBorrower => this == borrower;
  bool get isInvestor => this == investor;
  bool get isAdmin => this == admin;
  bool get isImfStaff => this == imfStaff;
  bool get isAgent => this == agent;
  bool get isBackoffice => isAdmin || isImfStaff || isAgent;
  bool get isFrontend => isBorrower || isInvestor;
}

// ─────────────────────────────────────────────
// CurrencyCode
// ─────────────────────────────────────────────

enum CurrencyCode {
  xof,
  usd,
  eur,
  ngn;

  String toJson() => name.toUpperCase();

  static CurrencyCode fromJson(String value) => CurrencyCode.values.firstWhere(
    (e) => e.toJson() == value,
    orElse: () => CurrencyCode.xof,
  );

  String get symbol => switch (this) {
    xof => 'FCFA',
    usd => '\$',
    eur => '€',
    ngn => '₦',
  };
}
