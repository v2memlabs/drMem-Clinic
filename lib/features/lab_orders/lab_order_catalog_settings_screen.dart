import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../features/settings/data/tenant_settings_repository_provider.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/form_screen_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/lab_order_catalog_gate.dart';
import 'models/lab_order_catalog_settings.dart';
import 'models/lab_test_catalog.dart';

class LabOrderCatalogSettingsScreen extends StatefulWidget {
  const LabOrderCatalogSettingsScreen({super.key});

  @override
  State<LabOrderCatalogSettingsScreen> createState() =>
      _LabOrderCatalogSettingsScreenState();
}

class _LabOrderCatalogSettingsScreenState
    extends State<LabOrderCatalogSettingsScreen> {
  final _customLabelCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  late Set<LabTestCode> _enabledDiger;
  late List<LabCustomTestEntry> _customTests;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await TenantSettingsRepositoryProvider.repository
          .loadLabOrderCatalogSettings();
      if (!mounted) return;
      setState(() {
        _enabledDiger = Set<LabTestCode>.from(settings.enabledDigerTests);
        _customTests = List<LabCustomTestEntry>.from(settings.customTests);
        _loading = false;
      });
      LabOrderCatalogGate.apply(settings);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enabledDiger =
            Set<LabTestCode>.from(LabOrderCatalogSettings.defaults.enabledDigerTests);
        _customTests = [];
        _loading = false;
      });
    }
  }

  void _addCustomTest() {
    final label = _customLabelCtrl.text.trim();
    if (label.isEmpty) {
      showClinicalSnackBar(context, 'Test adı girin.', isError: true);
      return;
    }
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _customTests = [..._customTests, LabCustomTestEntry(id: id, label: label)];
      _customLabelCtrl.clear();
    });
  }

  void _removeCustomTest(String id) {
    setState(() {
      _customTests = _customTests.where((e) => e.id != id).toList();
    });
  }

  Future<void> _save() async {
    if (!AuthSession.canManageLabOrderTemplates) {
      showClinicalSnackBar(context, 'Bu ayarı düzenleme yetkiniz yok.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final settings = LabOrderCatalogSettings(
      enabledDigerTests: _enabledDiger,
      customTests: _customTests,
    );

    try {
      await TenantSettingsRepositoryProvider.repository
          .updateLabOrderCatalogSettings(settings);
      LabOrderCatalogGate.apply(settings);
      if (!mounted) return;
      showClinicalSnackBar(context, 'Test listesi kaydedildi.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showClinicalSnackBar(
        context,
        e is Exception ? e.toString() : 'Kayıt başarısız.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShell(
        title: 'Diğer Test Listesi',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return AppShell(
      title: 'Diğer Test Listesi',
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = FormScreenLayout.contentWidth(constraints.maxWidth);
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: ListView(
                      padding: FormScreenLayout.scrollPadding(),
                      children: [
                        const PageHeader(
                          title: 'Diğer Test Listesi',
                          icon: Icons.tune_outlined,
                          leadingBack: true,
                          fallbackRoute: '/lab-order-templates',
                        ),
                        FormSectionCard(
                          title: 'Varsayılan tahliller',
                          icon: Icons.checklist_outlined,
                          children: [
                            const Text(
                              'Laboratuvar istem formunda «Diğer» bölümünde '
                              'gösterilecek hazır tahlilleri seçin.',
                            ),
                            const SizedBox(height: 8),
                            for (final code in labDefaultDigerTestCodes)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(labTestCodeLabel(code)),
                                value: _enabledDiger.contains(code),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _enabledDiger.add(code);
                                    } else {
                                      _enabledDiger.remove(code);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Özel testler',
                          icon: Icons.add_circle_outline,
                          children: [
                            const Text(
                              'Klinik ihtiyaca göre ek test adları tanımlayın. '
                              'Bu testler istem formunda seçilebilir olur.',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customLabelCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Yeni test adı',
                                      hintText: 'ör. PTH, Ferritin',
                                    ),
                                    onSubmitted: (_) => _addCustomTest(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _addCustomTest,
                                  child: const Text('Ekle'),
                                ),
                              ],
                            ),
                            if (_customTests.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('Henüz özel test eklenmedi.'),
                              )
                            else
                              for (final entry in _customTests)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(entry.label),
                                  trailing: IconButton(
                                    tooltip: 'Kaldır',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeCustomTest(entry.id),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          FormScreenLayout.bottomActions(
            onSave: _save,
            onCancel: () => context.pop(),
            saveLabel: 'Kaydet',
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
