import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/audit_log_card.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/audit_log_list_data_source.dart';
import 'data/audit_log_list_load_result.dart';
import 'data/audit_log_user_messages.dart';
import 'models/audit_log.dart';

class AuditLogListScreen extends StatefulWidget {
  final String? patientId;
  const AuditLogListScreen({super.key, this.patientId});

  @override
  State<AuditLogListScreen> createState() => _AuditLogListScreenState();
}

class _AuditLogListScreenState extends State<AuditLogListScreen> {
  String q = '';
  ModuleType? moduleFilter;
  ActionType? actionFilter;
  late Future<AuditLogListLoadResult> _loadFuture;

  int get _activeFilterCount {
    var n = 0;
    if (moduleFilter != null) n++;
    if (actionFilter != null) n++;
    return n;
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = AuditLogListDataSource.load(
        patientId: widget.patientId,
        query: q,
        actionTypeFilter: actionFilter,
        moduleFilter: moduleFilter,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      moduleFilter = null;
      actionFilter = null;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Audit Log / İşlem Geçmişi',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'İşlem Geçmişi',
              icon: Icons.history_outlined,
            ),
            FilterBar(
              searchHint: 'Kullanıcı, hasta, işlem, modül veya açıklama ara',
              onSearchChanged: (v) {
                q = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<ModuleType?>(
                      label: 'Modül',
                      value: moduleFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm modüller'),
                        ),
                        ...ModuleType.values.map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              moduleTypeLabel(m),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => moduleFilter = v);
                        _reload();
                      },
                    ),
                    ListFiltersRow.dropdown<ActionType?>(
                      label: 'İşlem tipi',
                      value: actionFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm işlemler'),
                        ),
                        ...ActionType.values.map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                              actionTypeLabel(a),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => actionFilter = v);
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<AuditLogListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  final result = snapshot.data;
                  if (snapshot.hasError ||
                      result == null ||
                      result.notConfigured) {
                    return ClinicalStateMessage.error(
                      icon: Icons.cloud_off_outlined,
                      title: 'İşlem geçmişi kullanılamıyor',
                      description: result?.errorMessage ??
                          AuditLogUserMessages.notConfigured,
                      onRetry: _reload,
                    );
                  }

                  if (result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'İşlem geçmişi yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result.errorMessage!,
                      ),
                      onRetry: _reload,
                    );
                  }

                  return _buildListBody(context, result.logs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(BuildContext context, List<AuditLog> list) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.history_outlined,
        title: AuditLogUserMessages.filterNoMatch,
        description: AuditLogUserMessages.filterNoMatchDescription,
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final log in list)
          AuditLogCard(
            log: log,
            onTap: () => context.push('/audit-logs/${log.id}'),
          ),
      ],
    );
  }
}
