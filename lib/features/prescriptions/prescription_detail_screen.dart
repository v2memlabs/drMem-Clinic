import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

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
import 'data/prescription_detail_data_source.dart';
import 'data/prescription_list_refresh.dart';
import 'data/prescription_user_messages.dart';
import 'models/prescription.dart';
import '../pdf_outputs/data/clinical_pdf_patient_identity.dart';
import 'services/prescription_pdf_generator.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String id;

  const PrescriptionDetailScreen({super.key, required this.id});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  late Future<PrescriptionDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PrescriptionListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = PrescriptionDetailDataSource.load(widget.id);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (PrescriptionListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = PrescriptionListRefresh.version;
      setState(() {
        _loadFuture = PrescriptionDetailDataSource.load(widget.id);
      });
    }
  }

  Future<void> _previewPdf(
    Prescription prescription,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) async {
    try {
      final result = await PrescriptionPdfGenerator.instance.generate(
        prescription: prescription,
        patientIdentityNumber: patientIdentityNumber,
        patientFileNumber: fileNo,
        clinicalEncounterProtocolNumber: encounter?.hasProtocolNumber == true
            ? encounter!.displayProtocolNumber
            : null,
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
    return FutureBuilder<PrescriptionDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Reçete',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final prescription = result?.prescription;
        if (snapshot.hasError || result == null || result.hasError || prescription == null) {
          return AppShell(
            title: 'Reçete',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Reçete kaydı bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? PrescriptionUserMessages.notFound,
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = PrescriptionDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        return PatientLookupBuilder(
          patientId: prescription.patientId,
          builder: (context, patient) {
            final fileNo = patient?.fileNumber ?? '';
            final identityNumber =
                ClinicalPdfPatientIdentity.turkishNationalIdForPdf(patient);
            return ClinicalEncounterLookupBuilder(
              encounterId: prescription.clinicalEncounterId,
              builder: (context, encounter) => _buildBody(
                context,
                prescription,
                fileNo,
                encounter: encounter,
                patientIdentityNumber: identityNumber,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    Prescription prescription,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) {
    final encounterId = prescription.clinicalEncounterId?.trim() ?? '';

    return AppShell(
      title: 'Reçete',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Reçete',
              icon: Icons.medication_outlined,
              leadingBack: true,
              fallbackRoute: '/prescriptions',
            ),
            DetailHeaderCard(
              title: prescription.patientName,
              subtitle: prescription.diagnosis.trim().isEmpty
                  ? 'Tanı belirtilmedi'
                  : prescription.diagnosis.trim(),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Reçete Bilgisi',
                  rows: [
                    InfoSectionRow(
                      'Durum',
                      prescriptionStatusLabel(prescription.status),
                      emphasize: true,
                    ),
                    InfoSectionRow('Hekim', prescription.createdBy),
                    InfoSectionRow(
                      'Oluşturulma',
                      _formatDate(prescription.createdAt),
                    ),
                    if (encounter != null) ...[
                      if (encounter.hasProtocolNumber)
                        InfoSectionRow(
                          'Muayene protokol',
                          encounter.displayProtocolNumber,
                          emphasize: true,
                        ),
                      InfoSectionRow(
                        'Muayene kaydı',
                        '${_formatDate(encounter.createdAt)} • ${encounter.visitType.label}',
                      ),
                    ],
                  ],
                ),
                InfoSectionCard(
                  title: 'İlaçlar',
                  rows: prescription.medications.isEmpty
                      ? [const InfoSectionRow('İlaç', 'Kayıt yok')]
                      : prescription.medications
                          .asMap()
                          .entries
                          .map(
                            (entry) => InfoSectionRow(
                              '${entry.key + 1}. ${entry.value.name}',
                              [
                                entry.value.dose,
                                entry.value.frequency,
                                entry.value.duration,
                              ].where((s) => s.trim().isNotEmpty).join(' • '),
                            ),
                          )
                          .toList(),
                ),
                if (prescription.additionalNotes != null &&
                    prescription.additionalNotes!.trim().isNotEmpty)
                  InfoSectionCard(
                    title: 'Ek Notlar',
                    rows: [
                      InfoSectionRow('Not', prescription.additionalNotes!.trim()),
                    ],
                  ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                DetailAction(
                  label: 'PDF Çıktısı Al',
                  filled: true,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () => _previewPdf(
                    prescription,
                    fileNo,
                    encounter: encounter,
                    patientIdentityNumber: patientIdentityNumber,
                  ),
                ),
                DetailAction(
                  label: 'Düzenle',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push(
                    '/prescriptions/${prescription.id}/edit',
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}
