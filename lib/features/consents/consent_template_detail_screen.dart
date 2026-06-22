import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_repository_failure.dart';
import 'data/consent_template_list_user_messages.dart';
import 'data/consent_template_repository_provider.dart';
import 'models/consent_record.dart';
import 'models/consent_template.dart';

class ConsentTemplateDetailScreen extends StatefulWidget {
  final String id;

  const ConsentTemplateDetailScreen({super.key, required this.id});

  @override
  State<ConsentTemplateDetailScreen> createState() =>
      _ConsentTemplateDetailScreenState();
}

class _ConsentTemplateDetailScreenState
    extends State<ConsentTemplateDetailScreen> {
  late Future<ConsentTemplate?> _loadFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture =
          ConsentTemplateRepositoryProvider.asyncRepository.getById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Form Şablonu',
      child: FutureBuilder<ConsentTemplate?>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return ClinicalStateMessage.loading(
              message: ConsentTemplateListUserMessages.loading,
            );
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ConsentRepositoryException
                ? ConsentTemplateListUserMessages.forFailure(
                    (snapshot.error as ConsentRepositoryException).reason,
                  )
                : ConsentTemplateListUserMessages.genericLoadFailure;
            return ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Form şablonu yüklenemedi',
              description: message,
              onRetry: _reload,
            );
          }

          final t = snapshot.data;
          if (t == null) {
            return ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: 'Form şablonu bulunamadı',
              description: 'Kayıt silinmiş veya erişim yetkiniz olmayabilir.',
            );
          }

          return _buildContent(context, t);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConsentTemplate t) {
    final createdStr = _formatDate(t.createdAt);
    final updatedStr = _formatDate(t.updatedAt);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ResponsiveDetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Onam Form Şablonu',
            icon: Icons.article_outlined,
            leadingBack: true,
            fallbackRoute: '/consent-templates',
          ),
          DetailHeaderCard(
            title: t.title,
            subtitle: '${t.category} • v${t.version}',
          ),
          Text(
            'Bu form şablonu klinik tarafından doğrulanmış içerik kullanır; '
            'hukuki metin değişikliklerinde sürüm güncellenmelidir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
          ClinicalStackedSections(
            children: [
              InfoSectionCard(
                title: 'Şablon Bilgisi',
                rows: [
                  InfoSectionRow(
                    'Form adı',
                    displayField(t.title),
                    emphasize: true,
                  ),
                  InfoSectionRow('Versiyon', displayField(t.version)),
                  InfoSectionRow(
                    'Durum',
                    t.isActive ? 'Aktif' : 'Pasif',
                  ),
                  InfoSectionRow('Oluşturulma', createdStr),
                  InfoSectionRow('Son güncelleme', updatedStr),
                ],
              ),
              InfoSectionCard(
                title: 'Kullanım Alanı',
                rows: [
                  InfoSectionRow('Kategori', displayField(t.category)),
                  InfoSectionRow(
                    'Gerekli olduğu durum',
                    displayField(t.requiredFor),
                  ),
                  InfoSectionRow(
                    'Açıklama',
                    displayField(t.description),
                  ),
                ],
              ),
              InfoSectionCard(
                title: 'Şablon İçeriği',
                rows: [
                  InfoSectionRow(
                    'Dosya adı',
                    displayField(t.documentFileName),
                  ),
                  InfoSectionRow(
                    'İçerik önizlemesi',
                    displayField(t.contentPreview),
                    emphasize: true,
                  ),
                ],
              ),
              InfoSectionCard(
                title: 'Hazırlama / Hasta İçin Kullanım',
                rows: [
                  InfoSectionRow(
                    'İlgili onam tipi',
                    consentTypeLabelFromCategory(t.category),
                  ),
                ],
              ),
              InfoSectionCard(
                title: 'Ek Notlar',
                rows: [
                  InfoSectionRow(
                    'Notlar',
                    t.notes == null || t.notes!.trim().isEmpty
                        ? kDisplayUnspecified
                        : t.notes!.trim(),
                  ),
                ],
              ),
            ],
          ),
          DetailActionsPanel(
            title: 'İşlemler',
            topSpacing: 0,
            actions: [
              if (AuthSession.canEditConsents)
                DetailAction(
                  label: DetailActionLabels.consentCreate,
                  filled: true,
                  onPressed: () =>
                      context.push('/consent-templates/prepare/${t.id}'),
                ),
              if (AuthSession.canEditClinicalEncounters)
                DetailAction(
                  label: DetailActionLabels.edit,
                  onPressed: () =>
                      context.push('/consent-templates/${t.id}/edit'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

String consentTypeLabelFromCategory(String category) {
  return consentTypeLabel(consentTypeFromTemplateCategory(category));
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
