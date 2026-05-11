import 'package:nexus/shared/models/app_enums.dart';

// ─────────────────────────────────────────────
// Requests
// ─────────────────────────────────────────────

class DepositRequest {
  final int amount;
  final MomoProvider momoProvider;
  final String momoPhone;

  const DepositRequest({
    required this.amount,
    required this.momoProvider,
    required this.momoPhone,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'momoProvider': momoProvider.toJson(),
        'momoPhone': momoPhone,
      };
}

class WithdrawalRequest {
  final int amount;
  final MomoProvider momoProvider;
  final String momoNumber;

  const WithdrawalRequest({
    required this.amount,
    required this.momoProvider,
    required this.momoNumber,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'momoProvider': momoProvider.toJson(),
        'momoNumber': momoNumber,
      };
}

// ─────────────────────────────────────────────
// Modèle Transaction
// ─────────────────────────────────────────────

class Transaction {
  final String id;
  final TransactionType type;
  final num amount;
  final CurrencyCode currency;
  final TransactionStatus status;
  final String? paymentGateway;
  final String? momoReference;
  final MomoProvider? momoProvider;
  final String? failureReason;
  final DateTime initiatedAt;
  final DateTime? confirmedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentGateway,
    this.momoReference,
    this.momoProvider,
    this.failureReason,
    required this.initiatedAt,
    this.confirmedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TransactionType.fromJson(json['type'] as String? ?? 'INVESTOR_DEPOSIT'),
      amount: _parseNum(json['amount']),
      currency: CurrencyCode.fromJson(json['currency'] as String? ?? 'XOF'),
      status: TransactionStatus.fromJson(json['status'] as String? ?? 'PENDING'),
      paymentGateway: json['paymentGateway'] as String?,
      momoReference: json['momoReference'] as String?,
      momoProvider: json['momoProvider'] != null
          ? MomoProvider.fromJson(json['momoProvider'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      initiatedAt: DateTime.tryParse(json['initiatedAt'] as String? ?? '') ??
          DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
    );
  }

  bool get isDebit =>
      type == TransactionType.investorWithdrawal ||
      type == TransactionType.loanRepayment ||
      type == TransactionType.platformCommission;
}

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}
