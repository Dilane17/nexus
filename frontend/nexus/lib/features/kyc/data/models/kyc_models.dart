import 'package:nexus/shared/models/app_enums.dart';

// ─────────────────────────────────────────────
// Requests (Flutter → Backend)
// ─────────────────────────────────────────────

class KycSession1Request {
  final String documentType; // CNI | CIP | PASSEPORT | PERMIS
  final String documentUrl;
  final String selfieUrl;

  const KycSession1Request({
    required this.documentType,
    required this.documentUrl,
    required this.selfieUrl,
  });

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'documentUrl': documentUrl,
        'selfieUrl': selfieUrl,
      };
}

class KycSession2Request {
  final num monthlyIncome;
  final String incomeSource; // SALARIE | INDEPENDANT | COMMERCE | AGRICULTURE | TRANSFERT | AUTRE
  final String? momoStatementUrl;

  const KycSession2Request({
    required this.monthlyIncome,
    required this.incomeSource,
    this.momoStatementUrl,
  });

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'incomeSource': incomeSource,
        if (momoStatementUrl != null) 'momoStatementUrl': momoStatementUrl,
      };
}

// ─────────────────────────────────────────────
// Response (Backend → Flutter)
// ─────────────────────────────────────────────

/// Statut KYC détaillé retourné par GET /users/kyc/status
class KycStatusResponse {
  final KycStatus status;
  final String? documentType;
  final String? documentUrl;
  final String? selfieUrl;
  final num? monthlyIncome;
  final String? incomeSource;
  final String? momoStatementUrl;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? validatedAt;

  const KycStatusResponse({
    required this.status,
    this.documentType,
    this.documentUrl,
    this.selfieUrl,
    this.monthlyIncome,
    this.incomeSource,
    this.momoStatementUrl,
    this.rejectionReason,
    this.submittedAt,
    this.validatedAt,
  });

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      status: KycStatus.fromJson(json['kycStatus'] as String? ?? 'NOT_STARTED'),
      documentType: json['kycDocumentType'] as String?,
      documentUrl: json['kycDocumentUrl'] as String?,
      selfieUrl: json['kycSelfieUrl'] as String?,
      monthlyIncome: json['kycMonthlyIncome'] as num?,
      incomeSource: json['kycIncomeSource'] as String?,
      momoStatementUrl: json['kycMomoStatement'] as String?,
      rejectionReason: json['kycRejectionReason'] as String?,
      submittedAt: json['kycSubmittedAt'] != null
          ? DateTime.tryParse(json['kycSubmittedAt'] as String)
          : null,
      validatedAt: json['kycValidatedAt'] != null
          ? DateTime.tryParse(json['kycValidatedAt'] as String)
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// Enums locaux
// ─────────────────────────────────────────────

enum DocumentType {
  cni,
  cip,
  passeport,
  permis;

  String toJson() => switch (this) {
        cni => 'CNI',
        cip => 'CIP',
        passeport => 'PASSEPORT',
        permis => 'PERMIS',
      };

  String get displayName => switch (this) {
        cni => "Carte Nationale d'Identité",
        cip => 'Carte d\'Identité Professionnelle',
        passeport => 'Passeport',
        permis => 'Permis de conduire',
      };
}

enum IncomeSource {
  salarie,
  independant,
  commerce,
  agriculture,
  transfert,
  autre;

  String toJson() => name.toUpperCase();

  String get displayName => switch (this) {
        salarie => 'Salarié',
        independant => 'Travailleur indépendant',
        commerce => 'Commerce / Négoce',
        agriculture => 'Agriculture',
        transfert => 'Transferts / Diaspora',
        autre => 'Autre',
      };
}
