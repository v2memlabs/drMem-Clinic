import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/auth/auth_session.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../clinical_encounter/models/clinical_encounter.dart';
import '../clinical_encounter/widgets/clinical_encounter_lookup_builder.dart';
import 'data/clinical_report_detail_data_source.dart';
import 'data/clinical_report_document_date_resolver.dart';
import 'data/clinical_report_istirahat_body_template.dart';
import 'data/clinical_report_list_refresh.dart';
import 'data/clinical_report_pdf_patient_identity.dart';
import 'data/clinical_report_user_messages.dart';
import 'models/clinical_report.dart';
import 'services/clinical_report_pdf_generator.dart';

class ClinicalReportDetailScreen extends StatefulWidget {
  final String id;

  const ClinicalReportDetailScreen({super.key, required this.id});

  @override
  State<ClinicalReportDetailScreen> createState() =>
      _ClinicalReportDetailScreenState();
}

class _ClinicalReportDetailScreenState extends State<ClinicalReportDetailScreen> {
  late Future<ClinicalReportDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ClinicalReportListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = ClinicalReportDetailDataSource.load(widget.id);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (ClinicalReportListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = ClinicalReportListRefresh.version;
      setState(() {
        _loadFuture = ClinicalReportDetailDataSource.load(widget.id);
      });
    }
  }

  Future<void> _previewPdf(
    ClinicalReport report, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) async {
    try {
      final result = await ClinicalReportPdfGenerator.instance.generate(
        report: report,
        patientIdentityNumber: patientIdentityNumber,
        clinicalEncounterProtocolNumber: _resolveProtocolNumber(
          report,
          encounter,
        ),
        encounterDate: encounter?.createdAt,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        name: result.fileName,
        onLayout: (_) async => result.bytes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF oluşturulurken bir sorun oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClinicalReportDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Rapor',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || result.hasError) {
          return AppShell(
            title: 'Rapor',
            child: Center(
              child: ClinicalStateMessage.error(
                icon: Icons.error_outline,
                title: 'Rapor yüklenemedi',
                description: ClinicalStateMessage.safeErrorDescription(
                  result?.errorMessage ??
                      ClinicalReportUserMessages.genericLoadFailure,
                ),
                onRetry: () => setState(() {
                  _loadFuture =
                      ClinicalReportDetailDataSource.load(widget.id);
                }),
              ),
            ),
          );
        }

        final report = result.report;
        if (report == null) {
          return const AppShell(
            title: 'Rapor',
            child: Center(child: Text('Rapor kaydı bulunamadı.')),
          );
        }

        return PatientLookupBuilder(
          patientId: report.patientId,
          builder: (context, patient) {
            return ClinicalEncounterLookupBuilder(
              encounterId: report.clinicalEncounterId,
              builder: (context, encounter) => _buildBody(
                context,
                report,
                ClinicalReportPdfPatientIdentity.turkishNationalIdForPdf(patient),
                encounter: encounter,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClinicalReport report,
    String? patientIdentityNumber, {
    ClinicalEncounter? encounter,
  }) {
    final encounterId = report.clinicalEncounterId?.trim() ?? '';

    return AppShell(
      title: 'Rapor',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Rapor',
              icon: Icons.description_outlined,
              leadingBack: true,
              fallbackRoute: '/clinical-reports',
            ),
            DetailHeaderCard(
              title: clinicalReportTypeLabel(report.reportType),
              subtitle: _headerSubtitle(report),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Rapor Bilgisi',
                  rows: [
                    InfoSectionRow(
                      'Durum',
                      clinicalReportStatusLabel(report.status),
                      emphasize: true,
                    ),
                    InfoSectionRow('Tanı', report.diagnosis.trim().isEmpty
                        ? 'Belirtilmedi'
                        : report.diagnosis.trim()),
                    InfoSectionRow('Hekim', report.createdBy),
                    InfoSectionRow(
                      'PDF tarihi',
                      ClinicalReportDocumentDateResolver.resolveLabel(
                        report: report,
                        generatedAt: DateTime.now(),
                        encounterDate: encounter?.createdAt,
                      ),
                    ),
                    InfoSectionRow(
                      'Tarih kaynağı',
                      clinicalReportDocumentDateSourceLabel(report.documentDateSource),
                    ),
                    if (report.displayReportNumber case final reportNo?)
                      InfoSectionRow('Rapor no', reportNo, emphasize: true),
                    InfoSectionRow('Oluşturulma', _formatDate(report.createdAt)),
                    if (_resolveProtocolNumber(report, encounter) case final protocol?)
                      InfoSectionRow(
                        'Muayene protokol',
                        protocol,
                        emphasize: true,
                      ),
                    if (encounter != null)
                      InfoSectionRow(
                        'Muayene kaydı',
                        '${_formatDate(encounter.createdAt)} • ${encounter.visitType.label}',
                      ),
                  ],
                ),
                ..._typeSpecificCards(report),
                InfoSectionCard(
                  title: clinicalReportPdfSalutation,
                  rows: [InfoSectionRow('İçerik', report.bodyText.trim())],
                ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                if (AuthSession.canViewClinicalReports)
                  DetailAction(
                    label: 'PDF Çıktısı Al',
                    filled: true,
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: () => _previewPdf(
                      report,
                      encounter: encounter,
                      patientIdentityNumber: patientIdentityNumber,
                    ),
                  ),
                if (AuthSession.canEditClinicalReports)
                  DetailAction(
                    label: 'Düzenle',
                    icon: Icons.edit_outlined,
                    onPressed: () => context.push(
                      '/clinical-reports/${report.id}/edit',
                    ),
                  ),
                if (encounterId.isNotEmpty)
                  DetailAction(
                    label: 'Muayene Kaydına Git',
                    icon: Icons.assignment_outlined,
                    onPressed: () => context.push('/clinical-records/$encounterId'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _typeSpecificCards(ClinicalReport report) {
    switch (report.reportType) {
      case ClinicalReportType.istirahat:
        return [
          InfoSectionCard(
            title: 'İstirahat Bilgileri',
            rows: [
              if (report.treatmentApproach != null)
                InfoSectionRow(
                  'Tedavi',
                  treatmentApproachLabel(report.treatmentApproach!),
                ),
              if (report.startDate != null &&
                  report.endDate != null &&
                  report.restDays != null)
                InfoSectionRow(
                  'İstirahat',
                  '${_formatDate(report.startDate!)} – ${_formatDate(report.endDate!)} '
                  '(${report.restDays} gün)',
                ),
              if (report.endDate != null)
                InfoSectionRow(
                  'İşe başlama',
                  ClinicalReportIstirahatBodyTemplate.returnToWorkDateLabel(
                    report.endDate!,
                  ).replaceFirst('İşe başlama tarihi: ', ''),
                ),
            ],
          ),
        ];
      case ClinicalReportType.durumBildirir:
        return [
          InfoSectionCard(
            title: 'Durum Bildirir Bilgileri',
            rows: [
              if (report.treatmentApproach != null)
                InfoSectionRow(
                  'Tedavi',
                  treatmentApproachLabel(report.treatmentApproach!),
                ),
              if (report.statusDuration != null &&
                  report.statusDuration!.trim().isNotEmpty)
                InfoSectionRow('Süre', report.statusDuration!.trim()),
              if (report.statusRecommendation != null &&
                  report.statusRecommendation!.trim().isNotEmpty)
                InfoSectionRow(
                  'Öneri / kısıtlama',
                  report.statusRecommendation!.trim(),
                ),
              if (report.statusSuitability != null)
                InfoSectionRow(
                  'Uygunluk',
                  statusSuitabilityFormLabel(report.statusSuitability!),
                ),
            ],
          ),
        ];
      case ClinicalReportType.ucabilir:
        return [
          InfoSectionCard(
            title: 'Uçuş Değerlendirmesi',
            rows: [
              if (report.treatmentApproach != null)
                InfoSectionRow(
                  'Tedavi',
                  treatmentApproachLabel(report.treatmentApproach!),
                ),
              if (report.flightDecision != null)
                InfoSectionRow(
                  'Uçuş kararı',
                  flightDecisionFormLabel(report.flightDecision!),
                ),
              if (report.flightNotes != null &&
                  report.flightNotes!.trim().isNotEmpty)
                InfoSectionRow('Koşullar', report.flightNotes!.trim()),
            ],
          ),
        ];
      case ClinicalReportType.cihazKullanim:
        return [
          InfoSectionCard(
            title: 'Cihaz Kullanımı',
            rows: [
              if (report.treatmentApproach != null)
                InfoSectionRow(
                  'Tedavi',
                  treatmentApproachLabel(report.treatmentApproach!),
                ),
              InfoSectionRow('Cihaz', report.deviceName ?? 'Belirtilmedi'),
              if (report.deviceUsageDuration != null &&
                  report.deviceUsageDuration!.trim().isNotEmpty)
                InfoSectionRow('Süre', report.deviceUsageDuration!.trim()),
              if (report.deviceUsageNotes != null &&
                  report.deviceUsageNotes!.trim().isNotEmpty)
                InfoSectionRow('Kullanım', report.deviceUsageNotes!.trim()),
              if (report.weightBearing != null)
                InfoSectionRow(
                  'Yük bindirme',
                  weightBearingFormLabel(report.weightBearing!),
                ),
            ],
          ),
        ];
      case ClinicalReportType.diger:
        return [];
    }
  }

  String? _resolveProtocolNumber(
    ClinicalReport report,
    ClinicalEncounter? encounter,
  ) {
    final snapshot = report.displayProtocolNumber;
    if (snapshot != null) return snapshot;
    if (encounter?.hasProtocolNumber == true) {
      return encounter!.displayProtocolNumber;
    }
    return null;
  }

  String _headerSubtitle(ClinicalReport report) {
    final protocol = report.displayProtocolNumber;
    if (protocol != null) {
      return '${report.patientName} • Protokol: $protocol';
    }
    return report.patientName;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}
