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
import 'data/lab_order_template_list_data_source.dart';
import 'data/lab_order_template_list_load_result.dart';
import 'data/lab_order_template_list_refresh.dart';
import 'data/lab_order_template_user_messages.dart';
import 'models/lab_order_template.dart';

class LabOrderTemplateListScreen extends StatefulWidget {
  const LabOrderTemplateListScreen({super.key});

  @override
  State<LabOrderTemplateListScreen> createState() =>
      _LabOrderTemplateListScreenState();
}

class _LabOrderTemplateListScreenState extends State<LabOrderTemplateListScreen> {
  String _query = '';
  late Future<LabOrderTemplateListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = LabOrderTemplateListRefresh.version;

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
    if (LabOrderTemplateListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderTemplateListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = LabOrderTemplateListDataSource.load(query: _query);
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/lab-order-templates/$id');
    if (mounted && LabOrderTemplateListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderTemplateListRefresh.version;
      _reload();
    }
  }

  Future<void> _openNew() async {
    await context.push('/lab-order-templates/new');
    if (mounted && LabOrderTemplateListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderTemplateListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Laboratuvar Şablonları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Laboratuvar Şablonları',
              icon: Icons.library_books_outlined,
              leadingBack: true,
              fallbackRoute: '/lab-orders',
            ),
            FilterBar(
              searchHint: 'Şablon adı ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/lab-order-templates/catalog-settings'),
                    icon: const Icon(Icons.tune_outlined, size: 18),
                    label: const Text('Diğer test listesi'),
                  ),
                  FilledButton.icon(
                    onPressed: _openNew,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni Şablon'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<LabOrderTemplateListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  final result = snapshot.data;
                  if (snapshot.hasError || result == null || result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'Şablonlar yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            LabOrderTemplateUserMessages.genericLoadFailure,
                      ),
                      onRetry: _reload,
                    );
                  }

                  return _buildListBody(result.items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(List<LabOrderTemplate> items) {
    if (items.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.library_books_outlined,
        title: 'Şablon bulunamadı',
        description:
            'Preoperatif veya enfeksiyon paneli şablonu oluşturun.',
        action: OutlinedButton.icon(
          onPressed: _openNew,
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
            subtitle: template.description ?? '',
            metaLine: '${template.selectedTests.length} tahlil',
            contextLine: template.createdBy,
            onTap: () => _openDetail(template.id),
          ),
      ],
    );
  }
}
