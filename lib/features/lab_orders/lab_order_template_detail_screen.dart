import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/lab_order_template_detail_data_source.dart';
import 'data/lab_order_template_list_refresh.dart';
import 'models/lab_order_template.dart';
import 'models/lab_test_catalog.dart';

class LabOrderTemplateDetailScreen extends StatefulWidget {
  final String id;
  const LabOrderTemplateDetailScreen({super.key, required this.id});

  @override
  State<LabOrderTemplateDetailScreen> createState() =>
      _LabOrderTemplateDetailScreenState();
}

class _LabOrderTemplateDetailScreenState
    extends State<LabOrderTemplateDetailScreen> {
  late Future<LabOrderTemplateDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = LabOrderTemplateListRefresh.version;

  @override
  void initState() {
    super.initState();
    _loadFuture = LabOrderTemplateDetailDataSource.load(widget.id);
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
      setState(() {
        _loadFuture = LabOrderTemplateDetailDataSource.load(widget.id);
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şablonu sil'),
        content: const Text('Bu şablon kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await LabOrderTemplateDetailDataSource.delete(widget.id);
    if (!mounted) return;
    if (error != null) {
      showClinicalSnackBar(context, error, isError: true);
      return;
    }
    showClinicalSnackBar(context, 'Şablon silindi.');
    context.go('/lab-order-templates');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LabOrderTemplateDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Şablon',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final template = result?.template;
        if (snapshot.hasError ||
            result == null ||
            result.hasError ||
            template == null) {
          return AppShell(
            title: 'Şablon',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Şablon bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = LabOrderTemplateDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        return _buildBody(context, template);
      },
    );
  }

  Widget _buildBody(BuildContext context, LabOrderTemplate template) {
    final grouped = <LabTestGroup, List<LabTestCode>>{};
    for (final test in template.selectedTests) {
      grouped.putIfAbsent(labTestGroupFor(test), () => []).add(test);
    }

    return AppShell(
      title: 'Şablon',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Laboratuvar Şablonu',
              icon: Icons.library_books_outlined,
              leadingBack: true,
              fallbackRoute: '/lab-order-templates',
            ),
            DetailHeaderCard(
              title: template.name,
              subtitle: template.description ?? 'Açıklama yok',
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Şablon Bilgisi',
                  rows: [
                    InfoSectionRow('Oluşturan', template.createdBy),
                    if (template.defaultDiagnosis != null)
                      InfoSectionRow('Varsayılan tanı', template.defaultDiagnosis!),
                    InfoSectionRow(
                      'Enfeksiyon bağlamı',
                      infectionContextLabel(template.defaultInfectionContext),
                    ),
                  ],
                ),
                for (final group in LabTestGroup.values)
                  if ((grouped[group] ?? []).isNotEmpty)
                    InfoSectionCard(
                      title: labTestGroupLabel(group),
                      rows: grouped[group]!
                          .map((t) => InfoSectionRow(labTestCodeLabel(t), 'Dahil'))
                          .toList(),
                    ),
              ],
            ),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                DetailAction(
                  label: 'Bu şablonla istem oluştur',
                  filled: true,
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.push(
                    '/lab-orders/new?templateId=${template.id}',
                  ),
                ),
                if (AuthSession.canManageLabOrderTemplates)
                  DetailAction(
                    label: 'Düzenle',
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        context.push('/lab-order-templates/${template.id}/edit'),
                  ),
                if (AuthSession.canManageLabOrderTemplates)
                  DetailAction(
                    label: 'Sil',
                    icon: Icons.delete_outline,
                    onPressed: _delete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
