import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../patients/data/patient_identity_privacy.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../../patients/models/patient.dart';
import '../../patients/patient_display_helpers.dart';
import '../../patients/widgets/patient_lookup_builder.dart';
import '../../../shared/widgets/clinical_list_row.dart';
import '../../../shared/widgets/premium_surface.dart';
import '../models/clinical_encounter.dart';

/// Hasta / muayene üst kimlik bandı — düz panel, chip seli yok.
class ClinicalEncounterIdentityBand extends StatelessWidget {
  final String patientName;
  final String? demographicLine;
  final String? maskedIdentityLine;
  final List<String> patientTags;
  final int maxPatientTags;
  final String? contextMetaLine;
  final String? encounterDateLabel;
  final bool compact;
  final bool showPatientTags;
  final Widget? trailing;

  const ClinicalEncounterIdentityBand({
    super.key,
    required this.patientName,
    this.demographicLine,
    this.maskedIdentityLine,
    this.patientTags = const [],
    this.maxPatientTags = 3,
    this.contextMetaLine,
    this.encounterDateLabel,
    this.compact = false,
    this.showPatientTags = false,
    this.trailing,
  });

  /// Muayene detay — kompakt demografi + maskeli T.C. (ham kimlik yok).
  factory ClinicalEncounterIdentityBand.fromEncounter(
    ClinicalEncounter encounter, {
    Widget? trailing,
    bool detailMode = true,
  }) {
    final patient = PatientLookupDataSource.findByIdSync(encounter.patientId);
    if (detailMode && patient != null) {
      return ClinicalEncounterIdentityBand.fromPatientDetail(
        encounter: encounter,
        patient: patient,
        trailing: trailing,
      );
    }

    String? demographic;
    var tags = const <String>[];
    if (patient != null) {
      demographic = PatientDisplayHelpers.formatListDemographicLine(patient);
      tags = patient.tags;
    }

    final d = encounter.createdAt;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final meta =
        '$dateLabel · ${encounter.visitType.label} · ${encounter.status.label}';

    return ClinicalEncounterIdentityBand(
      patientName: encounter.patientName,
      demographicLine: demographic,
      patientTags: tags,
      maxPatientTags: 3,
      contextMetaLine: meta,
      showPatientTags: !detailMode,
      trailing: trailing,
    );
  }

  factory ClinicalEncounterIdentityBand.fromPatientDetail({
    required ClinicalEncounter encounter,
    required Patient patient,
    Widget? trailing,
  }) {
    final name = patient.fullName.trim().isNotEmpty
        ? patient.fullName.trim()
        : encounter.patientName;

    final d = encounter.createdAt;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final protocolPrefix = encounter.hasProtocolNumber
        ? '${encounter.displayProtocolNumber} · '
        : '';
    final meta =
        '$protocolPrefix$dateLabel · ${encounter.visitType.label} · ${encounter.status.label}';

    return ClinicalEncounterIdentityBand(
      patientName: name,
      demographicLine: PatientDisplayHelpers.formatEncounterIdentityDemographyLine(
        patient,
      ),
      maskedIdentityLine: PatientIdentityPrivacy.maskedNationalIdLine(patient),
      contextMetaLine: meta,
      showPatientTags: false,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: PremiumSurface.contentHeaderBand(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (demographicLine != null &&
                        demographicLine!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        demographicLine!.trim(),
                        style: bodyStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (maskedIdentityLine != null &&
                        maskedIdentityLine!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        maskedIdentityLine!.trim(),
                        style: bodyStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          if (!compact && showPatientTags && _visibleTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final tag in _visibleTags)
                  ClinicalTagChip(label: tag),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            compact
                ? (encounterDateLabel ?? '')
                : (contextMetaLine ?? ''),
            style: bodyStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<String> get _visibleTags {
    if (patientTags.isEmpty) return const [];
    final limit = maxPatientTags.clamp(1, 3);
    return patientTags.take(limit).toList();
  }
}

/// Muayene detay — remote/mock hasta okuması ile kimlik bandı.
class ClinicalEncounterIdentityBandFromEncounter extends StatelessWidget {
  final ClinicalEncounter encounter;
  final Widget? trailing;
  final bool detailMode;

  const ClinicalEncounterIdentityBandFromEncounter({
    super.key,
    required this.encounter,
    this.trailing,
    this.detailMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return PatientLookupBuilder(
      patientId: encounter.patientId,
      builder: (context, patient) {
        if (detailMode && patient != null) {
          return ClinicalEncounterIdentityBand.fromPatientDetail(
            encounter: encounter,
            patient: patient,
            trailing: trailing,
          );
        }

        String? demographic;
        var tags = const <String>[];
        if (patient != null) {
          demographic = PatientDisplayHelpers.formatListDemographicLine(patient);
          tags = patient.tags;
        }

        final d = encounter.createdAt;
        final dateLabel =
            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
        final meta =
            '$dateLabel · ${encounter.visitType.label} · ${encounter.status.label}';

        return ClinicalEncounterIdentityBand(
          patientName: encounter.patientName,
          demographicLine: demographic,
          patientTags: tags,
          maxPatientTags: 3,
          contextMetaLine: meta,
          showPatientTags: !detailMode,
          trailing: trailing,
        );
      },
    );
  }
}
