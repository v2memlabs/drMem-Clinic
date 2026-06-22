import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/constants/app_roles.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/form_screen_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import '../pdf_outputs/widgets/pdf_letterhead_preview_card.dart';
import 'data/consent_document_prepare_helper.dart';
import 'data/consent_template_list_user_messages.dart';
import 'data/consent_template_repository_provider.dart';
import 'data/consent_repository_failure.dart';
import 'models/consent_record.dart';
import 'models/consent_template.dart';

class ConsentTemplatePrepareScreen extends StatefulWidget {
  final String templateId;

  const ConsentTemplatePrepareScreen({super.key, required this.templateId});

  @override
  State<ConsentTemplatePrepareScreen> createState() =>
      _ConsentTemplatePrepareScreenState();
}

class _ConsentTemplatePrepareScreenState
    extends State<ConsentTemplatePrepareScreen> {
  String? _patientId;
  Patient? _selectedPatient;
  final _extraNotes = TextEditingController();
  late final DateTime _preparedAt = DateTime.now();
  bool _saving = false;
  ConsentTemplate? _template;
  bool _loadingTemplate = true;
  String? _templateLoadError;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await ConsentTemplateRepositoryProvider.asyncRepository
          .getById(widget.templateId);
      if (!mounted) return;
      setState(() {
        _template = template;
        _loadingTemplate = false;
        _templateLoadError =
            template == null ? 'Form şablonu bulunamadı.' : null;
      });
    } on ConsentRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTemplate = false;
        _templateLoadError =
            ConsentTemplateListUserMessages.forFailure(e.reason);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTemplate = false;
        _templateLoadError = ConsentTemplateListUserMessages.genericLoadFailure;
      });
    }
  }

  Future<void> _onPatientChanged(String? patientId) async {
    setState(() => _patientId = patientId);
    if (patientId == null || patientId.isEmpty) {
      setState(() => _selectedPatient = null);
      return;
    }
    final patient = await PatientLookupDataSource.findById(patientId);
    if (!mounted) return;
    setState(() => _selectedPatient = patient);
  }

  @override
  void dispose() {
    _extraNotes.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _createConsentRecord() async {
    final template = _template;
    if (template == null || _saving) return;

    if (_patientId == null || _patientId!.isEmpty) {
      _showError('Lütfen hasta seçin.');
      return;
    }

    final remoteError = ConsentDocumentPrepareHelper.validateRemoteReady();
    if (remoteError != null) {
      _showError(remoteError);
      return;
    }

    final patient = _selectedPatient;
    if (patient == null) {
      _showError('Hasta bilgisi yüklenemedi. Lütfen hastayı tekrar seçin.');
      return;
    }

    final patientName = patient.fullName;
    final recordedBy = AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final extra = _extraNotes.text.trim();
    final notes = extra.isEmpty
        ? 'Şablon: ${template.title} (${template.version})'
        : 'Şablon: ${template.title} (${template.version})\n$extra';

    setState(() => _saving = true);
    try {
      final record = ConsentRecord(
        id: '',
        patientId: _patientId!,
        patientName: patientName,
        createdAt: DateTime.now(),
        consentType: consentTypeFromTemplateCategory(template.category),
        status: ConsentStatus.bekliyor,
        givenAt: null,
        expiresAt: null,
        recordedBy: recordedBy,
        notes: notes,
      );

      final result = await ConsentDocumentPrepareHelper.saveGeneratedDocument(
        template: template,
        patient: patient,
        consent: record,
        recordedBy: recordedBy,
        preparedAt: _preparedAt,
        extraNotes: extra,
      );
      if (!result.success) {
        _showError(result.errorMessage ?? 'Onam evrakı oluşturulamadı.');
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$patientName için onam evrakı oluşturuldu.')),
      );
      context.go('/consents');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _preparerRoleLabel() {
    final role = AuthSession.currentUser?.role;
    if (role == null) return kDisplayUnspecified;
    return AppRoles.roleLabel(role);
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
    if (_loadingTemplate) {
      return const AppShell(
        title: 'Form Hazırla',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final template = _template;
    if (template == null) {
      return AppShell(
        title: 'Form Hazırla',
        child: Center(child: Text(_templateLoadError ?? 'Form şablonu bulunamadı')),
      );
    }

    final preparedBy = AuthSession.currentUser?.displayName ?? '-';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final patient = _selectedPatient;
    final patientLine = patient == null
        ? kDisplayUnspecified
        : '${patient.fullName}${patient.fileNumber.isNotEmpty ? ' • Dosya: ${patient.fileNumber}' : ''}';
    final extraNotePreview = _extraNotes.text.trim().isEmpty
        ? kDisplayUnspecified
        : _extraNotes.text.trim();

    return AppShell(
      title: 'Hasta İçin Form Hazırla',
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
                        PageHeader(
                          title: 'Onam Hazırla',
                          subtitle: template.title,
                          leadingBack: true,
                          fallbackRoute: '/consent-templates',
                        ),
                        Text(
                          'Onam evrakı antetli PDF olarak üretilir, güvenli dosya alanına kaydedilir ve PDF çıktıları listesinde görünür.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.link, size: 16),
                              label: Text(
                                'Kaynak: Onam şablonu (${template.id})',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(template.category),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const PdfLetterheadPreviewCard(),
                        const SizedBox(height: 12),
                        InfoSectionCard(
                          title: 'Seçilen Şablon',
                          rows: [
                            InfoSectionRow(
                              'Şablon adı',
                              template.title,
                              emphasize: true,
                            ),
                            InfoSectionRow('Kategori', template.category),
                            InfoSectionRow('Sürüm', template.version),
                            InfoSectionRow('Gerekli durum', template.requiredFor),
                            InfoSectionRow('Dosya adı', template.documentFileName),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Hasta Seçimi',
                          icon: Icons.person_outline,
                          children: [
                            PatientSelectorField(
                              selectedPatientId: _patientId,
                              labelText: 'Hasta seçin',
                              isDense: true,
                              onChanged: _onPatientChanged,
                            ),
                          ],
                        ),
                        InfoSectionCard(
                          title: 'Hasta',
                          rows: [
                            InfoSectionRow(
                              'Seçili hasta',
                              patientLine,
                              emphasize: patient != null,
                            ),
                          ],
                        ),
                        InfoSectionCard(
                          title: 'Hazırlanacak Belge Özeti',
                          rows: [
                            InfoSectionRow(
                              'Şablon adı',
                              template.title,
                              emphasize: true,
                            ),
                            InfoSectionRow(
                              'Onam türü',
                              consentTypeLabel(
                                consentTypeFromTemplateCategory(template.category),
                              ),
                            ),
                            InfoSectionRow('Seçili hasta', patientLine),
                            InfoSectionRow('Hazırlayan', preparedBy),
                            InfoSectionRow('Hazırlayan rol', _preparerRoleLabel()),
                            InfoSectionRow(
                              'Hazırlanma tarihi',
                              _dateLabel(_preparedAt),
                            ),
                            InfoSectionRow('Ek not', extraNotePreview),
                            InfoSectionRow(
                              'Durum',
                              'PDF evrakı oluşturulacak (onam durumu: ${consentStatusLabel(ConsentStatus.bekliyor)})',
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Ek Not',
                          icon: Icons.note_alt_outlined,
                          children: [
                            TextField(
                              controller: _extraNotes,
                              decoration: const InputDecoration(
                                labelText: 'Ek not',
                                hintText: 'İsteğe bağlı ek açıklama',
                                isDense: true,
                              ),
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                        Text(
                          'Kaydettiğinizde belge PDF olarak oluşturulur. İmzalı nüsha alındığında onam kaydını güncelleyebilirsiniz.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          FormScreenLayout.bottomActions(
            onSave: () => _createConsentRecord(),
            onCancel: _cancel,
            saveLabel: 'Hazırla',
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
