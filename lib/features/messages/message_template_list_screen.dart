import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/message_template_list_data_source.dart';
import 'data/message_template_list_load_result.dart';
import 'data/message_template_list_refresh.dart';
import 'data/message_template_user_messages.dart';
import 'data/message_template_repository_provider.dart';
import 'models/message_template.dart';

class MessageTemplateListScreen extends StatefulWidget {
  const MessageTemplateListScreen({super.key});

  @override
  State<MessageTemplateListScreen> createState() =>
      _MessageTemplateListScreenState();
}

class _MessageTemplateListScreenState extends State<MessageTemplateListScreen> {
  String _query = '';
  Channel? _channelFilter;
  Category? _categoryFilter;
  bool _activeOnly = true;
  late Future<MessageTemplateListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = MessageTemplateListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (_channelFilter != null) n++;
    if (_categoryFilter != null) n++;
    if (!_activeOnly) n++;
    return n;
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
    if (MessageTemplateListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    MessageTemplateRepositoryProvider.resetCache();
    _lastRefreshVersion = MessageTemplateListRefresh.version;
    setState(() {
      _loadFuture = MessageTemplateListDataSource.load(
        query: _query,
        channelEnumFilter: _channelFilter,
        categoryEnumFilter: _categoryFilter,
        activeOnly: _activeOnly,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _channelFilter = null;
      _categoryFilter = null;
      _activeOnly = true;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Mesaj Şablonları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Mesaj Şablonları',
              icon: Icons.chat_bubble_outline,
            ),
            FilterBar(
              searchHint: 'Başlık, içerik veya oluşturan ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: AuthSession.canViewMessageTemplates
                  ? FilledButton.icon(
                      onPressed: () => context.push('/messages/templates/new'),
                      icon: const Icon(Icons.add_outlined),
                      label: const Text('Yeni Şablon'),
                    )
                  : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<Channel?>(
                      label: 'Kanal',
                      value: _channelFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm kanallar'),
                        ),
                        ...Channel.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(messageChannelLabel(c)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _channelFilter = v);
                        _reload();
                      },
                    ),
                    ListFiltersRow.dropdown<Category?>(
                      label: 'Kategori',
                      value: _categoryFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm kategoriler'),
                        ),
                        ...Category.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(messageCategoryLabel(c)),
                          ),
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
            Expanded(
              child: FutureBuilder<MessageTemplateListLoadResult>(
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
                      title: 'Mesaj şablonları yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            MessageTemplateUserMessages.genericLoadFailure,
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

  Widget _buildListBody(List<MessageTemplate> list) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.message_outlined,
        title: 'Mesaj şablonu bulunamadı',
        description: 'Arama veya filtre kriterlerinizi değiştirin.',
        action: AuthSession.canViewMessageTemplates
            ? FilledButton.icon(
                onPressed: () => context.push('/messages/templates/new'),
                icon: const Icon(Icons.add_outlined),
                label: const Text('Yeni Şablon'),
              )
            : null,
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final t in list) _buildCard(context, t),
      ],
    );
  }

  Widget _buildCard(BuildContext context, MessageTemplate t) {
    return DataListCard(
      title: t.title,
      subtitle: t.content,
      metaLine: '${t.channelLabel} • ${t.categoryLabel} • ${t.createdBy}',
      chips: [
        t.isActive ? 'Aktif' : 'Pasif',
      ],
      onTap: AuthSession.canViewMessageTemplates
          ? () => context.push('/messages/templates/${t.id}/edit')
          : null,
    );
  }
}
