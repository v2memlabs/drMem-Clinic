import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'data/message_channel_launcher.dart';
import 'data/sent_message_detail_data_source.dart';
import 'data/sent_message_list_refresh.dart';
import 'data/sent_message_user_messages.dart';
import 'models/sent_message.dart';
import 'widgets/message_preview_dialog.dart';

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
  bool _launching = false;

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

  String _messageBody(SentMessage message) {
    final full = message.content.trim();
    if (full.isNotEmpty) return full;
    return message.contentPreview.trim();
  }

  Future<void> _copyContent(SentMessage message) async {
    final body = _messageBody(message);
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak mesaj içeriği yok.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mesaj içeriği panoya kopyalandı.')),
    );
  }

  Future<void> _openInChannel(SentMessage message) async {
    if (_launching) return;

    final body = _messageBody(message);
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kanalda açılacak mesaj içeriği yok.')),
      );
      return;
    }

    final recipientError = MessageChannelLauncher.validateRecipient(
      channelLabel: message.channel,
      phone: message.patientPhone,
      email: message.patientEmail,
    );
    if (recipientError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recipientError)),
      );
      return;
    }

    setState(() => _launching = true);
    final launched = await MessageChannelLauncher.launch(
      channelLabel: message.channel,
      phone: message.patientPhone,
      email: message.patientEmail,
      body: body,
      subject: message.templateTitle,
    );
    if (!mounted) return;
    setState(() => _launching = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MessageChannelLaunchFailure.launchFailed.userMessage,
          ),
        ),
      );
    }
  }

  Future<void> _previewMessage(SentMessage message) async {
    final body = _messageBody(message);
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önizlenecek mesaj içeriği yok.')),
      );
      return;
    }

    await MessagePreviewDialog.show(
      context,
      channel: message.channel,
      phone: message.patientPhone,
      email: message.patientEmail,
      content: body,
      confirmSend: false,
    );
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
          final messageBody = _messageBody(m);

          return PatientLookupBuilder(
            patientId: m.patientId,
            builder: (context, patient) {
              final fileNo = patient?.fileNumber ?? '';
              return _buildSentMessageBody(
                context,
                m,
                sentStr,
                fileNo,
                messageBody,
              );
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
    String messageBody,
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
                  if (m.patientEmail.trim().isNotEmpty)
                    InfoSectionRow('E-posta', displayField(m.patientEmail)),
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
                    messageBody.length > 200 ? 'İçerik' : 'Önizleme',
                    displayField(messageBody),
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
                label: 'Kanalda Aç',
                filled: true,
                onPressed: _launching ? null : () => _openInChannel(m),
              ),
              DetailAction(
                label: 'İçeriği Kopyala',
                onPressed: () => _copyContent(m),
              ),
              DetailAction(
                label: 'Önizle',
                onPressed: () => _previewMessage(m),
              ),
              DetailAction(
                label: 'Tekrar Hazırla',
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
