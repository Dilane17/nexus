import 'app_enums.dart';

/// Modèle profil utilisateur retourné par `/users/profile`.
/// Contient le rôle métier et les données spécifiques au rôle.
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String email;
  final String? city;
  final String? district;
  final String? avatar;
  final UserStatus status;
  final KycStatus kycStatus;
  final DateTime? kycSubmittedAt;
  final bool isEmailVerified;
  final UserRole role;
  final InvestorData? investorData;
  final BorrowerData? borrowerData;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.email,
    this.city,
    this.district,
    this.avatar,
    required this.status,
    required this.kycStatus,
    this.kycSubmittedAt,
    required this.isEmailVerified,
    required this.role,
    this.investorData,
    this.borrowerData,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      city: json['city'] as String?,
      district: json['district'] as String?,
      avatar: json['avatar'] as String?,
      status: UserStatus.fromJson(json['status'] as String? ?? 'PENDING'),
      kycStatus: KycStatus.fromJson(
        json['kycStatus'] as String? ?? 'NOT_STARTED',
      ),
      kycSubmittedAt:
          json['kycSubmittedAt'] != null
              ? DateTime.parse(json['kycSubmittedAt'] as String)
              : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      role: UserRole.fromJson(json['role'] as String? ?? 'user'),
      investorData:
          json['investorData'] != null
              ? InvestorData.fromJson(
                json['investorData'] as Map<String, dynamic>,
              )
              : null,
      borrowerData:
          json['borrowerData'] != null
              ? BorrowerData.fromJson(
                json['borrowerData'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'city': city,
      'district': district,
      'avatar': avatar,
      'status': status.toJson(),
      'kycStatus': kycStatus.toJson(),
      if (kycSubmittedAt != null)
        'kycSubmittedAt': kycSubmittedAt!.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'role': role.toJson(),
      if (investorData != null) 'investorData': investorData!.toJson(),
      if (borrowerData != null) 'borrowerData': borrowerData!.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';

  bool get isBorrower => role == UserRole.borrower;
  bool get isInvestor => role == UserRole.investor;
  bool get isAdmin => role == UserRole.admin;
  bool get isImfStaff => role == UserRole.imfStaff;
  bool get isAgent => role == UserRole.agent;
  bool get isBackoffice => isAdmin || isImfStaff || isAgent;
  bool get isFrontend => isBorrower || isInvestor;

  bool get canAccessLoans =>
      kycStatus == KycStatus.validated && (isBorrower || isInvestor);
  bool get needsKyc => kycStatus != KycStatus.validated;
}

/// Données spécifiques aux investisseurs
class InvestorData {
  final num walletBalance;
  final num totalInvested;
  final num totalReturns;
  final String riskProfile;
  final String investorType;

  const InvestorData({
    required this.walletBalance,
    required this.totalInvested,
    required this.totalReturns,
    required this.riskProfile,
    required this.investorType,
  });

  factory InvestorData.fromJson(Map<String, dynamic> json) {
    return InvestorData(
      walletBalance: _parseNum(json['walletBalance']),
      totalInvested: _parseNum(json['totalInvested']),
      totalReturns: _parseNum(json['totalReturns']),
      riskProfile: json['riskProfile'] as String? ?? 'CONSERVATIVE',
      investorType: json['investorType'] as String? ?? 'INDIVIDUAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletBalance': walletBalance,
      'totalInvested': totalInvested,
      'totalReturns': totalReturns,
      'riskProfile': riskProfile,
      'investorType': investorType,
    };
  }
}

/// Données spécifiques aux emprunteurs
class BorrowerData {
  final num creditScore;
  final num tontineScore;
  final bool hasTontineHistory;
  final int defaultCount;
  final String mobileMoneyNumber;

  const BorrowerData({
    required this.creditScore,
    required this.tontineScore,
    required this.hasTontineHistory,
    required this.defaultCount,
    required this.mobileMoneyNumber,
  });

  factory BorrowerData.fromJson(Map<String, dynamic> json) {
    return BorrowerData(
      creditScore: _parseNum(json['creditScore']),
      tontineScore: _parseNum(json['tontineScore']),
      hasTontineHistory: json['hasTontineHistory'] as bool? ?? false,
      defaultCount: json['defaultCount'] as int? ?? 0,
      mobileMoneyNumber: json['mobileMoneyNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creditScore': creditScore,
      'tontineScore': tontineScore,
      'hasTontineHistory': hasTontineHistory,
      'defaultCount': defaultCount,
      'mobileMoneyNumber': mobileMoneyNumber,
    };
  }
}

num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  return 0;
}
