import 'package:flutter/material.dart';

import 'demo_usage_settings_content.dart';
import 'settings_subpage_scaffold.dart';

class DemoUsageSettingsScreen extends StatelessWidget {
  const DemoUsageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Demo / Kullanım Durumu',
      icon: Icons.science_outlined,
      children: const [
        DemoUsageSettingsContent(),
      ],
    );
  }
}
