import 'app_enums.dart';

/// Modèle utilisateur retourné par `/auth/me`.
class AuthUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? city;
  final String? district;
  final String? avatar;
  final UserStatus status;
  final KycStatus kycStatus;
  final bool isEmailVerified;

  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.city,
    this.district,
    this.avatar,
    required this.status,
    required this.kycStatus,
    required this.isEmailVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      avatar: json['avatar'] as String?,
      status: UserStatus.fromJson(json['status'] as String? ?? 'PENDING'),
      kycStatus: KycStatus.fromJson(
        json['kycStatus'] as String? ?? 'NOT_STARTED',
      ),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'city': city,
      'district': district,
      'avatar': avatar,
      'status': status.toJson(),
      'kycStatus': kycStatus.toJson(),
      'isEmailVerified': isEmailVerified,
    };
  }

  AuthUser copyWith({
    String? firstName,
    String? lastName,
    String? city,
    String? district,
    String? avatar,
    UserStatus? status,
    KycStatus? kycStatus,
  }) {
    return AuthUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone,
      city: city ?? this.city,
      district: district ?? this.district,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      isEmailVerified: isEmailVerified,
    );
  }

  String get fullName => '$firstName $lastName';

  bool get canAccessLoans => kycStatus == KycStatus.validated;
  bool get needsKyc => kycStatus != KycStatus.validated;
}
