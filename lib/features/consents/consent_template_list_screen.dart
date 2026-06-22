import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_template_list_data_source.dart';
import 'data/consent_template_list_load_result.dart';
import 'data/consent_template_list_refresh.dart';
import 'data/consent_template_list_user_messages.dart';
import 'data/consent_template_repository_provider.dart';
import 'models/consent_template.dart';

class ConsentTemplateListScreen extends StatefulWidget {
  const ConsentTemplateListScreen({super.key});

  @override
  State<ConsentTemplateListScreen> createState() =>
      _ConsentTemplateListScreenState();
}

class _ConsentTemplateListScreenState extends State<ConsentTemplateListScreen> {
  String _search = '';
  String? _categoryFilter;
  bool _activeOnly = true;
  late Future<ConsentTemplateListLoadResult> _loadFuture;
  ConsentTemplateListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ConsentTemplateListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (_categoryFilter != null) n++;
    if (!_activeOnly) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      _categoryFilter = null;
      _activeOnly = true;
    });
    _reload();
  }

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
    if (ConsentTemplateListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    ConsentTemplateRepositoryProvider.resetCache();
    _lastRefreshVersion = ConsentTemplateListRefresh.version;
    setState(() {
      _loadFuture = ConsentTemplateListDataSource.load(
        query: _search,
        categoryFilter: _categoryFilter,
        activeOnly: _activeOnly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Onam Form Şablonları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Onam Form Şablonları',
              icon: Icons.description_outlined,
              leadingBack: true,
              fallbackRoute: '/consents',
            ),
            FilterBar(
              searchHint: 'Form adı, kategori, açıklama veya dosya adı ara',
              onSearchChanged: (v) {
                _search = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: AuthSession.canEditClinicalEncounters
                  ? FilledButton.icon(
                      onPressed: () => context.push('/consent-templates/new'),
                      icon: const Icon(Icons.add_outlined),
                      label: const Text('Yeni şablon'),
                    )
                  : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<String?>(
                      label: 'Kategori',
                      value: _categoryFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm kategoriler'),
                        ),
                        ...ConsentTemplateCategories.all.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _categoryFilter = v);
                        _reload();
                      },
                    ),
                  ],
                ),
                FilterChip(
                  label: const Text('Sadece aktif şablonlar'),
                  selected: _activeOnly,
                  onSelected: (v) {
                    setState(() => _activeOnly = v);
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<ConsentTemplateListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: ConsentTemplateListUserMessages.loading,
          );
        }

        if (result != null && !result.hasError) {
          _cachedResult = result;
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return ClinicalStateMessage.loading(
            message: ConsentTemplateListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: ConsentTemplateListUserMessages.errorTitle,
            description: ClinicalStateMessage.safeErrorDescription(
              active.errorMessage,
            ),
            onRetry: _reload,
          );
        }

        final items = active.templates;
        if (items.isEmpty) {
          return ClinicalStateMessage.empty(
            icon: Icons.description_outlined,
            title: 'Form şablonu bulunamadı',
            description: AuthSession.canEditClinicalEncounters
                ? 'İlk ziyaret onamları için şablon ekleyin veya arama/filtre kriterlerinizi değiştirin.'
                : 'Arama veya filtre kriterlerinizi değiştirin.',
            action: AuthSession.canEditClinicalEncounters
                ? FilledButton.icon(
                    onPressed: () => context.push('/consent-templates/new'),
                    icon: const Icon(Icons.add_outlined, size: 18),
                    label: const Text('Yeni şablon'),
                  )
                : null,
          );
        }

        return ClinicalSeparatedListBody(
          children: [
            for (final t in items)
              DataListCard(
                title: t.title,
                subtitle: t.description,
                metaLine: '${t.requiredFor} • ${t.documentFileName}',
                trailing: _formatDate(t.updatedAt),
                chips: [
                  t.category,
                  t.isActive ? 'Aktif' : 'Pasif',
                ],
                onTap: () => context.push('/consent-templates/${t.id}'),
              ),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
