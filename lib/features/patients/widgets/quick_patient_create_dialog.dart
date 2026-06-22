import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/patient_form_user_messages.dart';
import '../data/patient_repository_failure.dart';
import '../data/quick_patient_create_data_source.dart';
import '../models/patient.dart';
import '../../../shared/widgets/clinical_notice.dart';
import '../../../shared/widgets/clinical_notice_tone.dart';

/// Minimal hasta oluşturma — muayene formu bağlamı.
Future<Patient?> showQuickPatientCreateDialog(BuildContext context) {
  return showDialog<Patient>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _QuickPatientCreateDialog(),
  );
}

class _QuickPatientCreateDialog extends StatefulWidget {
  const _QuickPatientCreateDialog();

  @override
  State<_QuickPatientCreateDialog> createState() =>
      _QuickPatientCreateDialogState();
}

class _QuickPatientCreateDialogState extends State<_QuickPatientCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _identityNumber = TextEditingController();

  DateTime? _birthDate;
  String _gender = Patient.unspecifiedLabel;
  String _identityType = Patient.defaultIdentityType;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _identityNumber.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Doğum tarihi (opsiyonel)',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<bool> _confirmSimilarPatients(List<Patient> similar) async {
    final lines = similar
        .take(3)
        .map(QuickPatientCreateDataSource.similarPatientSummary)
        .join('\n');
    final extra = similar.length > 3 ? '\n… ve ${similar.length - 3} kayıt daha' : '';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Benzer hasta kaydı bulundu'),
        content: Text(
          'Aşağıdaki kayıtlar benzer görünüyor:\n\n$lines$extra\n\n'
          'Yine de yeni hasta oluşturmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yine de oluştur'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final phone = _phone.text.trim();

    setState(() => _saving = true);
    try {
      final similar = await QuickPatientCreateDataSource.findSimilarPatients(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (similar.isNotEmpty) {
        final proceed = await _confirmSimilarPatients(similar);
        if (!proceed) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }

      final created = await QuickPatientCreateDataSource.createQuickPatient(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        birthDate: _birthDate,
        gender: _gender,
        identityType: _identityType,
        identityNumber: _identityNumber.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on PatientRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = PatientFormUserMessages.forFailure(e.reason, isEdit: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = PatientFormUserMessages.forFailure(
          PatientRepositoryFailure.unknown,
          isEdit: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth >= 600 ? 480.0 : screenWidth * 0.92;

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Yeni Hasta',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Kapat',
                      ),
                    ],
                  ),
                  ClinicalNotice(
                    tone: ClinicalNoticeTone.info,
                    dense: true,
                    message:
                        'Hızlı kayıt — eksik profil bilgileri hasta kartından tamamlanabilir.',
                    children: const [],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(
                      labelText: 'Ad *',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Ad zorunludur' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(
                      labelText: 'Soyad *',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Soyad zorunludur' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon *',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Telefon zorunludur';
                      }
                      if (!QuickPatientCreateDataSource.isValidPhone(v)) {
                        return 'Geçerli bir telefon numarası girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Doğum tarihi (opsiyonel)',
                      isDense: true,
                    ),
                    child: InkWell(
                      onTap: _saving ? null : _pickBirthDate,
                      child: Text(
                        _birthDate == null
                            ? 'Seçilmedi'
                            : '${_birthDate!.day.toString().padLeft(2, '0')}.'
                                '${_birthDate!.month.toString().padLeft(2, '0')}.'
                                '${_birthDate!.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Cinsiyet (opsiyonel)',
                      isDense: true,
                    ),
                    items: Patient.genderOptions
                        .map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(
                              () => _gender = v ?? Patient.unspecifiedLabel,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _identityType,
                    decoration: const InputDecoration(
                      labelText: 'Kimlik tipi (opsiyonel)',
                      isDense: true,
                    ),
                    items: Patient.identityTypeOptions
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(
                              () => _identityType =
                                  v ?? Patient.defaultIdentityType,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _identityNumber,
                    decoration: const InputDecoration(
                      labelText: 'Kimlik no (opsiyonel)',
                      isDense: true,
                    ),
                    enabled: !_saving,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClinicalNotice(
                      tone: ClinicalNoticeTone.danger,
                      dense: true,
                      message: _errorMessage!,
                      children: const [],
                      actions: const [],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Hastayı oluştur'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
