import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/sent_message_list_data_source.dart';
import 'data/sent_message_list_load_result.dart';
import 'data/sent_message_list_refresh.dart';
import 'data/sent_message_user_messages.dart';
import 'models/message_template.dart';
import 'models/sent_message.dart';

class SentMessageListScreen extends StatefulWidget {
  final String? patientId;
  const SentMessageListScreen({super.key, this.patientId});

  @override
  State<SentMessageListScreen> createState() => _SentMessageListScreenState();
}

class _SentMessageListScreenState extends State<SentMessageListScreen> {
  String _query = '';
  Channel? _channelFilter;
  SendStatus? _statusFilter;
  String? _categoryFilter;
  late Future<SentMessageListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = SentMessageListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (_channelFilter != null) n++;
    if (_statusFilter != null) n++;
    if (_categoryFilter != null) n++;
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
    if (SentMessageListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = SentMessageListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = SentMessageListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        channelFilter:
            _channelFilter != null ? messageChannelLabel(_channelFilter!) : null,
        statusEnumFilter: _statusFilter,
        categoryFilter: _categoryFilter,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _channelFilter = null;
      _statusFilter = null;
      _categoryFilter = null;
    });
    _reload();
  }

  Future<void> _openSend() async {
    final sendRoute = widget.patientId != null
        ? '/messages/send?patientId=${widget.patientId}'
        : '/messages/send';
    await context.push(sendRoute);
    if (mounted && SentMessageListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = SentMessageListRefresh.version;
      _reload();
    }
  }

  Future<void> _openDetail(String id) async {
    await context.push('/messages/sent/$id');
    if (mounted && SentMessageListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = SentMessageListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gönderim Kayıtları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Gönderim Kayıtları',
              icon: Icons.mail_outline,
            ),
            FilterBar(
              searchHint: 'Hasta, telefon veya şablon ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: FilledButton.icon(
                onPressed: _openSend,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Mesaj Hazırla'),
              ),
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
                    ListFiltersRow.dropdown<SendStatus?>(
                      label: 'Durum',
                      value: _statusFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm durumlar'),
                        ),
                        ...SendStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(sendStatusLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v);
                        _reload();
                      },
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          _categoryFilter =
                              v.trim().isEmpty ? null : v.trim();
                          _reload();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<SentMessageListLoadResult>(
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
                      title: 'Gönderim kayıtları yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            SentMessageUserMessages.genericLoadFailure,
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

  Widget _buildListBody(List<SentMessage> list) {
    if (list.isEmpty) {
      final hasFilters = _activeFilterCount > 0 || _query.trim().isNotEmpty;
      return ClinicalStateMessage.empty(
        icon: Icons.send_outlined,
        title: 'Gönderim kaydı bulunamadı',
        description: hasFilters
            ? 'Arama veya filtre kriterlerinizi değiştirin.'
            : 'Henüz gönderim kaydı yok. İlk mesajınızı hazırlayın.',
        action: FilledButton.icon(
          onPressed: _openSend,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Mesaj Hazırla'),
        ),
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final m in list) _buildCard(context, m),
      ],
    );
  }

  Widget _buildCard(BuildContext context, SentMessage m) {
    final status = sendStatusLabel(m.status);
    return DataListCard(
      title: m.patientName,
      subtitle: m.templateTitle,
      metaLine: '${m.channel} • ${m.patientPhone} • ${m.sentBy}',
      trailing: _formatDateTime(m.sentAt),
      chips: [status],
      onTap: () => _openDetail(m.id),
    );
  }
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$d.$m.${local.year} $time';
}
