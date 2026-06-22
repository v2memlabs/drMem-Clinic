import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import 'saas_subscription_settings_content.dart';
import 'settings_subpage_scaffold.dart';

class SaasSubscriptionSettingsScreen extends StatelessWidget {
  const SaasSubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = !AuthSession.canEditClinicProfile;

    return SettingsSubpageScaffold(
      title: 'SaaS / Abonelik',
      icon: Icons.workspace_premium_outlined,
      children: [
        SaasSubscriptionSettingsContent(compact: compact),
      ],
    );
  }
}
