import 'package:nexus/shared/models/app_enums.dart';

// ─────────────────────────────────────────────
// Requests (Flutter → Backend)
// ─────────────────────────────────────────────

class CreateLoanRequest {
  final int amount; // FCFA, min 25 000, max 500 000
  final int durationMonths; // 3, 6, 9 ou 12 uniquement
  final String purpose; // 10–500 caractères

  const CreateLoanRequest({
    required this.amount,
    required this.durationMonths,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'durationMonths': durationMonths,
    'purpose': purpose,
  };
}

class RepayLoanRequest {
  final int amount;
  final String momoReference;
  final MomoProvider momoProvider;

  const RepayLoanRequest({
    required this.amount,
    required this.momoReference,
    required this.momoProvider,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'momoReference': momoReference,
    'momoProvider': momoProvider.toJson(),
  };
}

// ─────────────────────────────────────────────
// Modèle Loan (Backend → Flutter)
// ─────────────────────────────────────────────

class Loan {
  final String id;
  final String borrowerId;
  final num amount;
  final CurrencyCode currency;
  final num interestRate;
  final int durationMonths;
  final LoanStatus status;
  final num monthlyInstallment;
  final num outstandingBalance;
  final int daysOverdue;
  final bool validatedByImf;
  final DateTime? disbursedAt;
  final DateTime? nextDueDate;
  final String? imfValidatedBy;
  final String? purpose;
  final String? rejectionReason;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.borrowerId,
    required this.amount,
    required this.currency,
    required this.interestRate,
    required this.durationMonths,
    required this.status,
    required this.monthlyInstallment,
    required this.outstandingBalance,
    required this.daysOverdue,
    required this.validatedByImf,
    this.disbursedAt,
    this.nextDueDate,
    this.imfValidatedBy,
    this.purpose,
    this.rejectionReason,
    required this.createdAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      borrowerId: json['borrowerId'] as String,
      // Les décimaux Prisma peuvent arriver en String ou num — on parse robustement
      amount: _parseNum(json['amount']),
      currency: CurrencyCode.fromJson(json['currency'] as String? ?? 'XOF'),
      interestRate: _parseNum(json['interestRate']),
      durationMonths: json['durationMonths'] as int,
      status: LoanStatus.fromJson(json['status'] as String? ?? 'PENDING_IMF'),
      monthlyInstallment: _parseNum(json['monthlyInstallment']),
      outstandingBalance: _parseNum(json['outstandingBalance']),
      daysOverdue: json['daysOverdue'] as int? ?? 0,
      validatedByImf: json['validatedByImf'] as bool? ?? false,
      disbursedAt: _parseDate(json['disbursedAt']),
      nextDueDate: _parseDate(json['nextDueDate']),
      imfValidatedBy: json['imfValidatedBy'] as String?,
      purpose: json['purpose'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  /// Vrai si l'utilisateur peut initier un remboursement.
  bool get canRepay =>
      status == LoanStatus.active || status == LoanStatus.overdue;

  /// Pourcentage remboursé (0.0 → 1.0).
  double get repaidRatio {
    if (amount == 0) return 0;
    return ((amount - outstandingBalance) / amount).clamp(0.0, 1.0).toDouble();
  }
}

// ─────────────────────────────────────────────
// Helpers de parsing Prisma
// ─────────────────────────────────────────────

/// Prisma Decimal → peut arriver comme String "25000.00" ou comme num.
num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
