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
import 'data/radiology_order_detail_data_source.dart';
import 'data/radiology_order_list_refresh.dart';
import 'data/radiology_order_user_messages.dart';
import 'models/radiology_order.dart';
import 'services/radiology_order_pdf_generator.dart';

class RadiologyOrderDetailScreen extends StatefulWidget {
  final String id;
  const RadiologyOrderDetailScreen({super.key, required this.id});

  @override
  State<RadiologyOrderDetailScreen> createState() =>
      _RadiologyOrderDetailScreenState();
}

class _RadiologyOrderDetailScreenState extends State<RadiologyOrderDetailScreen> {
  late Future<RadiologyOrderDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = RadiologyOrderListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = RadiologyOrderDetailDataSource.load(widget.id);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (RadiologyOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = RadiologyOrderListRefresh.version;
      setState(() {
        _loadFuture = RadiologyOrderDetailDataSource.load(widget.id);
      });
    }
  }

  Future<void> _previewPdf(
    RadiologyOrder order,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) async {
    try {
      final result = await RadiologyOrderPdfGenerator.instance.generate(
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

  Future<void> _deleteOrder(RadiologyOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İstemi sil'),
        content: const Text(
          'Bu radyoloji istemi silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await RadiologyOrderDetailDataSource.delete(order.id);
    if (!mounted) return;
    if (error != null) {
      showClinicalSnackBar(context, error, isError: true);
      return;
    }
    showClinicalSnackBar(context, 'İstem silindi.');
    context.go('/radiology-orders');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RadiologyOrderDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Radyoloji İstemi',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || result.hasError) {
          return AppShell(
            title: 'Radyoloji İstemi',
            child: Center(
              child: ClinicalStateMessage.error(
                icon: Icons.error_outline,
                title: 'İstem yüklenemedi',
                description: ClinicalStateMessage.safeErrorDescription(
                  result?.errorMessage ??
                      RadiologyOrderUserMessages.genericLoadFailure,
                ),
                onRetry: () => setState(() {
                  _loadFuture =
                      RadiologyOrderDetailDataSource.load(widget.id);
                }),
              ),
            ),
          );
        }

        final order = result.order;
        if (order == null) {
          return const AppShell(
            title: 'Radyoloji İstemi',
            child: Center(child: Text('İstem bulunamadı.')),
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
    RadiologyOrder order,
    String fileNo, {
    ClinicalEncounter? encounter,
    String? patientIdentityNumber,
  }) {
    final encounterId = order.clinicalEncounterId?.trim() ?? '';

    return AppShell(
      title: 'Radyoloji İstemi',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Radyoloji İstemi',
              icon: Icons.radar_outlined,
              leadingBack: true,
              fallbackRoute: '/radiology-orders',
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
                    InfoSectionRow(
                      'Tanı',
                      order.diagnosis.trim().isEmpty
                          ? '—'
                          : order.diagnosis.trim(),
                    ),
                    InfoSectionRow(
                      'Öncelik',
                      radiologyPriorityLabel(order.priority),
                    ),
                    InfoSectionRow('İstem yapan', order.createdBy),
                    if (_resolveProtocolNumber(order, encounter)
                        case final protocol?)
                      InfoSectionRow(
                        'Muayene protokol',
                        protocol,
                        emphasize: true,
                      ),
                    if (encounter != null)
                      InfoSectionRow(
                        'Muayene',
                        _formatDate(encounter.createdAt),
                      ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Görüntülemeler',
                  rows: order.lines
                      .map(
                        (line) => InfoSectionRow(
                          radiologyModalityLabel(line.modality),
                          '${line.bodyRegion} • ${radiologySideLabel(line.side)} • ${line.clinicalIndication}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                if (AuthSession.canViewRadiologyOrders)
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
                if (AuthSession.canEditRadiologyOrders)
                  DetailAction(
                    label: 'Düzenle',
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        context.push('/radiology-orders/${order.id}/edit'),
                  ),
                if (AuthSession.canEditRadiologyOrders)
                  DetailAction(
                    label: 'Sil',
                    icon: Icons.delete_outline,
                    onPressed: () => _deleteOrder(order),
                  ),
                if (encounterId.isNotEmpty &&
                    AuthSession.canViewClinicalEncounters)
                  DetailAction(
                    label: 'Muayene Kaydına Git',
                    icon: Icons.assignment_outlined,
                    onPressed: () =>
                        context.push('/clinical-records/$encounterId'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveProtocolNumber(
    RadiologyOrder order,
    ClinicalEncounter? encounter,
  ) {
    final snapshot = order.displayProtocolNumber;
    if (snapshot != null) return snapshot;
    if (encounter?.hasProtocolNumber == true) {
      return encounter!.displayProtocolNumber;
    }
    return null;
  }

  String _headerSubtitle(RadiologyOrder order) {
    final protocol = order.displayProtocolNumber;
    if (protocol != null) {
      return '${radiologyOrderStatusLabel(order.status)} • Protokol: $protocol';
    }
    return radiologyOrderStatusLabel(order.status);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
