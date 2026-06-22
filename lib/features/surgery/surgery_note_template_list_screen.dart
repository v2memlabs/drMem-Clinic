import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/surgery_note_template_list_refresh.dart';
import 'data/surgery_note_template_repository_provider.dart';
import 'models/surgery_note_template.dart';

class SurgeryNoteTemplateListScreen extends StatefulWidget {
  const SurgeryNoteTemplateListScreen({super.key});

  @override
  State<SurgeryNoteTemplateListScreen> createState() =>
      _SurgeryNoteTemplateListScreenState();
}

class _SurgeryNoteTemplateListScreenState
    extends State<SurgeryNoteTemplateListScreen> {
  String _query = '';
  late Future<List<SurgeryNoteTemplate>> _loadFuture;
  int _lastRefresh = SurgeryNoteTemplateListRefresh.version;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (SurgeryNoteTemplateListRefresh.isStale(_lastRefresh)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefresh = SurgeryNoteTemplateListRefresh.version;
    setState(() {
      _loadFuture = SurgeryNoteTemplateRepositoryProvider.asyncRepository
          .search(_query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ameliyat Notu Şablonları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Ameliyat Notu Şablonları',
              icon: Icons.library_books_outlined,
              leadingBack: true,
              fallbackRoute: '/surgery-notes',
            ),
            FilterBar(
              searchHint: 'Şablon adı ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              trailing: FilledButton.icon(
                onPressed: () => context.push('/surgery-note-templates/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Şablon'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<SurgeryNoteTemplate>>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'Şablonlar yüklenemedi',
                      description: 'Lütfen tekrar deneyin.',
                      onRetry: _reload,
                    );
                  }

                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return ClinicalStateMessage.empty(
                      icon: Icons.library_books_outlined,
                      title: 'Şablon bulunamadı',
                      description:
                          'Sık kullandığınız ameliyat notu alanlarını şablon olarak kaydedin.',
                      action: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/surgery-note-templates/new'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yeni Şablon'),
                      ),
                    );
                  }

                  return ClinicalSeparatedListBody(
                    children: [
                      for (final template in items)
                        DataListCard(
                          title: template.name,
                          subtitle: template.description,
                          metaLine: _formatDate(template.updatedAt ?? template.createdAt),
                          onTap: () => context.push(
                            '/surgery-note-templates/${template.id}/edit',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
