import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/auth/auth_session.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../clinical_encounter/models/clinical_encounter.dart';
import '../clinical_encounter/widgets/clinical_encounter_lookup_builder.dart';
import '../pdf_outputs/data/clinical_pdf_patient_identity.dart';
import 'data/lab_order_catalog_gate.dart';
import 'data/lab_order_detail_data_source.dart';
import 'data/lab_order_list_refresh.dart';
import 'data/lab_test_selection.dart';
import 'models/lab_order.dart';
import 'models/lab_test_catalog.dart';
import 'services/lab_order_pdf_generator.dart';

class LabOrderDetailScreen extends StatefulWidget {
  final String id;
  const LabOrderDetailScreen({super.key, required this.id});

  @override
  State<LabOrderDetailScreen> createState() => _LabOrderDetailScreenState();
}

class _LabOrderDetailScreenState extends State<LabOrderDetailScreen> {
  late Future<LabOrderDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = LabOrderListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = LabOrderDetailDataSource.load(widget.id);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (LabOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderListRefresh.version;
      setState(() {
        _loadFuture = LabOrderDetailDataSource.load(widget.id);
      });
    }
  }

  Future<void> _previewPdf(
    LabOrder order,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) async {
    try {
      final result = await LabOrderPdfGenerator.instance.generate(
        order: order,
        patientIdentityNumber: patientIdentityNumber,
        patientFileNumber: fileNo,
        clinicalEncounterProtocolNumber: _resolveProtocolNumber(
          order,
          encounter,
        ),
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        name: result.fileName,
        onLayout: (_) async => result.bytes,
      );
    } catch (_) {
      if (!mounted) return;
      showClinicalSnackBar(context, 'PDF oluşturulamadı.', isError: true);
    }
  }

  Future<void> _deleteOrder(LabOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İstemi sil'),
        content: const Text('Bu laboratuvar istemi kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await LabOrderDetailDataSource.delete(order.id);
    if (!mounted) return;
    if (error != null) {
      showClinicalSnackBar(context, error, isError: true);
      return;
    }
    showClinicalSnackBar(context, 'İstem silindi.');
    context.go('/lab-orders');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LabOrderDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Laboratuvar İstemi',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final order = result?.order;
        if (snapshot.hasError || result == null || result.hasError || order == null) {
          return AppShell(
            title: 'Laboratuvar İstemi',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Laboratuvar istemi bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = LabOrderDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        return PatientLookupBuilder(
          patientId: order.patientId,
          builder: (context, patient) => ClinicalEncounterLookupBuilder(
            encounterId: order.clinicalEncounterId,
            builder: (context, encounter) => _buildBody(
              context,
              order,
              patient?.fileNumber ?? '',
              encounter: encounter,
              patientIdentityNumber:
                  ClinicalPdfPatientIdentity.turkishNationalIdForPdf(patient),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LabOrder order,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) {
    final encounterId = order.clinicalEncounterId?.trim() ?? '';

    final catalog = LabOrderCatalogGate.current;

    return AppShell(
      title: 'Laboratuvar İstemi',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Laboratuvar İstemi',
              icon: Icons.biotech_outlined,
              leadingBack: true,
              fallbackRoute: '/lab-orders',
            ),
            DetailHeaderCard(
              title: order.patientName,
              subtitle: _headerSubtitle(order),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'İstem Bilgisi',
                  rows: [
                    InfoSectionRow('Tanı', order.diagnosis.trim().isEmpty ? '—' : order.diagnosis.trim()),
                    InfoSectionRow('İstem sebebi', labOrderReasonLabel(order.orderReason)),
                    InfoSectionRow('İstem yapan', order.createdBy),
                    if (order.templateName != null)
                      InfoSectionRow('Şablon', order.templateName!),
                    if (order.infectionContext != InfectionContext.yok)
                      InfoSectionRow(
                        'Enfeksiyon',
                        infectionContextLabel(order.infectionContext),
                      ),
                    if (_resolveProtocolNumber(order, encounter) case final protocol?)
                      InfoSectionRow(
                        'Muayene protokol',
                        protocol,
                        emphasize: true,
                      ),
                    if (encounter != null)
                      InfoSectionRow('Muayene', _formatDate(encounter.createdAt)),
                  ],
                ),
                for (final group in LabTestGroup.values) ...[
                  if (LabTestSelection.codesForPdfGroup(group, order.selectedTests)
                      .isNotEmpty)
                    InfoSectionCard(
                      title: labTestGroupLabel(group),
                      rows: LabTestSelection.codesForPdfGroup(
                        group,
                        order.selectedTests,
                      )
                          .map((t) => InfoSectionRow(labTestCodeLabel(t), 'İstendi'))
                          .toList(),
                    ),
                  if (group == LabTestGroup.diger &&
                      order.selectedCustomTestIds.isNotEmpty)
                    InfoSectionCard(
                      title: 'Diğer (özel)',
                      rows: order.selectedCustomTestIds
                          .map(catalog.labelForCustomTest)
                          .whereType<String>()
                          .map((label) => InfoSectionRow(label, 'İstendi'))
                          .toList(),
                    ),
                ],
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
                    order,
                    fileNo,
                    encounter: encounter,
                    patientIdentityNumber: patientIdentityNumber,
                  ),
                ),
                if (AuthSession.canEditLabOrders)
                  DetailAction(
                    label: 'Düzenle',
                    icon: Icons.edit_outlined,
                    onPressed: () => context.push('/lab-orders/${order.id}/edit'),
                  ),
                if (AuthSession.canEditLabOrders)
                  DetailAction(
                    label: 'Sil',
                    icon: Icons.delete_outline,
                    onPressed: () => _deleteOrder(order),
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

  String? _resolveProtocolNumber(
    LabOrder order,
    ClinicalEncounter? encounter,
  ) {
    final snapshot = order.displayProtocolNumber;
    if (snapshot != null) return snapshot;
    if (encounter?.hasProtocolNumber == true) {
      return encounter!.displayProtocolNumber;
    }
    return null;
  }

  String _headerSubtitle(LabOrder order) {
    final protocol = order.displayProtocolNumber;
    if (protocol != null) {
      return '${labOrderStatusLabel(order.status)} • Protokol: $protocol';
    }
    return labOrderStatusLabel(order.status);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
