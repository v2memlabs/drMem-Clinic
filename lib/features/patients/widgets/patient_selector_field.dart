import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/repository_registry.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../data/patient_identity_privacy.dart';
import '../data/patient_list_state_messages.dart';
import '../data/patient_list_load_result.dart';
import '../data/patient_selector_data_source.dart';
import '../models/patient.dart';

/// Hasta listesi satırı ve seçici alanı için kısa alt bilgi.
String patientSelectorSubtitle(Patient patient) {
  final contact = patient.phone.trim().isNotEmpty
      ? patient.phone.trim()
      : Patient.unspecifiedLabel;
  final identity = PatientIdentityPrivacy.formatIdentityLineForDisplay(patient);
  final insurance = patient.insuranceType != Patient.defaultInsuranceType
      ? patient.insuranceType
      : null;

  final parts = <String>[patient.fileNumber, contact];
  if (identity != null) parts.add(identity);
  if (insurance != null) parts.add(insurance);
  return parts.join(' • ');
}

/// Formlarda standart hasta seçimi alanı.
class PatientSelectorField extends StatefulWidget {
  final String? selectedPatientId;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<Patient?>? onPatientSelected;
  final bool isRequired;
  final bool enabled;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool isDense;
  /// Route bağlamında hasta önceden seçiliyse seçici kilitlenir (değiştirilemez).
  final bool lockSelection;
  /// Üst formda zaten çözümlenmiş hasta (ör. hızlı oluşturma sonrası anında gösterim).
  final Patient? selectedPatientPreview;

  const PatientSelectorField({
    super.key,
    this.selectedPatientId,
    this.selectedPatientPreview,
    this.onChanged,
    this.onPatientSelected,
    this.isRequired = true,
    this.enabled = true,
    this.labelText = 'Hasta',
    this.hintText,
    this.validator,
    this.isDense = false,
    this.lockSelection = false,
  });

  @override
  State<PatientSelectorField> createState() => _PatientSelectorFieldState();
}

class _PatientSelectorFieldState extends State<PatientSelectorField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  Patient? _resolvedPatient;
  bool _loadingPatient = false;
  bool _patientNotFound = false;

  Patient? _patientForDisplay(String? fieldValue) {
    final id = fieldValue ?? widget.selectedPatientId;
    if (id == null || id.isEmpty) return null;
    if (_resolvedPatient?.id == id) return _resolvedPatient;
    final preview = widget.selectedPatientPreview;
    if (preview != null && preview.id == id) return preview;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedPatient(widget.selectedPatientId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormFieldValue());
  }

  @override
  void didUpdateWidget(PatientSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPatientId != widget.selectedPatientId ||
        oldWidget.selectedPatientPreview != widget.selectedPatientPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncFormFieldValue();
        _loadSelectedPatient(widget.selectedPatientId);
      });
    }
  }

  void _syncFormFieldValue() {
    final id = widget.selectedPatientId;
    if (id == null || id.isEmpty) return;
    _fieldKey.currentState?.didChange(id);
  }

  Future<void> _loadSelectedPatient(String? id) async {
    if (id == null || id.isEmpty) {
      if (mounted) {
        setState(() {
          _resolvedPatient = null;
          _loadingPatient = false;
          _patientNotFound = false;
        });
      }
      return;
    }

    final preview = widget.selectedPatientPreview;
    final hasPreview = preview != null && preview.id == id;

    if (_resolvedPatient?.id == id && !hasPreview) return;

    if (!hasPreview) {
      setState(() {
        _loadingPatient = true;
        _patientNotFound = false;
      });
    } else {
      _resolvedPatient = preview;
      _patientNotFound = false;
      _loadingPatient = false;
      // Locked referral/session/exercise flows may not have direct patient
      // list access for the current role. A provided preview should remain
      // visible instead of being replaced with a not-found state.
      if (widget.lockSelection) {
        _syncFormFieldValue();
        return;
      }
    }

    final patient = await PatientSelectorDataSource.getById(id);
    if (!mounted) return;
    setState(() {
      _loadingPatient = false;
      if (patient != null) {
        _resolvedPatient = patient;
        _patientNotFound = false;
        widget.onPatientSelected?.call(patient);
      } else {
        // Locked flows may intentionally carry a patient id from source
        // context even when current role cannot fetch patient details.
        if (widget.lockSelection) {
          _patientNotFound = false;
        } else {
          _resolvedPatient = null;
          _patientNotFound = true;
        }
      }
    });
    if (patient != null) {
      _syncFormFieldValue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.selectedPatientId,
      validator: widget.validator ??
          (value) {
            if (!widget.isRequired) return null;
            final effective = (value != null && value.isNotEmpty)
                ? value
                : widget.selectedPatientId;
            if (effective == null || effective.isEmpty) {
              return 'Hasta seçiniz';
            }
            return null;
          },
      builder: (field) {
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final pickerEnabled = widget.enabled && !widget.lockSelection;

        Future<void> openPicker() async {
          if (!pickerEnabled) return;
          final picked = await showPatientPickerDialog(
            context: context,
            selectedPatientId: field.value,
          );
          if (picked == null) return;
          field.didChange(picked.id);
          setState(() => _resolvedPatient = picked);
          widget.onChanged?.call(picked.id);
          widget.onPatientSelected?.call(picked);
        }

        Widget child;
        if (_loadingPatient && field.value != null && field.value!.isNotEmpty) {
          child = Row(
            children: [
              SizedBox(
                width: widget.isDense ? 16 : 18,
                height: widget.isDense ? 16 : 18,
                child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Hasta yükleniyor…',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: muted,
                    ),
              ),
            ],
          );
        } else if (_patientNotFound && widget.lockSelection) {
          final effectiveId = field.value ?? widget.selectedPatientId;
          child = Text(
            effectiveId == null || effectiveId.isEmpty
                ? 'Hasta kaydı bulunamadı veya erişim yok.'
                : 'Seçili hasta (erişim kısıtlı).',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: effectiveId == null || effectiveId.isEmpty
                      ? Theme.of(context).colorScheme.error
                      : muted,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        } else if (_patientForDisplay(field.value) != null) {
          final patient = _patientForDisplay(field.value)!;
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                patient.fullName,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                patientSelectorSubtitle(patient),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        } else {
          child = Text(
            widget.hintText ?? 'Hasta seçiniz',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: muted,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return InkWell(
          onTap: pickerEnabled ? openPicker : null,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText ?? 'Hasta seçiniz',
              isDense: widget.isDense,
              suffixIcon: pickerEnabled
                  ? Icon(
                      _patientForDisplay(field.value) == null
                          ? Icons.person_search_outlined
                          : Icons.swap_horiz,
                      size: widget.isDense ? 20 : 24,
                    )
                  : widget.lockSelection && _patientForDisplay(field.value) != null
                      ? Icon(
                          Icons.lock_outline,
                          size: widget.isDense ? 18 : 20,
                          color: muted,
                        )
                      : null,
              errorText: field.errorText,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Hasta arama ve seçim diyaloğu.
Future<Patient?> showPatientPickerDialog({
  required BuildContext context,
  String? selectedPatientId,
}) {
  return showDialog<Patient>(
    context: context,
    builder: (ctx) => _PatientPickerDialog(
      selectedPatientId: selectedPatientId,
    ),
  );
}

class _PatientPickerDialog extends StatefulWidget {
  final String? selectedPatientId;

  const _PatientPickerDialog({
    this.selectedPatientId,
  });

  @override
  State<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<_PatientPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  late Future<PatientListLoadResult> _loadFuture;
  Timer? _searchDebounce;

  static const Duration _remoteSearchDebounce = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _loadFuture = PatientSelectorDataSource.loadPatients(_query);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _loadFuture = PatientSelectorDataSource.loadPatients(_query);
    });
  }

  void _onSearchChanged(String value) {
    _query = value;
    _searchDebounce?.cancel();

    if (RepositoryRegistry.usesRemotePatients) {
      _searchDebounce = Timer(_remoteSearchDebounce, () {
        if (mounted) _reload();
      });
      return;
    }

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth >= 600 ? 520.0 : screenWidth * 0.92;

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        height: screenWidth >= 600 ? 520 : 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hasta Seçimi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Kapat',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Ara',
                  hintText: 'Ad, dosya no, telefon, kimlik…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<PatientListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null) {
                    return _messageCenter(context, 'Hasta listesi yüklenemedi.');
                  }

                  if (result.hasError) {
                    return _messageCenter(
                      context,
                      ClinicalStateMessage.safeErrorDescription(
                        result.errorMessage,
                      ),
                    );
                  }

                  return _buildList(context, result.patients);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCenter(BuildContext context, String message) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Patient> patients) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (patients.isEmpty) {
      final message = _query.trim().isEmpty
          ? PatientListStateMessages.emptyDbTitle
          : PatientListStateMessages.emptyDescription(query: _query);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final patient = patients[index];
        final selected = patient.id == widget.selectedPatientId;
        return ListTile(
          selected: selected,
          title: Text(
            patient.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            patientSelectorSubtitle(patient),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () => Navigator.of(context).pop(patient),
        );
      },
    );
  }
}
