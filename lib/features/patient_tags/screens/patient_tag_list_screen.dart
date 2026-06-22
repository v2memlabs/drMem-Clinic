import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/page_header.dart';
import '../widgets/patient_tag_list_content.dart';

class PatientTagListScreen extends StatelessWidget {
  const PatientTagListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Hasta Etiketleri',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PageHeader(
              title: 'Hasta Etiketleri',
              icon: Icons.label_outline,
            ),
            SizedBox(height: AppSpacing.sm),
            Expanded(child: PatientTagListContent()),
          ],
        ),
      ),
    );
  }
}
