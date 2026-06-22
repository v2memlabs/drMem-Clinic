import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/consent_document_prepare_helper.dart';
import 'data/consent_template_resolver.dart';
import 'models/consent_record.dart';
import 'models/consent_template.dart';

class ConsentFormScreen extends StatefulWidget {
  final String? patientId;
  final String? encounterId;
  final String? initialConsentType;

  const ConsentFormScreen({
    super.key,
    this.patientId,
    this.encounterId,
    this.initialConsentType,
  });

  @override
  State<ConsentFormScreen> createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends State<ConsentFormScreen> {
  String? patientId;
  String? patientName;
  Patient? _selectedPatient;
  ConsentType type = ConsentType.kvkkAydinlatma;
  final notes = TextEditingController();
  bool _saving = false;
  String? _encounterId;

  ConsentTemplate? get _selectedTemplate =>
      ConsentTemplateResolver.resolveActiveTemplate(type);

  ConsentType? _parseInitialType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final value in ConsentType.values) {
      if (value.name == raw.trim()) return value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;
    _encounterId = widget.encounterId?.trim();
    final initialType = _parseInitialType(widget.initialConsentType);
    if (initialType != null) type = initialType;
    _loadInitialPatient();
  }

  Future<void> _loadInitialPatient() async {
    final id = widget.patientId?.trim();
    if (id == null || id.isEmpty) return;
    final patient = await PatientLookupDataSource.findById(id);
    if (!mounted || patient == null) return;
    setState(() {
      _selectedPatient = patient;
      patientName = patient.fullName;
    });
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> _onPatientChanged(String? value) async {
    setState(() => patientId = value);
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _selectedPatient = null;
        patientName = null;
      });
      return;
    }
    final patient = await PatientLookupDataSource.findById(value);
    if (!mounted) return;
    setState(() {
      _selectedPatient = patient;
      patientName = patient?.fullName;
    });
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/consents');
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    if (patientId == null || patientId!.trim().isEmpty) {
      showClinicalSnackBar(context, 'Lütfen hasta seçin', isError: true);
      return;
    }

    final template = _selectedTemplate;
    if (template == null) {
      showClinicalSnackBar(
        context,
        'Seçilen onam tipi için aktif şablon bulunamadı.',
        isError: true,
      );
      return;
    }

    final patient = _selectedPatient;
    if (patient == null) {
      showClinicalSnackBar(
        context,
        'Hasta bilgisi yüklenemedi. Lütfen hastayı tekrar seçin.',
        isError: true,
      );
      return;
    }

    final remoteError = ConsentDocumentPrepareHelper.validateRemoteReady();
    if (remoteError != null) {
      showClinicalSnackBar(context, remoteError, isError: true);
      return;
    }

    final name = patient.fullName;
    final recordedBy =
        AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final extra = notes.text.trim();
    final noteText = extra.isEmpty
        ? 'Şablon: ${template.title} (${template.version})'
        : 'Şablon: ${template.title} (${template.version})\n$extra';

    final consent = ConsentRecord(
      id: '',
      patientId: patientId!.trim(),
      patientName: name,
      createdAt: DateTime.now(),
      consentType: type,
      status: ConsentStatus.bekliyor,
      recordedBy: recordedBy,
      notes: noteText,
      encounterId: _encounterId,
    );

    setState(() => _saving = true);
    try {
      final result = await ConsentDocumentPrepareHelper.saveGeneratedDocument(
        template: template,
        patient: patient,
        consent: consent,
        recordedBy: recordedBy,
        preparedAt: DateTime.now(),
        extraNotes: extra,
      );

      if (!mounted) return;

      if (!result.success) {
        showClinicalSnackBar(
          context,
          result.errorMessage ?? 'Onam evrakı oluşturulamadı.',
          isError: true,
        );
        return;
      }

      final consentId = result.consentId?.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name için onam evrakı oluşturuldu.')),
      );
      if (consentId != null && consentId.isNotEmpty) {
        context.push('/consents/$consentId');
      } else {
        context.push(
          '/consents${widget.patientId != null ? '?patientId=${widget.patientId}' : ''}',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = _selectedTemplate;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ClinicalFormScaffold.sections(
      shellTitle: 'Onam Evrakı Hazırla',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Evrak Oluştur',
      saving: _saving,
      header: const PageHeader(
        title: 'Onam Evrakı Hazırla',
        icon: Icons.assignment_turned_in_outlined,
        leadingBack: true,
        fallbackRoute: '/consents',
      ),
      sections: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Kaydettiğinizde antetli PDF evrakı oluşturulur, güvenli dosya alanına '
            'kaydedilir ve PDF çıktıları listesinde görünür.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
        FormSectionCard(
          title: 'Hasta ve Onam',
          icon: Icons.person_outline,
          children: [
            PatientSelectorField(
              selectedPatientId: patientId,
              onChanged: _onPatientChanged,
              onPatientSelected: (p) => setState(() {
                patientId = p?.id;
                patientName = p?.fullName;
                _selectedPatient = p;
              }),
            ),
            DropdownButtonFormField<ConsentType>(
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Onam Tipi',
                isDense: true,
              ),
              isExpanded: true,
              items: ConsentType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(consentTypeLabel(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => type = v);
              },
            ),
            if (template != null)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Kullanılacak şablon',
                  isDense: true,
                ),
                child: Text(
                  '${template.title} (${template.version})',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Text(
                'Seçilen onam tipi için aktif şablon bulunamadı.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            if (_encounterId != null && _encounterId!.isNotEmpty)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bağlı muayene',
                  isDense: true,
                ),
                child: Text(
                  _encounterId!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Durum'),
              subtitle: const Text(
                'Evrak oluşturulduktan sonra pad veya ıslak imza ile "Alındı" kaydedilir.',
              ),
              trailing: Text(
                consentStatusLabel(ConsentStatus.bekliyor),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        FormSectionCard(
          title: 'Not',
          icon: Icons.event_outlined,
          children: [
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                isDense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
