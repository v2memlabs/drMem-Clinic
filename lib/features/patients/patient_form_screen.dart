import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../settings/data/tenant_settings_repository_provider.dart';
import '../settings/models/patient_registration_settings.dart';
import '../settings/models/patient_required_field.dart';
import 'data/patient_form_data_source.dart';
import 'data/patient_form_required_field_validator.dart';
import 'data/patient_form_user_messages.dart';
import 'data/patient_list_refresh.dart';
import 'data/patient_repository_failure.dart';
import 'models/patient.dart';

class PatientFormScreen extends StatefulWidget {
  final String? patientId;

  const PatientFormScreen({super.key, this.patientId});

  bool get isEditMode => patientId != null && patientId!.isNotEmpty;

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  Patient? _existing;
  String _fileNumber = '';
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _secondaryPhone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _birth = TextEditingController();
  final _complaint = TextEditingController();
  final _region = TextEditingController();
  final _notes = TextEditingController();
  final _identityNumber = TextEditingController();
  final _nationality = TextEditingController(text: Patient.defaultNationality);
  final _occupation = TextEditingController();
  final _sportBranch = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyRelation = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _emergencyNote = TextEditingController();
  final _insuranceCompany = TextEditingController();
  final _policyNumber = TextEditingController();

  String _gender = Patient.unspecifiedLabel;
  String _identityType = Patient.defaultIdentityType;
  String _bloodType = Patient.unspecifiedLabel;
  String _insuranceType = Patient.defaultInsuranceType;
  bool _loaded = false;
  bool _saving = false;
  String? _initError;
  PatientRegistrationSettings _registrationSettings =
      const PatientRegistrationSettings();

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  Future<void> _initForm() async {
    try {
      _registrationSettings = await TenantSettingsRepositoryProvider.repository
          .loadPatientRegistrationSettings();
      if (widget.isEditMode) {
        final patient = await PatientFormDataSource.loadForEdit(widget.patientId!);
        if (patient != null) {
          _existing = patient;
          _populateFromPatient(patient);
        }
      } else {
        _fileNumber = await PatientFormDataSource.nextFileNumber();
      }
      if (mounted) {
        setState(() => _loaded = true);
      }
    } on PatientRepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = PatientFormUserMessages.forFailure(
            e.reason,
            isEdit: widget.isEditMode,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = PatientFormUserMessages.loadFailure;
        });
      }
    }
  }

  void _populateFromPatient(Patient p) {
    _fileNumber = p.fileNumber;
    _firstName.text = p.firstName;
    _lastName.text = p.lastName;
    _phone.text = p.phone == '-' || p.phone == Patient.unspecifiedLabel ? '' : p.phone;
    _secondaryPhone.text = _emptyToField(p.secondaryPhone);
    _email.text = _emptyToField(p.email);
    _address.text = _emptyToField(p.address);
    _city.text = _emptyToField(p.city);
    _district.text = _emptyToField(p.district);
    _birth.text = p.birthDate.toLocal().toString().split(' ').first;
    _complaint.text = p.primaryComplaint == '-' ? '' : p.primaryComplaint;
    _region.text = p.bodyRegion == '-' ? '' : p.bodyRegion;
    _notes.text = p.notes;
    _identityNumber.text = p.identityNumber;
    _nationality.text = p.nationality;
    _occupation.text = _emptyToField(p.occupation);
    _sportBranch.text = _emptyToField(p.sportBranch);
    _emergencyName.text = _emptyToField(p.emergencyContactName);
    _emergencyRelation.text = _emptyToField(p.emergencyContactRelation);
    _emergencyPhone.text = _emptyToField(p.emergencyContactPhone);
    _emergencyNote.text = _emptyToField(p.emergencyContactNote);
    _insuranceCompany.text = p.insuranceCompany;
    _policyNumber.text = p.policyNumber;
    _gender = Patient.normalizeDropdownValue(
      p.gender,
      Patient.genderOptions,
      Patient.unspecifiedLabel,
    );
    _identityType = Patient.normalizeDropdownValue(
      p.identityType,
      Patient.identityTypeOptions,
      Patient.defaultIdentityType,
    );
    _bloodType = Patient.normalizeDropdownValue(
      p.bloodType,
      Patient.bloodTypeOptions,
      Patient.unspecifiedLabel,
    );
    _insuranceType = Patient.normalizeDropdownValue(
      p.insuranceType,
      Patient.insuranceTypeOptions,
      Patient.defaultInsuranceType,
    );
  }

  static String _emptyToField(String value) {
    final t = value.trim();
    if (t.isEmpty || t == Patient.unspecifiedLabel || t == '-') return '';
    return t;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _secondaryPhone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _district.dispose();
    _birth.dispose();
    _complaint.dispose();
    _region.dispose();
    _notes.dispose();
    _identityNumber.dispose();
    _nationality.dispose();
    _occupation.dispose();
    _sportBranch.dispose();
    _emergencyName.dispose();
    _emergencyRelation.dispose();
    _emergencyPhone.dispose();
    _emergencyNote.dispose();
    _insuranceCompany.dispose();
    _policyNumber.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_saving) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    final route = widget.isEditMode && widget.patientId != null
        ? '/patients/${widget.patientId}'
        : '/patients';
    context.go(route);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Patient? _buildPatientFromForm({required Patient? base}) {
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      _showMessage('Ad ve soyad zorunludur.');
      return null;
    }

    final requiredError = PatientFormRequiredFieldValidator.validateDraft(
      settings: _registrationSettings,
      phone: _phone.text,
      gender: _gender,
      identityNumber: _identityNumber.text,
      email: _email.text,
      address: _address.text,
    );
    if (requiredError != null) {
      _showMessage(requiredError);
      return null;
    }

    DateTime birthDate;
    try {
      birthDate = DateTime.parse(_birth.text.trim());
    } catch (_) {
      _showMessage('Doğum tarihi YYYY-MM-DD formatında olmalı.');
      return null;
    }

    final phone = _phone.text.trim().isEmpty ? '-' : _phone.text.trim();
    final complaint =
        _complaint.text.trim().isEmpty ? '-' : _complaint.text.trim();
    final region = _region.text.trim().isEmpty ? '-' : _region.text.trim();

    final profile = {
      'gender': _gender,
      'identityType': _identityType,
      'identityNumber': _identityNumber.text.trim(),
      'nationality': _nationality.text.trim().isEmpty
          ? Patient.defaultNationality
          : _nationality.text.trim(),
      'bloodType': _bloodType,
      'occupation': _occupation.text.trim(),
      'sportBranch': _sportBranch.text.trim(),
      'secondaryPhone': _secondaryPhone.text.trim(),
      'email': _email.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      'emergencyContactName': _emergencyName.text.trim(),
      'emergencyContactRelation': _emergencyRelation.text.trim(),
      'emergencyContactPhone': _emergencyPhone.text.trim(),
      'emergencyContactNote': _emergencyNote.text.trim(),
      'notes': _notes.text.trim(),
      'insuranceType': _insuranceType,
      'insuranceCompany': _insuranceCompany.text.trim(),
      'policyNumber': _policyNumber.text.trim(),
    };

    if (widget.isEditMode) {
      final existing = base ?? _existing;
      if (existing == null) {
        _showMessage('Hasta bulunamadı.');
        return null;
      }
      return existing.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        birthDate: birthDate,
        primaryComplaint: complaint,
        bodyRegion: region,
        notes: profile['notes'] as String,
        gender: profile['gender'] as String,
        identityType: profile['identityType'] as String,
        identityNumber: profile['identityNumber'] as String,
        nationality: profile['nationality'] as String,
        bloodType: profile['bloodType'] as String,
        occupation: profile['occupation'] as String,
        sportBranch: profile['sportBranch'] as String,
        secondaryPhone: profile['secondaryPhone'] as String,
        email: profile['email'] as String,
        address: profile['address'] as String,
        city: profile['city'] as String,
        district: profile['district'] as String,
        emergencyContactName: profile['emergencyContactName'] as String,
        emergencyContactRelation: profile['emergencyContactRelation'] as String,
        emergencyContactPhone: profile['emergencyContactPhone'] as String,
        emergencyContactNote: profile['emergencyContactNote'] as String,
        insuranceType: profile['insuranceType'] as String,
        insuranceCompany: profile['insuranceCompany'] as String,
        policyNumber: profile['policyNumber'] as String,
      );
    }

    return Patient(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      fileNumber: _fileNumber,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      birthDate: birthDate,
      lastVisitDate: DateTime.now(),
      primaryComplaint: complaint,
      bodyRegion: region,
      notes: profile['notes'] as String,
      gender: profile['gender'] as String,
      identityType: profile['identityType'] as String,
      identityNumber: profile['identityNumber'] as String,
      nationality: profile['nationality'] as String,
      bloodType: profile['bloodType'] as String,
      occupation: profile['occupation'] as String,
      sportBranch: profile['sportBranch'] as String,
      secondaryPhone: profile['secondaryPhone'] as String,
      email: profile['email'] as String,
      address: profile['address'] as String,
      city: profile['city'] as String,
      district: profile['district'] as String,
      emergencyContactName: profile['emergencyContactName'] as String,
      emergencyContactRelation: profile['emergencyContactRelation'] as String,
      emergencyContactPhone: profile['emergencyContactPhone'] as String,
      emergencyContactNote: profile['emergencyContactNote'] as String,
      insuranceType: profile['insuranceType'] as String,
      insuranceCompany: profile['insuranceCompany'] as String,
      policyNumber: profile['policyNumber'] as String,
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final draft = _buildPatientFromForm(base: _existing);
    if (draft == null) return;

    setState(() => _saving = true);

    try {
      if (widget.isEditMode) {
        final saved = await PatientFormDataSource.update(draft);
        if (!mounted) return;
        _showMessage(
          PatientFormUserMessages.successMessage(
            isEdit: true,
            name: saved.fullName,
          ),
        );
        PatientListRefresh.markStale();
        context.go('/patients/${saved.id}');
      } else {
        final saved = await PatientFormDataSource.create(draft);
        if (!mounted) return;
        _showMessage(
          PatientFormUserMessages.successMessage(
            isEdit: false,
            name: saved.fullName,
          ),
        );
        PatientListRefresh.markStale();
        context.go('/patients/${saved.id}');
      }
    } on PatientRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(
        PatientFormUserMessages.forFailure(
          e.reason,
          isEdit: widget.isEditMode,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        PatientFormUserMessages.forFailure(
          PatientRepositoryFailure.unknown,
          isEdit: widget.isEditMode,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _identityNumberLabel {
    switch (_identityType) {
      case 'Pasaport No':
        return 'Pasaport No';
      case 'Yabancı Kimlik No':
        return 'Yabancı Kimlik No';
      case 'T.C. Kimlik No':
        return 'T.C. Kimlik No';
      default:
        return 'Kimlik No';
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required String fallback,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = Patient.normalizeDropdownValue(
      value,
      options,
      fallback,
    );
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$safeValue'),
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      isExpanded: true,
      items: options
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _saving ? null : onChanged,
    );
  }

  String _labelWithRequired(String label, PatientRequiredField field) {
    return _registrationSettings.isRequired(field) ? '$label *' : label;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        isDense: true,
      ),
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Hasta',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (_initError != null) {
      return AppShell(
        title: 'Hasta',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(_initError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (widget.isEditMode && _existing == null) {
      return AppShell(
        title: 'Hasta Düzenle',
        child: Center(
          child: Text(
            'Hasta bulunamadı',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Hasta Düzenle' : 'Yeni Hasta Kaydı',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: widget.isEditMode ? 'Değişiklikleri Kaydet' : 'Kaydet',
      saving: _saving,
      header: PageHeader(
        title: widget.isEditMode ? 'Hasta Düzenle' : 'Yeni Hasta',
        icon: Icons.person_outline,
        leadingBack: true,
        fallbackRoute: widget.isEditMode && widget.patientId != null
            ? '/patients/${widget.patientId}'
            : '/patients',
      ),
      sections: [
                          FormSectionCard(
                            title: 'Kimlik Bilgileri',
                            icon: Icons.badge_outlined,
                            children: [
                              if (_fileNumber.isNotEmpty)
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Dosya No',
                                    helperText: widget.isEditMode
                                        ? 'Değiştirilemez'
                                        : 'Otomatik oluşturulur',
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _fileNumber,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              _textField(controller: _firstName, label: 'Ad *'),
                              _textField(controller: _lastName, label: 'Soyad *'),
                              _textField(
                                controller: _birth,
                                label: 'Doğum Tarihi (YYYY-MM-DD) *',
                              ),
                              _dropdown(
                                label: _labelWithRequired(
                                  'Cinsiyet',
                                  PatientRequiredField.gender,
                                ),
                                value: _gender,
                                options: Patient.genderOptions,
                                fallback: Patient.unspecifiedLabel,
                                onChanged: (v) => setState(
                                  () => _gender = v ?? Patient.unspecifiedLabel,
                                ),
                              ),
                              _textField(controller: _nationality, label: 'Uyruk'),
                              _dropdown(
                                label: 'Kimlik Tipi',
                                value: _identityType,
                                options: Patient.identityTypeOptions,
                                fallback: Patient.defaultIdentityType,
                                onChanged: (v) => setState(
                                  () => _identityType =
                                      v ?? Patient.defaultIdentityType,
                                ),
                              ),
                              _textField(
                                controller: _identityNumber,
                                label: _labelWithRequired(
                                  _identityNumberLabel,
                                  PatientRequiredField.identityNumber,
                                ),
                                helperText: 'Kimlik tipine göre giriniz',
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'İletişim',
                            icon: Icons.phone_outlined,
                            children: [
                              _textField(
                                controller: _phone,
                                label: _labelWithRequired(
                                  'Telefon',
                                  PatientRequiredField.phone,
                                ),
                              ),
                              _textField(
                                controller: _secondaryPhone,
                                label: 'İkinci Telefon',
                              ),
                              _textField(
                                controller: _email,
                                label: _labelWithRequired(
                                  'E-posta',
                                  PatientRequiredField.email,
                                ),
                              ),
                              _textField(
                                controller: _address,
                                label: _labelWithRequired(
                                  'Adres',
                                  PatientRequiredField.address,
                                ),
                                maxLines: 2,
                              ),
                              _textField(controller: _district, label: 'İlçe'),
                              _textField(controller: _city, label: 'İl'),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Klinik / İdari',
                            icon: Icons.medical_information_outlined,
                            children: [
                              _dropdown(
                                label: 'Kan Grubu',
                                value: _bloodType,
                                options: Patient.bloodTypeOptions,
                                fallback: Patient.unspecifiedLabel,
                                onChanged: (v) => setState(
                                  () => _bloodType = v ?? Patient.unspecifiedLabel,
                                ),
                              ),
                              _textField(controller: _occupation, label: 'Meslek'),
                              _textField(
                                controller: _sportBranch,
                                label: 'Spor Branşı',
                              ),
                              _textField(
                                controller: _notes,
                                label: 'Notlar',
                                maxLines: 3,
                              ),
                              _dropdown(
                                label: 'Sigorta Türü',
                                value: _insuranceType,
                                options: Patient.insuranceTypeOptions,
                                fallback: Patient.defaultInsuranceType,
                                onChanged: (v) => setState(
                                  () => _insuranceType =
                                      v ?? Patient.defaultInsuranceType,
                                ),
                              ),
                              _textField(
                                controller: _insuranceCompany,
                                label: 'Sigorta Şirketi',
                              ),
                              _textField(
                                controller: _policyNumber,
                                label: 'Poliçe Numarası',
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Acil Kişi',
                            icon: Icons.contact_emergency_outlined,
                            children: [
                              _textField(
                                controller: _emergencyName,
                                label: 'Ad Soyad',
                              ),
                              _textField(
                                controller: _emergencyRelation,
                                label: 'Yakınlık',
                              ),
                              _textField(
                                controller: _emergencyPhone,
                                label: 'Telefon',
                              ),
                              _textField(
                                controller: _emergencyNote,
                                label: 'Not',
                                maxLines: 2,
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Klinik Ön Bilgi',
                            icon: Icons.notes_outlined,
                            children: [
                              _textField(
                                controller: _complaint,
                                label: 'Ana Şikayet',
                              ),
                              _textField(controller: _region, label: 'Bölge'),
                            ],
                          ),
      ],
    );
  }
}
