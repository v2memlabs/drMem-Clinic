import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../../../shared/widgets/clinical_separated_list_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/list_filters_row.dart';
import '../../../shared/widgets/list_card_accent.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/physiotherapy_referral_list_data_source.dart';
import '../data/physiotherapy_referral_list_load_result.dart';
import '../data/physiotherapy_referral_list_refresh.dart';
import '../data/physiotherapy_referral_user_messages.dart';
import '../models/physiotherapy_referral.dart';

class PhysiotherapyReferralListScreen extends StatefulWidget {
  final String? patientId;
  final bool pendingOnly;

  const PhysiotherapyReferralListScreen({
    super.key,
    this.patientId,
    this.pendingOnly = false,
  });

  @override
  State<PhysiotherapyReferralListScreen> createState() =>
      _PhysiotherapyReferralListScreenState();
}

class _PhysiotherapyReferralListScreenState
    extends State<PhysiotherapyReferralListScreen> {
  String search = '';
  ReferralStatus? statusFilter;
  late Future<PhysiotherapyReferralListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;

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
    if (PhysiotherapyReferralListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  int get _activeFilterCount => statusFilter != null ? 1 : 0;

  void _clearFilters() {
    setState(() => statusFilter = null);
    _reload();
  }

  void _reload() {
    _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;
    setState(() {
      _loadFuture = PhysiotherapyReferralListDataSource.load(
        patientId: widget.patientId,
        query: search,
        statusFilter: statusFilter,
        pendingOnly: widget.pendingOnly,
      );
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/physiotherapy/referrals/$id');
    if (mounted &&
        PhysiotherapyReferralListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.pendingOnly
        ? 'Bekleyen Hastalar'
        : widget.patientId != null && widget.patientId!.isNotEmpty
            ? 'Hasta Fizyoterapi Yönlendirmeleri'
            : 'Fizyoterapi Yönlendirmeleri';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.medical_information_outlined,
            ),
            FilterBar(
              searchHint:
                  'Hasta, fizyoterapist, tanı özeti, tedavi hedefi veya duruma göre ara',
              onSearchChanged: (v) {
                search = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<ReferralStatus?>(
                      label: 'Durum',
                      value: statusFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm durumlar'),
                        ),
                        ...ReferralStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(referralStatusLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => statusFilter = v);
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<PhysiotherapyReferralListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ClinicalStateMessage.loading(
                      message: PhysiotherapyReferralListUserMessages.loading,
                    );
                  }

                  final result = snapshot.data!;
                  if (result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: PhysiotherapyReferralListUserMessages.errorTitle,
                      description: result.errorMessage!,
                      onRetry: _reload,
                    );
                  }

                  final list = result.items ?? const [];
                  if (list.isEmpty) {
                    return ClinicalStateMessage.empty(
                      title: 'Fizyoterapi yönlendirmesi bulunamadı',
                      description:
                          'Arama veya filtre kriterlerinizi değiştirin.',
                      icon: Icons.assignment_outlined,
                    );
                  }

                  return ClinicalSeparatedListBody(
                    children: [
                      for (final r in list) _buildCard(context, r),
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

  Widget _buildCard(BuildContext context, PhysiotherapyReferral r) {
    final diagnosis = r.diagnosisSummary.trim();
    final goal = r.treatmentGoal.trim();
    final metaParts = <String>[
      if (diagnosis.isNotEmpty) diagnosis,
      'Fizyoterapist: ${r.physiotherapistName}',
    ];

    return DataListCard(
      title: r.patientName,
      subtitle: goal.isNotEmpty ? goal : (diagnosis.isNotEmpty ? diagnosis : null),
      metaLine: metaParts.join(' • '),
      trailing: _formatDate(r.referredAt),
      chips: [r.statusLabel],
      accentRailColor: ListCardAccent.referralStatus(r.statusLabel),
      onTap: () => _openDetail(r.id),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
