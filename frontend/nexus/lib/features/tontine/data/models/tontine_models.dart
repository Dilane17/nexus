import 'package:nexus/shared/models/app_enums.dart';

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

// ── Requests ──────────────────────────────────────────────────────────────────

class CreateTontineGroupRequest {
  final String name;
  final int monthlyContribution;

  const CreateTontineGroupRequest({
    required this.name,
    required this.monthlyContribution,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'monthlyContribution': monthlyContribution,
  };
}

class CreateCycleRequest {
  final int cycleNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String beneficiaryId;

  const CreateCycleRequest({
    required this.cycleNumber,
    required this.startDate,
    required this.endDate,
    required this.beneficiaryId,
  });

  Map<String, dynamic> toJson() => {
    'cycleNumber': cycleNumber,
    'startDate': _formatDate(startDate),
    'endDate': _formatDate(endDate),
    'beneficiaryId': beneficiaryId,
  };

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CompleteCycleRequest {
  final int membersPaid;
  final int membersDefaulted;
  final num totalCollected;

  const CompleteCycleRequest({
    required this.membersPaid,
    required this.membersDefaulted,
    required this.totalCollected,
  });

  Map<String, dynamic> toJson() => {
    'membersPaid': membersPaid,
    'membersDefaulted': membersDefaulted,
    'totalCollected': totalCollected,
  };
}

// ── TontineScore ──────────────────────────────────────────────────────────────

class TontineScore {
  final String borrowerId;
  final num tontineScore;
  final bool hasTontineHistory;
  final int cyclesParticipated;
  final num averagePaymentRate;

  const TontineScore({
    required this.borrowerId,
    required this.tontineScore,
    required this.hasTontineHistory,
    required this.cyclesParticipated,
    required this.averagePaymentRate,
  });

  factory TontineScore.fromJson(Map<String, dynamic> json) {
    return TontineScore(
      borrowerId: json['borrowerId'] as String? ?? '',
      tontineScore: _parseNum(json['tontineScore']),
      hasTontineHistory: json['hasTontineHistory'] as bool? ?? false,
      cyclesParticipated: json['cyclesParticipated'] as int? ?? 0,
      averagePaymentRate: _parseNum(json['averagePaymentRate']),
    );
  }

  num get score => tontineScore;
  int get completedCycles => cyclesParticipated;
  int get defaultedCycles => 0;
  num get totalContributed => 0;
}

// ── TontineMember ──────────────────────────────────────────────────────────────

class TontineMember {
  final String id;
  final String userId;
  final String name;
  final String phone;

  const TontineMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
  });

  factory TontineMember.fromJson(Map<String, dynamic> json) {
    return TontineMember(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

// ── TontineGroup ──────────────────────────────────────────────────────────────

class TontineGroup {
  final String id;
  final String name;
  final String leaderUserId;
  final String leaderPhone;
  final int memberCount;
  final num monthlyContribution;
  final int completedCycles;
  final TontineStatus status;
  final List<TontineCycle> cycles;
  final List<TontineMember> members;

  const TontineGroup({
    required this.id,
    required this.name,
    required this.leaderUserId,
    required this.leaderPhone,
    required this.memberCount,
    required this.monthlyContribution,
    required this.completedCycles,
    required this.status,
    this.cycles = const [],
    this.members = const [],
  });

  factory TontineGroup.fromJson(Map<String, dynamic> json) {
    return TontineGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      leaderUserId: json['leaderUserId'] as String? ?? '',
      leaderPhone: json['leaderPhone'] as String? ?? '',
      memberCount: json['memberCount'] as int? ?? 0,
      monthlyContribution: _parseNum(json['monthlyContribution']),
      completedCycles: json['completedCycles'] as int? ?? 0,
      status: TontineStatus.fromJson(json['status'] as String? ?? 'PENDING'),
      cycles:
          (json['cycles'] as List<dynamic>?)
              ?.map((e) => TontineCycle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => TontineMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ── TontineCycle ──────────────────────────────────────────────────────────────

class TontineCycle {
  final String id;
  final int cycleNumber;
  final DateTime startDate;
  final DateTime endDate;
  final num totalCollected;
  final bool isComplete;
  final String beneficiaryId;
  final int membersPaid;
  final int membersDefaulted;

  const TontineCycle({
    required this.id,
    required this.cycleNumber,
    required this.startDate,
    required this.endDate,
    required this.totalCollected,
    required this.isComplete,
    required this.beneficiaryId,
    required this.membersPaid,
    required this.membersDefaulted,
  });

  factory TontineCycle.fromJson(Map<String, dynamic> json) {
    return TontineCycle(
      id: json['id'] as String,
      cycleNumber: json['cycleNumber'] as int? ?? 0,
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      totalCollected: _parseNum(json['totalCollected']),
      isComplete: json['isComplete'] as bool? ?? false,
      beneficiaryId: json['beneficiaryId'] as String? ?? '',
      membersPaid: json['membersPaid'] as int? ?? 0,
      membersDefaulted: json['membersDefaulted'] as int? ?? 0,
    );
  }
}
