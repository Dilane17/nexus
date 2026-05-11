import 'package:flutter/material.dart';
import 'package:nexus/core/theme/widgets/nexus_chip.dart';
import 'package:nexus/shared/models/app_enums.dart';

/// Badge de statut réutilisé dans la liste et le détail.
/// Wrapper autour de NexusStatusChip pour compatibilité.
@Deprecated('Use NexusStatusChip.fromLoanStatus() instead')
class LoanStatusBadge extends StatelessWidget {
  final LoanStatus status;

  const LoanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return NexusStatusChip.fromLoanStatus(status);
  }
}
