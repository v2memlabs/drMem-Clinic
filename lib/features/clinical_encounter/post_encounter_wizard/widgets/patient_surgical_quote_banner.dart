import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clinical_notice.dart';
import '../../../../shared/widgets/clinical_notice_tone.dart';
import '../data/patient_surgical_quote_alert_repository.dart';
import '../models/patient_surgical_quote_alert.dart';
import '../models/surgical_quote_currency.dart';

/// Hasta detay ve muayene formunda gösterilen cerrahi teklif uyarısı.
class PatientSurgicalQuoteBanner extends StatefulWidget {
  final String patientId;
  final VoidCallback? onChanged;

  const PatientSurgicalQuoteBanner({
    super.key,
    required this.patientId,
    this.onChanged,
  });

  @override
  State<PatientSurgicalQuoteBanner> createState() =>
      _PatientSurgicalQuoteBannerState();
}

class _PatientSurgicalQuoteBannerState extends State<PatientSurgicalQuoteBanner> {
  PatientSurgicalQuoteAlert? _alert;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PatientSurgicalQuoteBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _alert = PatientSurgicalQuoteAlertRepository.instance
          .activeForPatient(widget.patientId);
    });
  }

  void _dismiss() {
    final alert = _alert;
    if (alert == null) return;

    PatientSurgicalQuoteAlertRepository.instance.dismiss(
      alert.id,
      dismissedBy: AuthSession.currentUser?.displayName ?? 'Hekim',
      at: DateTime.now(),
    );
    _reload();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!TenantFinancialFeatureGate.surgicalQuoteAlertsEnabled) {
      return const SizedBox.shrink();
    }
    final alert = _alert;
    if (alert == null) return const SizedBox.shrink();

    final amountText = alert.hasQuotedAmount
        ? '${alert.quotedAmount!.toStringAsFixed(2)} ${alert.currency.label}'
        : 'Fiyat verilmedi';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClinicalNotice(
        tone: ClinicalNoticeTone.warning,
        title: 'Cerrahi teklif bekliyor',
        message:
            '${alert.patientName} — $amountText${alert.procedureNote.trim().isEmpty ? '' : '\n${alert.procedureNote.trim()}'}',
        dense: true,
        actions: AuthSession.canEditClinicalEncounters
            ? [
                ClinicalNoticeAction(
                  label: 'Bir daha gösterme',
                  onPressed: _dismiss,
                ),
              ]
            : const [],
      ),
    );
  }
}
