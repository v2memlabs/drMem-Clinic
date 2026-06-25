import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/message_template_repository_failure.dart';
import 'data/message_template_form_data_source.dart';
import 'data/message_template_repository_provider.dart';
import 'data/message_template_user_messages.dart';
import 'models/message_template.dart';

class MessageTemplateFormScreen extends StatefulWidget {
  final String? templateId;

  const MessageTemplateFormScreen({super.key, this.templateId});

  bool get isEditMode => templateId != null && templateId!.trim().isNotEmpty;

  @override
  State<MessageTemplateFormScreen> createState() =>
      _MessageTemplateFormScreenState();
}

class _MessageTemplateFormScreenState extends State<MessageTemplateFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  Channel _channel = Channel.whatsapp;
  Category _category = Category.genel_bilgilendirme;
  bool _isActive = true;
  bool _saving = false;
  bool _loading = false;
  String? _loadError;
  String _createdBy = '';

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
          await MessageTemplateRepositoryProvider.asyncRepository.getById(id);
      if (!mounted) return;
      if (template == null) {
        setState(() {
          _loading = false;
          _loadError = MessageTemplateUserMessages.notFound;
        });
        return;
      }
      _titleCtrl.text = template.title;
      _contentCtrl.text = template.content;
      _channel = template.channel;
      _category = template.category;
      _isActive = template.isActive;
      _createdBy = template.createdBy;
      setState(() => _loading = false);
    } on MessageTemplateRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = MessageTemplateUserMessages.forFailure(e.reason);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = MessageTemplateUserMessages.genericLoadFailure;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_titleCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Şablon başlığı zorunludur.', isError: true);
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Mesaj içeriği zorunludur.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final createdBy = _createdBy.trim().isNotEmpty
        ? _createdBy.trim()
        : (AuthSession.currentUser?.displayName.trim().isNotEmpty == true
            ? AuthSession.currentUser!.displayName.trim()
            : 'Doktor');

    final template = MessageTemplate(
      id: widget.isEditMode ? widget.templateId!.trim() : '',
      title: _titleCtrl.text.trim(),
      channel: _channel,
      category: _category,
      content: _contentCtrl.text.trim(),
      createdBy: createdBy,
      isActive: _isActive,
    );

    try {
      final saved = await MessageTemplateFormDataSource.save(
        draft: template,
        isEdit: widget.isEditMode,
      );

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        widget.isEditMode ? 'Mesaj şablonu güncellendi.' : 'Mesaj şablonu oluşturuldu.',
      );
      context.go('/messages/templates/${saved.id}/edit');
    } on MessageTemplateFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        MessageTemplateUserMessages.genericSaveFailure,
        isError: true,
      );
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/messages/templates');
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

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Mesaj Şablonu Düzenle' : 'Yeni Mesaj Şablonu',
      onSave: AuthSession.canViewMessageTemplates ? _save : () {},
      onCancel: _cancel,
      saveLabel: _saving ? 'Kaydediliyor…' : 'Kaydet',
      saving: _saving,
      header: PageHeader(
        title: widget.isEditMode ? 'Mesaj Şablonu Düzenle' : 'Yeni Mesaj Şablonu',
        icon: Icons.chat_bubble_outline,
        leadingBack: true,
        fallbackRoute: '/messages/templates',
      ),
      sections: [
        FormSectionCard(
          title: 'Şablon Bilgisi',
          icon: Icons.article_outlined,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                isDense: true,
              ),
            ),
            DropdownButtonFormField<Channel>(
              value: _channel,
              decoration: const InputDecoration(
                labelText: 'Kanal',
                isDense: true,
              ),
              isExpanded: true,
              items: Channel.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(messageChannelLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _channel = v);
              },
            ),
            DropdownButtonFormField<Category>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                isDense: true,
              ),
              isExpanded: true,
              items: Category.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(messageCategoryLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif şablon'),
              subtitle: Text(
                'Pasif şablonlar mesaj hazırlama ekranında listelenmez.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
        FormSectionCard(
          title: 'Mesaj İçeriği',
          icon: Icons.message_outlined,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Kullanılabilir yer tutucular: {{hastaAdi}}, {{tarih}}, {{saat}}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'İçerik',
                alignLabelWithHint: true,
                isDense: true,
              ),
              maxLines: 8,
            ),
          ],
        ),
      ],
    );
  }
}
