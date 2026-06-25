import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/form_screen_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/message_channel_launcher.dart';
import 'data/message_template_lookup_data_source.dart';
import 'data/sent_message_form_data_source.dart';
import 'models/message_template.dart';
import 'models/sent_message.dart';
import 'widgets/message_preview_dialog.dart';

class MessageSendScreen extends StatefulWidget {
  final String? patientId;
  const MessageSendScreen({super.key, this.patientId});

  @override
  State<MessageSendScreen> createState() => _MessageSendScreenState();
}

class _MessageSendScreenState extends State<MessageSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedPatientId;
  String channel = 'WhatsApp';
  String category = '';
  String? selectedTemplateId;
  String content = '';
  List<MessageTemplate> _templates = const [];
  bool _templatesLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    final initialId = widget.patientId;
    if (initialId != null && initialId.isNotEmpty) {
      _selectPatient(initialId);
    }
  }

  Future<void> _loadTemplates() async {
    final templates = await MessageTemplateLookupDataSource.listAll();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templatesLoading = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectPatient(String? patientId) async {
    if (patientId == null) {
      setState(() {
        _selectedPatientId = null;
        _phoneController.clear();
        _emailController.clear();
      });
      return;
    }

    final patient = await PatientLookupDataSource.findById(patientId);
    if (!mounted || patient == null) return;

    setState(() {
      _selectedPatientId = patientId;
      _phoneController.text = patient.phone;
      _emailController.text = patient.email;
    });
  }

  Future<void> loadTemplate(String id) async {
    final t = await MessageTemplateLookupDataSource.findById(id);
    if (t == null || !mounted) return;
    setState(() {
      channel = t.channelLabel;
      category = t.categoryLabel;
      content = t.content;
      selectedTemplateId = id;
    });
  }

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mesaj içeriği gerekli.';
    }
    return null;
  }

  Future<void> _saveAsSent({
    required SendStatus status,
    required String templateTitle,
  }) async {
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    final patient = await PatientLookupDataSource.findById(_selectedPatientId!);
    if (!mounted) return;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    final sentBy =
        AuthSession.currentUser?.displayName.trim().isNotEmpty == true
            ? AuthSession.currentUser!.displayName.trim()
            : 'Asistan';

    final trimmedContent = content.trim();
    final preview = trimmedContent.length > 200
        ? trimmedContent.substring(0, 200)
        : trimmedContent;

    final msg = SentMessage(
      id: 'sent-${DateTime.now().millisecondsSinceEpoch}',
      patientId: _selectedPatientId!,
      patientName: patient.fullName,
      patientPhone: _phoneController.text.trim(),
      channel: channel,
      category: category,
      templateTitle: templateTitle,
      sentAt: DateTime.now(),
      sentBy: sentBy,
      status: status,
      contentPreview: preview,
      content: trimmedContent,
      patientEmail: _emailController.text.trim(),
      relatedModule: 'Mesajlaşma',
      notes: '',
    );

    try {
      await SentMessageFormDataSource.create(
        msg,
        templateId: selectedTemplateId,
        patientEmail: _emailController.text.trim(),
        fullContent: trimmedContent,
      );
    } on SentMessageFormException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    if (!mounted) return;
    final successText = status == SendStatus.gonderildi
        ? 'Gönderim kaydı oluşturuldu.'
        : 'Gönderim başarısız olarak kaydedildi.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successText)),
    );
    context.push('/messages/sent');
  }

  Future<String> _resolveTemplateTitle() async {
    if (selectedTemplateId == null) return 'Manuel';
    final template =
        await MessageTemplateLookupDataSource.findById(selectedTemplateId!);
    return template?.title ?? 'Manuel';
  }

  Future<void> _previewMessage() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    await MessagePreviewDialog.show(
      context,
      channel: channel,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      content: content.trim(),
      confirmSend: false,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    final recipientError = MessageChannelLauncher.validateRecipient(
      channelLabel: channel,
      phone: _phoneController.text,
      email: _emailController.text,
    );
    if (recipientError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recipientError)),
      );
      return;
    }

    final confirmed = await MessagePreviewDialog.show(
      context,
      channel: channel,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      content: content.trim(),
      confirmSend: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final templateTitle = await _resolveTemplateTitle();
    if (!mounted) return;

    final launched = await MessageChannelLauncher.launch(
      channelLabel: channel,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      body: content.trim(),
      subject: templateTitle,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MessageChannelLaunchFailure.launchFailed.userMessage,
          ),
        ),
      );
    }

    await _saveAsSent(
      status: launched ? SendStatus.gonderildi : SendStatus.basarisiz,
      templateTitle: templateTitle,
    );
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/messages/sent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasPatient = _selectedPatientId != null;
    final showMissingEmailHint = hasPatient &&
        _emailController.text.trim().isEmpty &&
        channel == 'E-posta';

    return AppShell(
      title: 'Mesaj Hazırla',
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
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: FormScreenLayout.scrollPadding(),
                        children: [
                          const PageHeader(
                            title: 'Mesaj Hazırla',
                            leadingBack: true,
                            fallbackRoute: '/messages/sent',
                          ),
                          Card(
                            color: Colors.yellow[100],
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'Klinik ve kişisel sağlık verisi içeren mesajlar yalnızca gerekli durumlarda, uygun onam ve yetki kapsamında gönderilmelidir.',
                              ),
                            ),
                          ),
                          FormSectionCard(
                            title: 'Hasta ve İletişim',
                            icon: Icons.person_outline,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: _selectedPatientId,
                                isDense: true,
                                onChanged: _selectPatient,
                                onPatientSelected: (p) => _selectPatient(p?.id),
                              ),
                              LayoutBuilder(
                                builder: (context, rowConstraints) {
                                  final stacked = rowConstraints.maxWidth < 480;
                                  final phoneField = TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.phone,
                                  );
                                  final emailField = TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'E-posta',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  );
                                  if (stacked) {
                                    return Column(
                                      children: [
                                        phoneField,
                                        emailField,
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: phoneField),
                                      const SizedBox(width: 12),
                                      Expanded(child: emailField),
                                    ],
                                  );
                                },
                              ),
                              if (showMissingEmailHint)
                                Text(
                                  'Hasta kartında e-posta bilgisi yok',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: muted),
                                ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Şablon ve İçerik',
                            icon: Icons.message_outlined,
                            children: [
                              DropdownButtonFormField<String>(
                                value: channel,
                                decoration: const InputDecoration(
                                  labelText: 'Kanal',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: ['WhatsApp', 'SMS', 'E-posta']
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => channel = v!),
                              ),
                              DropdownButtonFormField<String>(
                                value: category.isEmpty ? null : category,
                                decoration: const InputDecoration(
                                  labelText: 'Kategori',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: _templates
                                    .map((t) => t.categoryLabel)
                                    .toSet()
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => category = v ?? ''),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedTemplateId,
                                decoration: InputDecoration(
                                  labelText: 'Şablon',
                                  isDense: true,
                                  suffixIcon: _templatesLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                isExpanded: true,
                                items: [
                                  null,
                                  ..._templates,
                                ]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t == null ? null : t.id,
                                        child: Text(
                                          t == null ? 'Seçiniz' : t.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _templatesLoading
                                    ? null
                                    : (v) {
                                        if (v != null) loadTemplate(v);
                                      },
                              ),
                              TextFormField(
                                initialValue: content,
                                decoration: const InputDecoration(
                                  labelText: 'İçerik',
                                  alignLabelWithHint: true,
                                  isDense: true,
                                ),
                                maxLines: 6,
                                validator: _validateContent,
                                onChanged: (v) => content = v,
                                onSaved: (v) => content = v ?? '',
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: _previewMessage,
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Önizle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          FormScreenLayout.bottomActions(
            onSave: _submit,
            onCancel: _cancel,
            saveLabel: 'Gönder',
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
