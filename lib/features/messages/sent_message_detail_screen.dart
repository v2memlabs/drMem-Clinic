import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/sent_message_detail_data_source.dart';
import 'data/sent_message_list_refresh.dart';
import 'data/sent_message_user_messages.dart';
import 'models/sent_message.dart';

class SentMessageDetailScreen extends StatefulWidget {
  final String id;
  const SentMessageDetailScreen({super.key, required this.id});

  @override
  State<SentMessageDetailScreen> createState() =>
      _SentMessageDetailScreenState();
}

class _SentMessageDetailScreenState extends State<SentMessageDetailScreen> {
  late Future<SentMessageDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = SentMessageListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = SentMessageDetailDataSource.load(widget.id);
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (SentMessageListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = SentMessageListRefresh.version;
      setState(() {
        _loadFuture = SentMessageDetailDataSource.load(widget.id);
      });
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = SentMessageDetailDataSource.load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gönderim Detayı',
      child: FutureBuilder<SentMessageDetailLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final result = snapshot.data;
          if (snapshot.hasError || result == null || result.hasError) {
            return ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Gönderim kaydı yüklenemedi',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ??
                    SentMessageUserMessages.genericLoadFailure,
              ),
              onRetry: _reload,
            );
          }

          final m = result.message;
          if (m == null) {
            return ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: SentMessageUserMessages.notFound,
            );
          }

          final sentStr = _formatDateTime(m.sentAt);

          return PatientLookupBuilder(
            patientId: m.patientId,
            builder: (context, patient) {
              final fileNo = patient?.fileNumber ?? '';
              return _buildSentMessageBody(context, m, sentStr, fileNo);
            },
          );
        },
      ),
    );
  }

  Widget _buildSentMessageBody(
    BuildContext context,
    SentMessage m,
    String sentStr,
    String fileNo,
  ) {
    return ResponsiveDetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Gönderim Detayı',
            icon: Icons.mail_outline,
            leadingBack: true,
            fallbackRoute: '/messages/sent',
          ),
          DetailHeaderCard(
            title: m.patientName,
            subtitle: sentStr,
          ),
          ClinicalStackedSections(
            children: [
              InfoSectionCard(
                title: 'Hasta ve Alıcı Bilgisi',
                rows: [
                  InfoSectionRow('Hasta', m.patientName, emphasize: true),
                  InfoSectionRow(
                    'Hasta dosya no',
                    fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                  ),
                  InfoSectionRow('Telefon', displayField(m.patientPhone)),
                  InfoSectionRow('Gönderen', displayField(m.sentBy)),
                  InfoSectionRow('Kanal', m.channel),
                  InfoSectionRow('Kategori', m.category),
                ],
              ),
              InfoSectionCard(
                title: 'Gönderim Detayı',
                rows: [
                  InfoSectionRow(
                    'Durum',
                    sendStatusLabel(m.status),
                    emphasize: true,
                  ),
                  InfoSectionRow('Gönderim tarihi', sentStr),
                  InfoSectionRow(
                    'Şablon',
                    displayField(m.templateTitle),
                  ),
                  if (m.relatedModule.trim().isNotEmpty)
                    InfoSectionRow('İlgili modül', m.relatedModule),
                ],
              ),
              InfoSectionCard(
                title: 'Mesaj İçeriği',
                rows: [
                  InfoSectionRow(
                    'Önizleme',
                    displayField(m.contentPreview),
                    emphasize: true,
                  ),
                  InfoSectionRow('Notlar', displayField(m.notes)),
                ],
              ),
            ],
          ),
          DetailActionsPanel(
            title: 'İşlemler',
            topSpacing: 0,
            actions: [
              DetailAction(
                label: 'Tekrar Hazırla',
                filled: true,
                onPressed: () => context.push(
                  '/messages/send?patientId=${m.patientId}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
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
