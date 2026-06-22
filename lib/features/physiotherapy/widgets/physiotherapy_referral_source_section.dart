import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/detail_action_labels.dart';
import '../../../shared/widgets/detail_actions_panel.dart';
import '../../../shared/widgets/info_section_card.dart';
import '../data/physiotherapy_referral_lookup_data_source.dart';
import '../models/physiotherapy_referral.dart';

/// Kaynak yönlendirme kartı — async lookup ile remote/mock uyumlu.
class PhysiotherapyReferralSourceSection extends StatefulWidget {
  final String referralId;
  final bool showGoToReferralAction;

  const PhysiotherapyReferralSourceSection({
    super.key,
    required this.referralId,
    this.showGoToReferralAction = true,
  });

  @override
  State<PhysiotherapyReferralSourceSection> createState() =>
      _PhysiotherapyReferralSourceSectionState();
}

class _PhysiotherapyReferralSourceSectionState
    extends State<PhysiotherapyReferralSourceSection> {
  PhysiotherapyReferral? _referral;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result =
        await PhysiotherapyReferralLookupDataSource.getById(widget.referralId);
    if (!mounted) return;
    setState(() {
      _referral = result.referral;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _referral == null) {
      return const SizedBox.shrink();
    }

    final referral = _referral!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoSectionCard(
          title: 'Kaynak Yönlendirme',
          rows: [
            InfoSectionRow(
              'Yönlendirme tarihi',
              _formatDate(referral.referredAt),
            ),
            InfoSectionRow(
              'Tanı özeti',
              _truncate(referral.diagnosisSummary, 80),
              emphasize: true,
            ),
            InfoSectionRow(
              'Tedavi hedefi',
              _truncate(referral.treatmentGoal, 80),
            ),
          ],
        ),
        if (widget.showGoToReferralAction)
          DetailActionsPanel(
            title: 'İşlemler',
            actions: [
              DetailAction(
                label: DetailActionLabels.goToReferral,
                onPressed: () => context.push(
                  '/physiotherapy/referrals/${widget.referralId.trim()}',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _truncate(String text, int maxLen) {
  final t = text.trim();
  if (t.isEmpty) return kDisplayUnspecified;
  if (t.length <= maxLen) return t;
  return '${t.substring(0, maxLen)}…';
}
