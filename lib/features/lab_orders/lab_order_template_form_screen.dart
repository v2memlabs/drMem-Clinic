import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/lab_order_template_form_data_source.dart';
import 'data/lab_test_selection.dart';
import 'models/lab_order.dart';
import 'models/lab_order_template.dart';
import 'models/lab_test_catalog.dart';
import 'widgets/lab_test_selector.dart';

class LabOrderTemplateFormScreen extends StatefulWidget {
  final String? templateId;
  const LabOrderTemplateFormScreen({super.key, this.templateId});

  bool get isEditMode => templateId != null && templateId!.trim().isNotEmpty;

  @override
  State<LabOrderTemplateFormScreen> createState() =>
      _LabOrderTemplateFormScreenState();
}

class _LabOrderTemplateFormScreenState extends State<LabOrderTemplateFormScreen> {
  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();
  final preopCtrl = TextEditingController();
  final ekgCtrl = TextEditingController();
  final additionalCtrl = TextEditingController();
  final Set<LabTestCode> _selectedTests = {};
  final Set<String> _selectedCustomTestIds = {};
  LabOrderReason defaultOrderReason = LabOrderReason.preoperatifHazirlik;
  InfectionContext infectionContext = InfectionContext.yok;
  bool _loaded = false;
  bool _saving = false;
  LabOrderTemplate? _existing;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  Future<void> _initForm() async {
    if (widget.isEditMode) {
      final existing =
          await LabOrderTemplateFormDataSource.loadForEdit(widget.templateId!);
      if (existing != null) {
        _existing = existing;
        nameCtrl.text = existing.name;
        descriptionCtrl.text = existing.description ?? '';
        diagnosisCtrl.text = existing.defaultDiagnosis ?? '';
        preopCtrl.text = existing.preoperativeNotes ?? '';
        ekgCtrl.text = existing.ekgNotes ?? '';
        additionalCtrl.text = existing.additionalNotes ?? '';
        infectionContext = existing.defaultInfectionContext;
        defaultOrderReason = existing.defaultOrderReason;
        _selectedTests.addAll(
          LabTestSelection.expandForEditing(existing.selectedTests),
        );
        _selectedCustomTestIds.addAll(existing.selectedCustomTestIds);
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    diagnosisCtrl.dispose();
    preopCtrl.dispose();
    ekgCtrl.dispose();
    additionalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nameCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Şablon adı zorunlu.', isError: true);
      return;
    }
    if (_selectedTests.isEmpty && _selectedCustomTestIds.isEmpty) {
      showClinicalSnackBar(context, 'En az bir tahlil seçin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final performer = AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final now = DateTime.now();
    final record = LabOrderTemplate(
      id: _existing?.id ?? '',
      name: nameCtrl.text.trim(),
      description: descriptionCtrl.text.trim().isEmpty
          ? null
          : descriptionCtrl.text.trim(),
      createdBy: _existing?.createdBy ?? performer,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      selectedTests: LabTestSelection.normalizeForStorage(_selectedTests),
      selectedCustomTestIds: _selectedCustomTestIds.toList(),
      defaultOrderReason: defaultOrderReason,
      defaultDiagnosis: diagnosisCtrl.text.trim().isEmpty
          ? null
          : diagnosisCtrl.text.trim(),
      defaultInfectionContext: infectionContext,
      preoperativeNotes: preopCtrl.text.trim().isEmpty ? null : preopCtrl.text.trim(),
      ekgNotes: ekgCtrl.text.trim().isEmpty ? null : ekgCtrl.text.trim(),
      additionalNotes:
          additionalCtrl.text.trim().isEmpty ? null : additionalCtrl.text.trim(),
    );

    try {
      final saved = widget.isEditMode
          ? await LabOrderTemplateFormDataSource.update(record)
          : await LabOrderTemplateFormDataSource.create(record);

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, 'Şablon kaydedildi.');
      context.go('/lab-order-templates/${saved.id}');
    } on LabOrderTemplateFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        'Şablon kaydedilemedi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Şablon',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Şablon Düzenle' : 'Yeni Şablon',
      onSave: _save,
      onCancel: () => context.pop(),
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      header: PageHeader(
        title: widget.isEditMode ? 'Şablon Düzenle' : 'Yeni Şablon',
        icon: Icons.library_books_outlined,
        leadingBack: true,
        fallbackRoute: '/lab-order-templates',
      ),
      sections: [
                        FormSectionCard(
                          title: 'Şablon Bilgisi',
                          icon: Icons.library_books_outlined,
                          children: [
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: 'Şablon adı'),
                            ),
                            TextFormField(
                              controller: descriptionCtrl,
                              decoration: const InputDecoration(labelText: 'Açıklama'),
                              maxLines: 2,
                            ),
                            TextFormField(
                              controller: diagnosisCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Varsayılan ön tanı / tanı',
                              ),
                            ),
                            DropdownButtonFormField<LabOrderReason>(
                              initialValue: defaultOrderReason,
                              decoration: const InputDecoration(
                                labelText: 'Varsayılan istem sebebi',
                              ),
                              items: LabOrderReason.values
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(labOrderReasonLabel(r)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => defaultOrderReason = v);
                              },
                            ),
                            DropdownButtonFormField<InfectionContext>(
                              initialValue: infectionContext,
                              decoration: const InputDecoration(
                                labelText: 'Varsayılan enfeksiyon bağlamı',
                              ),
                              items: InfectionContext.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(infectionContextLabel(c)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => infectionContext = v);
                              },
                            ),
                          ],
                        ),
                        LabTestSelector(
                          selectedTests: _selectedTests,
                          selectedCustomTestIds: _selectedCustomTestIds,
                          onTestsChanged: (next) => setState(() {
                            _selectedTests
                              ..clear()
                              ..addAll(next);
                          }),
                          onCustomTestsChanged: (next) => setState(() {
                            _selectedCustomTestIds
                              ..clear()
                              ..addAll(next);
                          }),
                        ),
                        FormSectionCard(
                          title: 'Varsayılan notlar',
                          icon: Icons.notes_outlined,
                          children: [
                            TextFormField(
                              controller: preopCtrl,
                              decoration: const InputDecoration(labelText: 'Preoperatif not'),
                            ),
                            TextFormField(
                              controller: ekgCtrl,
                              decoration: const InputDecoration(labelText: 'EKG notu'),
                            ),
                            TextFormField(
                              controller: additionalCtrl,
                              decoration: const InputDecoration(labelText: 'Genel not'),
                            ),
                          ],
                        ),
      ],
    );
  }
}
