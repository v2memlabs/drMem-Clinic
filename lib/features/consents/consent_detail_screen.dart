import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_detail_data_source.dart';
import 'data/consent_detail_load_result.dart';
import 'data/consent_detail_user_messages.dart';
import 'data/consent_pdf_lookup_data_source.dart';
import 'data/consent_list_refresh.dart';
import 'models/consent_record.dart';
import 'models/consent_signature_mode.dart';
import 'widgets/consent_signature_actions_panel.dart';
import '../../features/pdf_outputs/data/pdf_output_view_launcher.dart';
import '../../features/pdf_outputs/models/pdf_output.dart';

class ConsentDetailScreen extends StatefulWidget {
  final String id;
  const ConsentDetailScreen({super.key, required this.id});

  @override
  State<ConsentDetailScreen> createState() => _ConsentDetailScreenState();
}

class _ConsentDetailScreenState extends State<ConsentDetailScreen> {
  late Future<ConsentDetailLoadResult> _loadFuture;
  ConsentDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ConsentListRefresh.version;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (ConsentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = ConsentListRefresh.version;
    setState(() {
      _loadFuture = ConsentDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConsentDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return AppShell(
            title: 'Onam',
            child: ClinicalStateMessage.loading(
              message: ConsentDetailUserMessages.loading,
            ),
          );
        }

        if (result != null && !result.hasError && result.record != null) {
          _cachedResult = result;
        }

        final active = _cachedResult ?? result;
        if (active == null) {
          return AppShell(
            title: 'Onam',
            child: ClinicalStateMessage.loading(
              message: ConsentDetailUserMessages.loading,
            ),
          );
        }

        if (active.hasError) {
          return AppShell(
            title: 'Onam',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: ConsentDetailUserMessages.errorTitle,
              description: ClinicalStateMessage.safeErrorDescription(
                active.errorMessage,
              ),
              onRetry: _reload,
            ),
          );
        }

        if (active.notFound || active.record == null) {
          return AppShell(
            title: 'Onam',
            child: ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: ConsentDetailUserMessages.notFoundTitle,
              description: ConsentDetailUserMessages.notFoundDescription,
            ),
          );
        }

        return _buildContent(active.record!);
      },
    );
  }

  Widget _buildContent(ConsentRecord c) {
    return PatientLookupBuilder(
      patientId: c.patientId,
      builder: (context, patient) {
        final fileNo = patient?.fileNumber ?? '';
        return _buildConsentDetailBody(c, fileNo);
      },
    );
  }

  Widget _buildConsentDetailBody(ConsentRecord c, String fileNo) {
    final createdStr = _formatDateTime(c.createdAt);
    final givenStr = c.givenAt != null
        ? _formatDateTime(c.givenAt!)
        : kDisplayUnspecified;
    final expiresStr = c.expiresAt != null
        ? _formatDate(c.expiresAt!)
        : kDisplayUnspecified;

    return AppShell(
      title: 'Onam Detayı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Onam Detayı',
              icon: Icons.assignment_turned_in_outlined,
              leadingBack: true,
              fallbackRoute: '/consents',
            ),
            DetailHeaderCard(
              title: consentTypeLabel(c.consentType),
              subtitle: c.patientName,
            ),
            _ConsentPdfActions(consent: c),
            ConsentSignatureActionsPanel(
              consent: c,
              onSigned: _reload,
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Hasta ve Onam Bilgisi',
                  rows: [
                    InfoSectionRow('Hasta', c.patientName, emphasize: true),
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    InfoSectionRow('Kayıt tarihi', createdStr),
                    InfoSectionRow('Kaydeden', displayField(c.recordedBy)),
                  ],
                ),
                InfoSectionCard(
                  title: 'Onam Detayı',
                  rows: [
                    InfoSectionRow(
                      'Onam tipi',
                      consentTypeLabel(c.consentType),
                      emphasize: true,
                    ),
                    InfoSectionRow(
                      'Belge',
                      c.documentFileName == null ||
                              c.documentFileName!.trim().isEmpty
                          ? kDisplayUnspecified
                          : c.documentFileName!.trim(),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'İmza / Onay Durumu',
                  rows: [
                    InfoSectionRow(
                      'Durum',
                      consentStatusLabel(c.status),
                      emphasize: true,
                    ),
                    InfoSectionRow('Alınma tarihi', givenStr),
                    InfoSectionRow('Geçerlilik sonu', expiresStr),
                    InfoSectionRow(
                      'İmza modu',
                      consentSignatureModeLabel(c.signatureMode),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Ek Notlar',
                  rows: [
                    InfoSectionRow(
                      'Notlar',
                      c.notes == null || c.notes!.trim().isEmpty
                          ? kDisplayUnspecified
                          : c.notes!.trim(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ConsentPdfActions extends StatelessWidget {
  final ConsentRecord consent;

  const _ConsentPdfActions({required this.consent});

  @override
  Widget build(BuildContext context) {
    if (consent.documentFileName == null ||
        consent.documentFileName!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FutureBuilder<PdfOutput?>(
        future: ConsentPdfLookupDataSource.findPdfForConsent(consent),
        builder: (context, snapshot) {
          final pdf = snapshot.data;
          final fileLabel = consent.documentFileName!.trim();

          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (pdf != null)
                FilledButton.tonalIcon(
                  onPressed: () => _openPdf(context, pdf),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF Aç'),
                ),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/pdf-outputs?patientId=${consent.patientId}',
                ),
                icon: const Icon(Icons.list_outlined),
                label: Text('PDF listesi ($fileLabel)'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, PdfOutput output) async {
    try {
      await PdfOutputViewLauncher.openStoredPdf(output);
    } on PdfOutputViewException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF açılırken bir sorun oluştu.')),
      );
    }
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${_formatDate(local)} $time';
}
