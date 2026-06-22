import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_repository_failure.dart';
import 'data/consent_template_list_refresh.dart';
import 'data/consent_template_list_user_messages.dart';
import 'data/consent_template_repository_provider.dart';
import 'models/consent_template.dart';

class ConsentTemplateFormScreen extends StatefulWidget {
  final String? templateId;

  const ConsentTemplateFormScreen({super.key, this.templateId});

  bool get isEditMode => templateId != null && templateId!.trim().isNotEmpty;

  @override
  State<ConsentTemplateFormScreen> createState() =>
      _ConsentTemplateFormScreenState();
}

class _ConsentTemplateFormScreenState extends State<ConsentTemplateFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _versionCtrl = TextEditingController(text: '1.0');
  final _fileNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = ConsentTemplateCategories.kvkkAydinlatma;
  String _requiredFor = ConsentTemplateRequiredFor.tumHastalar;
  bool _isActive = true;
  bool _saving = false;
  bool _loading = false;
  String? _loadError;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final id = widget.templateId?.trim();
    if (id == null || id.isEmpty) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final template =
          await ConsentTemplateRepositoryProvider.asyncRepository.getById(id);
      if (!mounted) return;
      if (template == null) {
        setState(() {
          _loading = false;
          _loadError = 'Form şablonu bulunamadı.';
        });
        return;
      }
      _titleCtrl.text = template.title;
      _descriptionCtrl.text = template.description;
      _contentCtrl.text = template.contentPreview;
      _versionCtrl.text = template.version;
      _fileNameCtrl.text = template.documentFileName;
      _notesCtrl.text = template.notes ?? '';
      _category = template.category;
      _requiredFor = template.requiredFor;
      _isActive = template.isActive;
      _createdAt = template.createdAt;
      setState(() => _loading = false);
    } on ConsentRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = ConsentTemplateListUserMessages.forFailure(e.reason);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = ConsentTemplateListUserMessages.genericLoadFailure;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _contentCtrl.dispose();
    _versionCtrl.dispose();
    _fileNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_titleCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Form adı zorunludur.', isError: true);
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Onam metni zorunludur.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final template = ConsentTemplate(
      id: widget.isEditMode ? widget.templateId!.trim() : '',
      title: _titleCtrl.text.trim(),
      category: _category,
      description: _descriptionCtrl.text.trim(),
      version: _versionCtrl.text.trim().isEmpty ? '1.0' : _versionCtrl.text.trim(),
      isActive: _isActive,
      createdAt: _createdAt ?? now,
      updatedAt: now,
      documentFileName: _fileNameCtrl.text.trim().isEmpty
          ? '${_titleCtrl.text.trim().replaceAll(' ', '_')}.pdf'
          : _fileNameCtrl.text.trim(),
      contentPreview: _contentCtrl.text.trim(),
      requiredFor: _requiredFor,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      final repo = ConsentTemplateRepositoryProvider.asyncRepository;
      final saved = widget.isEditMode
          ? await repo.update(template)
          : await repo.add(template);

      if (!mounted) return;
      setState(() => _saving = false);
      ConsentTemplateListRefresh.markStale();
      showClinicalSnackBar(
        context,
        widget.isEditMode ? 'Şablon güncellendi.' : 'Şablon oluşturuldu.',
      );
      context.go('/consent-templates/${saved.id}');
    } on ConsentRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        ConsentTemplateListUserMessages.saveFailure(e.reason),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        ConsentTemplateListUserMessages.genericLoadFailure,
        isError: true,
      );
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/consent-templates');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: 'Şablon yüklenemedi',
            description: _loadError!,
            onRetry: _loadExisting,
          ),
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Onam Şablonu Düzenle' : 'Yeni Onam Şablonu',
      onSave: AuthSession.canEditClinicalEncounters ? () => _save() : () {},
      onCancel: _cancel,
      saveLabel: _saving ? 'Kaydediliyor…' : 'Kaydet',
      header: PageHeader(
        title: widget.isEditMode ? 'Onam Şablonu Düzenle' : 'Yeni Onam Şablonu',
        icon: Icons.description_outlined,
        leadingBack: true,
        fallbackRoute: '/consent-templates',
      ),
      sections: [
        FormSectionCard(
          title: 'Şablon Bilgisi',
          icon: Icons.article_outlined,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Form adı',
                isDense: true,
              ),
            ),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                isDense: true,
              ),
              isExpanded: true,
              items: ConsentTemplateCategories.all
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Kısa açıklama',
                isDense: true,
              ),
              maxLines: 2,
            ),
            DropdownButtonFormField<String>(
              value: _requiredFor,
              decoration: const InputDecoration(
                labelText: 'Gerekli durum',
                isDense: true,
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: ConsentTemplateRequiredFor.tumHastalar,
                  child: Text(ConsentTemplateRequiredFor.tumHastalar),
                ),
                DropdownMenuItem(
                  value: ConsentTemplateRequiredFor.ameliyatOncesi,
                  child: Text(ConsentTemplateRequiredFor.ameliyatOncesi),
                ),
                DropdownMenuItem(
                  value: ConsentTemplateRequiredFor.girisimOncesi,
                  child: Text(ConsentTemplateRequiredFor.girisimOncesi),
                ),
                DropdownMenuItem(
                  value: ConsentTemplateRequiredFor.mesajlasmaIzni,
                  child: Text(ConsentTemplateRequiredFor.mesajlasmaIzni),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _requiredFor = v);
              },
            ),
            TextFormField(
              controller: _versionCtrl,
              decoration: const InputDecoration(
                labelText: 'Sürüm',
                isDense: true,
              ),
            ),
            TextFormField(
              controller: _fileNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosya adı (opsiyonel)',
                isDense: true,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
        FormSectionCard(
          title: 'Onam Metni',
          icon: Icons.edit_note_outlined,
          children: [
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'PDF gövde metni',
                alignLabelWithHint: true,
                isDense: true,
                helperText:
                    'Hasta imzası sonrası antetli PDF içinde kullanılır.',
              ),
              minLines: 8,
              maxLines: 16,
            ),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'İç not',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }
}
