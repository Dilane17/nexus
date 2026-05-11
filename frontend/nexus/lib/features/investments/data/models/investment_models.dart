import 'package:nexus/shared/models/app_enums.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

// ── Requests ──────────────────────────────────────────────────────────────────

class CreateInvestmentRequest {
  final String loanId;
  final int amount;

  const CreateInvestmentRequest({required this.loanId, required this.amount});

  Map<String, dynamic> toJson() => {
        'loanId': loanId,
        'amount': amount,
      };
}

class AutoInvestRuleRequest {
  final bool isActive;
  final int maxAmount;
  final int maxDuration;
  final num minHybridScore;

  const AutoInvestRuleRequest({
    required this.isActive,
    required this.maxAmount,
    required this.maxDuration,
    required this.minHybridScore,
  });

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'maxAmount': maxAmount,
        'maxDuration': maxDuration,
        'minHybridScore': minHybridScore,
      };
}

// ── Investment ────────────────────────────────────────────────────────────────

class Investment {
  final String id;
  final String investorId;
  final String loanId;
  final num amount;
  final CurrencyCode currency;
  final num expectedReturn;
  final num actualReturn;
  final InvestmentStatus status;
  final bool isGuaranteed;
  final int guaranteeTier;
  final DateTime maturityDate;

  const Investment({
    required this.id,
    required this.investorId,
    required this.loanId,
    required this.amount,
    required this.currency,
    required this.expectedReturn,
    required this.actualReturn,
    required this.status,
    required this.isGuaranteed,
    required this.guaranteeTier,
    required this.maturityDate,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      investorId: json['investorId'] as String? ?? '',
      loanId: json['loanId'] as String? ?? '',
      amount: _parseNum(json['amount']),
      currency: CurrencyCode.fromJson(json['currency'] as String? ?? 'XOF'),
      expectedReturn: _parseNum(json['expectedReturn']),
      actualReturn: _parseNum(json['actualReturn']),
      status: InvestmentStatus.fromJson(json['status'] as String? ?? 'ACTIVE'),
      isGuaranteed: json['isGuaranteed'] as bool? ?? false,
      guaranteeTier: json['guaranteeTier'] as int? ?? 0,
      maturityDate:
          DateTime.tryParse(json['maturityDate'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

// ── InvestmentSummary ─────────────────────────────────────────────────────────

class InvestmentSummary {
  final num totalInvested;
  final num totalExpectedReturn;
  final num totalActualReturn;
  final int activeCount;
  final int completedCount;
  final int defaultedCount;

  const InvestmentSummary({
    required this.totalInvested,
    required this.totalExpectedReturn,
    required this.totalActualReturn,
    required this.activeCount,
    required this.completedCount,
    required this.defaultedCount,
  });

  factory InvestmentSummary.fromJson(Map<String, dynamic> json) {
    return InvestmentSummary(
      totalInvested: _parseNum(json['totalInvested']),
      totalExpectedReturn: _parseNum(json['totalExpectedReturn']),
      totalActualReturn: _parseNum(json['totalActualReturn']),
      activeCount: json['investmentsByStatus']?['ACTIVE'] as int? ?? 0,
      completedCount: json['investmentsByStatus']?['COMPLETED'] as int? ?? 0,
      defaultedCount: json['investmentsByStatus']?['DEFAULTED'] as int? ?? 0,
    );
  }
}

// ── AutoInvestRule ────────────────────────────────────────────────────────────

class AutoInvestRule {
  final String id;
  final String investorId;
  final bool isActive;
  final num maxAmount;
  final int maxDuration;
  final num minHybridScore;
  final DateTime createdAt;

  const AutoInvestRule({
    required this.id,
    required this.investorId,
    required this.isActive,
    required this.maxAmount,
    required this.maxDuration,
    required this.minHybridScore,
    required this.createdAt,
  });

  factory AutoInvestRule.fromJson(Map<String, dynamic> json) {
    return AutoInvestRule(
      id: json['id'] as String,
      investorId: json['investorId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      maxAmount: _parseNum(json['maxAmount']),
      maxDuration: json['maxDuration'] as int? ?? 12,
      minHybridScore: _parseNum(json['minHybridScore']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
