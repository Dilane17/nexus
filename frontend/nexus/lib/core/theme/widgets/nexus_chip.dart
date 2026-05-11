import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_shapes.dart';
import '../app_typography.dart';
import 'package:nexus/shared/models/app_enums.dart';

/// Chip de statut Nexus générique.
/// Supporte tous les types de statuts de l'application avec mapping automatique des couleurs.
class NexusStatusChip extends StatelessWidget {
  final String label;
  final NexusChipStatus status;
  final Color? customColor;

  const NexusStatusChip({
    super.key,
    required this.label,
    required this.status,
    this.customColor,
  });

  /// Crée un chip pour LoanStatus avec mapping automatique.
  factory NexusStatusChip.fromLoanStatus(LoanStatus loanStatus) {
    final (label, status) = _mapLoanStatus(loanStatus);
    return NexusStatusChip(label: label, status: status);
  }

  /// Crée un chip pour InvestmentStatus avec mapping automatique.
  factory NexusStatusChip.fromInvestmentStatus(
    InvestmentStatus investmentStatus,
  ) {
    final (label, status) = _mapInvestmentStatus(investmentStatus);
    return NexusStatusChip(label: label, status: status);
  }

  /// Crée un chip pour TontineStatus avec mapping automatique.
  factory NexusStatusChip.fromTontineStatus(TontineStatus tontineStatus) {
    final (label, status) = _mapTontineStatus(tontineStatus);
    return NexusStatusChip(label: label, status: status);
  }

  /// Crée un chip pour TransactionStatus avec mapping automatique.
  factory NexusStatusChip.fromTransactionStatus(
    TransactionStatus transactionStatus,
  ) {
    final (label, status) = _mapTransactionStatus(transactionStatus);
    return NexusStatusChip(label: label, status: status);
  }

  /// Crée un chip pour KycStatus avec mapping automatique.
  factory NexusStatusChip.fromKycStatus(KycStatus kycStatus) {
    final (label, status) = _mapKycStatus(kycStatus);
    return NexusStatusChip(label: label, status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.1),
        borderRadius: NexusShapes.chipRadius,
        border: Border.all(
          color: _backgroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: NexusTypography.textTheme.labelSmall?.copyWith(
          color: _backgroundColor,
        ),
      ),
    );
  }

  Color get _backgroundColor => customColor ?? _mapStatusToColor(status);

  static Color _mapStatusToColor(NexusChipStatus status) {
    switch (status) {
      case NexusChipStatus.success:
        return NexusColors.success;
      case NexusChipStatus.warning:
        return NexusColors.warning;
      case NexusChipStatus.error:
        return NexusColors.error;
      case NexusChipStatus.info:
        return NexusColors.info;
      case NexusChipStatus.neutral:
        return NexusColors.onSurfaceVariant;
    }
  }

  /// Mapping LoanStatus → (label, NexusChipStatus)
  static (String, NexusChipStatus) _mapLoanStatus(LoanStatus status) {
    switch (status) {
      case LoanStatus.pendingImf:
        return (status.displayName, NexusChipStatus.warning);
      case LoanStatus.funding:
        return (status.displayName, NexusChipStatus.info);
      case LoanStatus.active:
        return (status.displayName, NexusChipStatus.success);
      case LoanStatus.overdue:
        return (status.displayName, NexusChipStatus.error);
      case LoanStatus.guaranteeActivated:
        return (status.displayName, NexusChipStatus.warning);
      case LoanStatus.repurchased:
        return (status.displayName, NexusChipStatus.info);
      case LoanStatus.repaid:
        return (status.displayName, NexusChipStatus.success);
      case LoanStatus.cancelled:
        return (status.displayName, NexusChipStatus.neutral);
      case LoanStatus.restructured:
        return (status.displayName, NexusChipStatus.info);
    }
  }

  /// Mapping InvestmentStatus → (label, NexusChipStatus)
  static (String, NexusChipStatus) _mapInvestmentStatus(
    InvestmentStatus status,
  ) {
    switch (status) {
      case InvestmentStatus.active:
        return (status.displayName, NexusChipStatus.success);
      case InvestmentStatus.completed:
        return (status.displayName, NexusChipStatus.info);
      case InvestmentStatus.defaulted:
        return (status.displayName, NexusChipStatus.error);
      case InvestmentStatus.guaranteed:
        return (status.displayName, NexusChipStatus.success);
    }
  }

  /// Mapping TontineStatus → (label, NexusChipStatus)
  static (String, NexusChipStatus) _mapTontineStatus(TontineStatus status) {
    switch (status) {
      case TontineStatus.pending:
        return (status.displayName, NexusChipStatus.warning);
      case TontineStatus.active:
        return (status.displayName, NexusChipStatus.success);
      case TontineStatus.completed:
        return (status.displayName, NexusChipStatus.info);
      case TontineStatus.suspended:
        return (status.displayName, NexusChipStatus.error);
    }
  }

  /// Mapping TransactionStatus → (label, NexusChipStatus)
  static (String, NexusChipStatus) _mapTransactionStatus(
    TransactionStatus status,
  ) {
    switch (status) {
      case TransactionStatus.pending:
        return (status.displayName, NexusChipStatus.warning);
      case TransactionStatus.confirmed:
        return (status.displayName, NexusChipStatus.success);
      case TransactionStatus.reconciled:
        return (status.displayName, NexusChipStatus.info);
      case TransactionStatus.failed:
        return (status.displayName, NexusChipStatus.error);
      case TransactionStatus.phantomDetected:
        return (status.displayName, NexusChipStatus.error);
    }
  }

  /// Mapping KycStatus → (label, NexusChipStatus)
  static (String, NexusChipStatus) _mapKycStatus(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return (status.displayName, NexusChipStatus.neutral);
      case KycStatus.session1Done:
        return (status.displayName, NexusChipStatus.info);
      case KycStatus.session2Done:
        return (status.displayName, NexusChipStatus.info);
      case KycStatus.submitted:
        return (status.displayName, NexusChipStatus.warning);
      case KycStatus.validated:
        return (status.displayName, NexusChipStatus.success);
      case KycStatus.rejected:
        return (status.displayName, NexusChipStatus.error);
    }
  }
}

enum NexusChipStatus { success, warning, error, info, neutral }
