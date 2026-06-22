import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_selector_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/clinical_report_encounter_prefill.dart';
import 'data/clinical_report_cihaz_body_template.dart';
import 'data/clinical_report_durum_bildirir_body_template.dart';
import 'data/clinical_report_istirahat_body_template.dart';
import 'data/clinical_report_ucabilir_body_template.dart';
import 'data/clinical_report_form_data_source.dart';
import 'models/clinical_report.dart';
import '../clinical_encounter/post_encounter_wizard/models/post_encounter_document_kind.dart';
import '../clinical_encounter/post_encounter_wizard/post_encounter_form_save_navigation.dart';

class ClinicalReportFormScreen extends StatefulWidget {
  final String? patientId;
  final String? clinicalEncounterId;
  final String? reportType;
  final String? reportId;
  final bool encounterWizardMode;

  const ClinicalReportFormScreen({
    super.key,
    this.patientId,
    this.clinicalEncounterId,
    this.reportType,
    this.reportId,
    this.encounterWizardMode = false,
  });

  bool get isEditMode => reportId != null && reportId!.trim().isNotEmpty;

  @override
  State<ClinicalReportFormScreen> createState() =>
      _ClinicalReportFormScreenState();
}

class _ClinicalReportFormScreenState extends State<ClinicalReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  String? patientName;
  String? clinicalEncounterId;
  String? clinicalEncounterProtocolNumber;
  ClinicalReportType reportType = ClinicalReportType.istirahat;
  ClinicalReportStatus status = ClinicalReportStatus.taslak;
  final diagnosisCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final deviceNameCtrl = TextEditingController();
  final deviceUsageCtrl = TextEditingController();
  final flightNotesCtrl = TextEditingController();
  final restDaysCtrl = TextEditingController();
  final restrictionNotesCtrl = TextEditingController();
  final statusDurationCtrl = TextEditingController();
  final statusRecommendationCtrl = TextEditingController();
  final supplementaryNotesCtrl = TextEditingController();
  final deviceUsageDurationCtrl = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  ClinicalReportDocumentDateSource documentDateSource =
      ClinicalReportDocumentDateSource.belgeTarihi;
  ClinicalReportTreatmentApproach treatmentApproach =
      ClinicalReportTreatmentApproach.konservatif;
  ClinicalReportStatusSuitability statusSuitability =
      ClinicalReportStatusSuitability.uygun;
  ClinicalReportFlightDecision flightDecision =
      ClinicalReportFlightDecision.ucabilir;
  ClinicalReportWeightBearing? weightBearing;
  bool _istirahatBodyManual = false;
  bool _durumBodyManual = false;
  bool _ucabilirBodyManual = false;
  bool _cihazBodyManual = false;
  bool _syncingIstirahat = false;
  bool _loaded = false;
  bool _saving = false;
  ClinicalReport? _existing;

  bool get _lockPatient =>
      widget.patientId?.trim().isNotEmpty == true ||
      clinicalEncounterId?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId?.trim();
    clinicalEncounterId = widget.clinicalEncounterId?.trim();
    final parsedType =
        ClinicalReportEncounterPrefill.parseReportType(widget.reportType);
    if (parsedType != null) reportType = parsedType;
    _initForm();
  }

  Future<void> _initForm() async {
    if (widget.isEditMode) {
      final existing =
          await ClinicalReportFormDataSource.loadForEdit(widget.reportId!);
      if (existing == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      _existing = existing;
      patientId = existing.patientId;
      patientName = existing.patientName;
      clinicalEncounterId = existing.clinicalEncounterId;
      clinicalEncounterProtocolNumber = existing.clinicalEncounterProtocolNumber;
      reportType = existing.reportType;
      status = existing.status;
      documentDateSource = existing.documentDateSource;
      treatmentApproach =
          existing.treatmentApproach ?? ClinicalReportTreatmentApproach.konservatif;
      diagnosisCtrl.text = existing.diagnosis;
      bodyCtrl.text = existing.bodyText;
      restrictionNotesCtrl.text = existing.restrictionNotes ??
          ClinicalReportIstirahatBodyTemplate.defaultRestrictionNotes;
      statusDurationCtrl.text = existing.statusDuration ?? '';
      statusRecommendationCtrl.text = existing.statusRecommendation ?? '';
      supplementaryNotesCtrl.text = existing.supplementaryNotes ?? '';
      statusSuitability =
          existing.statusSuitability ?? ClinicalReportStatusSuitability.uygun;
      flightDecision =
          existing.flightDecision ?? ClinicalReportFlightDecision.ucabilir;
      deviceUsageDurationCtrl.text = existing.deviceUsageDuration ?? '';
      weightBearing = existing.weightBearing;
      _istirahatBodyManual = existing.reportType == ClinicalReportType.istirahat;
      _durumBodyManual =
          existing.reportType == ClinicalReportType.durumBildirir;
      _ucabilirBodyManual = existing.reportType == ClinicalReportType.ucabilir;
      _cihazBodyManual =
          existing.reportType == ClinicalReportType.cihazKullanim;
      deviceNameCtrl.text = existing.deviceName ?? '';
      deviceUsageCtrl.text = existing.deviceUsageNotes ?? '';
      flightNotesCtrl.text = existing.flightNotes ?? '';
      startDate = existing.startDate;
      endDate = existing.endDate;
      if (existing.restDays != null) {
        restDaysCtrl.text = '${existing.restDays}';
      }
    } else {
      final encounter = await ClinicalReportEncounterPrefill.loadEncounter(
        clinicalEncounterId,
      );
      if (encounter != null) {
        patientId ??= encounter.patientId;
        patientName ??= encounter.patientName;
        clinicalEncounterProtocolNumber ??=
            ClinicalReportEncounterPrefill.protocolFromEncounter(encounter);
        if (diagnosisCtrl.text.trim().isEmpty) {
          diagnosisCtrl.text =
              ClinicalReportEncounterPrefill.diagnosisFromEncounter(encounter);
        }
      }
      if (patientId != null && patientName == null) {
        final patient = await PatientSelectorDataSource.getById(patientId!);
        patientName = patient?.fullName;
      }
      if (reportType == ClinicalReportType.istirahat) {
        restrictionNotesCtrl.text =
            ClinicalReportIstirahatBodyTemplate.defaultRestrictionNotes;
        _applyDefaultIstirahatDates();
        _syncIstirahatBodyFromFields();
      } else if (reportType == ClinicalReportType.durumBildirir) {
        _durumBodyManual = false;
        _syncDurumBodyFromFields();
      } else if (reportType == ClinicalReportType.ucabilir) {
        _ucabilirBodyManual = false;
        _syncUcabilirBodyFromFields();
      } else if (reportType == ClinicalReportType.cihazKullanim) {
        _cihazBodyManual = false;
        _syncCihazBodyFromFields();
      } else if (reportType == ClinicalReportType.diger) {
        bodyCtrl.clear();
      }
    }

    if (mounted) setState(() => _loaded = true);
  }

  void _applyDefaultIstirahatDates() {
    final today = DateTime.now();
    startDate ??= DateTime(today.year, today.month, today.day);
    if (restDaysCtrl.text.trim().isEmpty) {
      restDaysCtrl.text = '7';
    }
    _recomputeIstirahatEndFromDays();
  }

  @override
  void dispose() {
    diagnosisCtrl.dispose();
    bodyCtrl.dispose();
    deviceNameCtrl.dispose();
    deviceUsageCtrl.dispose();
    flightNotesCtrl.dispose();
    restDaysCtrl.dispose();
    restrictionNotesCtrl.dispose();
    statusDurationCtrl.dispose();
    statusRecommendationCtrl.dispose();
    supplementaryNotesCtrl.dispose();
    deviceUsageDurationCtrl.dispose();
    super.dispose();
  }

  void _onDiagnosisChanged(String _) {
    switch (reportType) {
      case ClinicalReportType.istirahat:
        _syncIstirahatBodyFromFields();
      case ClinicalReportType.durumBildirir:
        _syncDurumBodyFromFields();
      case ClinicalReportType.ucabilir:
        _syncUcabilirBodyFromFields();
      case ClinicalReportType.cihazKullanim:
        _syncCihazBodyFromFields();
      case ClinicalReportType.diger:
        break;
    }
  }

  void _onRestDaysChanged(String value) {
    if (reportType != ClinicalReportType.istirahat) return;
    _recomputeIstirahatEndFromDays();
    _syncIstirahatBodyFromFields();
  }

  void _recomputeIstirahatEndFromDays() {
    if (_syncingIstirahat || startDate == null) return;
    final days = int.tryParse(restDaysCtrl.text.trim());
    if (days == null || days < 1) return;
    _syncingIstirahat = true;
    endDate = ClinicalReportIstirahatBodyTemplate.endDateFromStartAndDays(
      startDate!,
      days,
    );
    _syncingIstirahat = false;
  }

  void _recomputeIstirahatDaysFromEnd() {
    if (_syncingIstirahat || startDate == null || endDate == null) return;
    final days = ClinicalReportIstirahatBodyTemplate.restDaysBetween(
      startDate!,
      endDate!,
    );
    if (days == null) return;
    _syncingIstirahat = true;
    restDaysCtrl.text = '$days';
    _syncingIstirahat = false;
  }

  void _syncIstirahatBodyFromFields() {
    if (_istirahatBodyManual ||
        reportType != ClinicalReportType.istirahat ||
        startDate == null ||
        endDate == null) {
      return;
    }
    final days = int.tryParse(restDaysCtrl.text.trim());
    if (days == null || days < 1) return;

    bodyCtrl.text = ClinicalReportIstirahatBodyTemplate.compose(
      diagnosis: diagnosisCtrl.text,
      treatmentApproach: treatmentApproach,
      startDate: startDate!,
      endDate: endDate!,
      restDays: days,
      restrictionNotes: restrictionNotesCtrl.text,
    );
  }

  void _refreshIstirahatTemplate() {
    setState(() => _istirahatBodyManual = false);
    _syncIstirahatBodyFromFields();
  }

  void _syncDurumBodyFromFields() {
    if (_durumBodyManual || reportType != ClinicalReportType.durumBildirir) {
      return;
    }
    bodyCtrl.text = ClinicalReportDurumBildirirBodyTemplate.compose(
      diagnosis: diagnosisCtrl.text,
      treatmentApproach: treatmentApproach,
      duration: statusDurationCtrl.text,
      recommendation: statusRecommendationCtrl.text,
      suitability: statusSuitability,
      supplementaryNotes: supplementaryNotesCtrl.text,
    );
  }

  void _refreshDurumTemplate() {
    setState(() => _durumBodyManual = false);
    _syncDurumBodyFromFields();
  }

  void _syncUcabilirBodyFromFields() {
    if (_ucabilirBodyManual || reportType != ClinicalReportType.ucabilir) {
      return;
    }
    bodyCtrl.text = ClinicalReportUcabilirBodyTemplate.compose(
      diagnosis: diagnosisCtrl.text,
      treatmentApproach: treatmentApproach,
      flightDecision: flightDecision,
      flightConditions: flightNotesCtrl.text,
    );
  }

  void _refreshUcabilirTemplate() {
    setState(() => _ucabilirBodyManual = false);
    _syncUcabilirBodyFromFields();
  }

  void _syncCihazBodyFromFields() {
    if (_cihazBodyManual || reportType != ClinicalReportType.cihazKullanim) {
      return;
    }
    bodyCtrl.text = ClinicalReportCihazBodyTemplate.compose(
      diagnosis: diagnosisCtrl.text,
      treatmentApproach: treatmentApproach,
      deviceUsageDuration: deviceUsageDurationCtrl.text,
      deviceName: deviceNameCtrl.text,
      deviceUsageNotes: deviceUsageCtrl.text,
      weightBearing: weightBearing,
      supplementaryNotes: supplementaryNotesCtrl.text,
    );
  }

  void _refreshCihazTemplate() {
    setState(() => _cihazBodyManual = false);
    _syncCihazBodyFromFields();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
        _recomputeIstirahatEndFromDays();
      } else {
        endDate = picked;
        _recomputeIstirahatDaysFromEnd();
      }
      _syncIstirahatBodyFromFields();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (patientId == null || patientId!.trim().isEmpty) {
      showClinicalSnackBar(context, 'Lütfen hasta seçin.', isError: true);
      return;
    }
    if (bodyCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Rapor metni zorunludur.', isError: true);
      return;
    }
    if (reportType == ClinicalReportType.istirahat) {
      if (startDate == null || endDate == null) {
        showClinicalSnackBar(
          context,
          'İstirahat için başlangıç ve bitiş tarihi zorunludur.',
          isError: true,
        );
        return;
      }
      final days = int.tryParse(restDaysCtrl.text.trim());
      if (days == null || days < 1) {
        showClinicalSnackBar(
          context,
          'Geçerli bir istirahat gün sayısı girin.',
          isError: true,
        );
        return;
      }
    }
    if (reportType == ClinicalReportType.durumBildirir) {
      if (statusDurationCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(context, 'Süre alanı zorunludur.', isError: true);
        return;
      }
      if (statusRecommendationCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(
          context,
          'Öneri / kısıtlama alanı zorunludur.',
          isError: true,
        );
        return;
      }
    }
    if (reportType == ClinicalReportType.ucabilir) {
      if (flightDecision == ClinicalReportFlightDecision.kosullu &&
          flightNotesCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(
          context,
          'Koşullu uçuş için koşullar alanı zorunludur.',
          isError: true,
        );
        return;
      }
    }
    if (reportType == ClinicalReportType.cihazKullanim) {
      if (deviceNameCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(context, 'Cihaz adı zorunludur.', isError: true);
        return;
      }
      if (deviceUsageDurationCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(context, 'Kullanım süresi zorunludur.', isError: true);
        return;
      }
      if (deviceUsageCtrl.text.trim().isEmpty) {
        showClinicalSnackBar(
          context,
          'Kullanım talimatı zorunludur.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _saving = true);
    final performer = AuthSession.currentUser?.displayName ?? 'Hekim';
    final now = DateTime.now();
    final restDays = int.tryParse(restDaysCtrl.text.trim());

    String? protocolNumber = clinicalEncounterProtocolNumber?.trim();
    if ((protocolNumber == null || protocolNumber.isEmpty) &&
        clinicalEncounterId != null &&
        clinicalEncounterId!.trim().isNotEmpty) {
      final encounter = await ClinicalReportEncounterPrefill.loadEncounter(
        clinicalEncounterId,
      );
      protocolNumber =
          ClinicalReportEncounterPrefill.protocolFromEncounter(encounter);
    }
    if (protocolNumber != null && protocolNumber.isEmpty) {
      protocolNumber = null;
    }

    final record = ClinicalReport(
      id: _existing?.id ?? '',
      patientId: patientId!.trim(),
      patientName: patientName ?? 'Hasta',
      clinicalEncounterId: clinicalEncounterId,
      clinicalEncounterProtocolNumber: protocolNumber,
      reportNumber: _existing?.reportNumber,
      documentDateSource: documentDateSource,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: _existing?.createdBy ?? performer,
      status: status,
      reportType: reportType,
      diagnosis: diagnosisCtrl.text.trim(),
      bodyText: bodyCtrl.text.trim(),
      startDate: reportType == ClinicalReportType.istirahat ? startDate : null,
      endDate: reportType == ClinicalReportType.istirahat ? endDate : null,
      restDays: reportType == ClinicalReportType.istirahat ? restDays : null,
      treatmentApproach:
          reportType == ClinicalReportType.istirahat ||
                  reportType == ClinicalReportType.durumBildirir ||
                  reportType == ClinicalReportType.ucabilir ||
                  reportType == ClinicalReportType.cihazKullanim
              ? treatmentApproach
              : null,
      restrictionNotes: reportType == ClinicalReportType.istirahat
          ? (restrictionNotesCtrl.text.trim().isEmpty
              ? null
              : restrictionNotesCtrl.text.trim())
          : null,
      statusDuration: reportType == ClinicalReportType.durumBildirir
          ? statusDurationCtrl.text.trim()
          : null,
      statusRecommendation: reportType == ClinicalReportType.durumBildirir
          ? statusRecommendationCtrl.text.trim()
          : null,
      statusSuitability: reportType == ClinicalReportType.durumBildirir
          ? statusSuitability
          : null,
      supplementaryNotes:
          reportType == ClinicalReportType.durumBildirir ||
                  reportType == ClinicalReportType.cihazKullanim
              ? (supplementaryNotesCtrl.text.trim().isEmpty
                  ? null
                  : supplementaryNotesCtrl.text.trim())
              : null,
      flightDecision: reportType == ClinicalReportType.ucabilir
          ? flightDecision
          : null,
      deviceUsageDuration: reportType == ClinicalReportType.cihazKullanim
          ? deviceUsageDurationCtrl.text.trim()
          : null,
      weightBearing: reportType == ClinicalReportType.cihazKullanim
          ? weightBearing
          : null,
      deviceName: reportType == ClinicalReportType.cihazKullanim
          ? deviceNameCtrl.text.trim()
          : null,
      deviceUsageNotes: reportType == ClinicalReportType.cihazKullanim
          ? (deviceUsageCtrl.text.trim().isEmpty
              ? null
              : deviceUsageCtrl.text.trim())
          : null,
      flightNotes: reportType == ClinicalReportType.ucabilir
          ? (flightNotesCtrl.text.trim().isEmpty
              ? null
              : flightNotesCtrl.text.trim())
          : null,
    );

    try {
      final saved = widget.isEditMode
          ? await ClinicalReportFormDataSource.update(record)
          : await ClinicalReportFormDataSource.create(record);

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, 'Rapor kaydedildi.');
      navigateAfterDocumentSave(
        context,
        encounterWizardMode: widget.encounterWizardMode,
        kind: PostEncounterDocumentKind.clinicalReport,
        documentId: saved.id,
        detailPath: '/clinical-reports/${saved.id}',
      );
    } on ClinicalReportFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        'Rapor kaydedilemedi.',
        isError: true,
      );
    }
  }

  Widget _typeSpecificFields() {
    switch (reportType) {
      case ClinicalReportType.istirahat:
        return FormSectionCard(
          title: 'İstirahat Bilgileri',
          icon: Icons.event_note_outlined,
          children: [
            DropdownButtonFormField<ClinicalReportTreatmentApproach>(
              initialValue: treatmentApproach,
              decoration: const InputDecoration(labelText: 'Tedavi yaklaşımı'),
              items: ClinicalReportTreatmentApproach.values
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(treatmentApproachLabel(a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  treatmentApproach = v;
                  _syncIstirahatBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            _datePickerField(
              emptyLabel: 'Başlangıç tarihi seçilmedi',
              selectedPrefix: 'Başlangıç',
              date: startDate,
              buttonLabel: 'Başlangıç',
              onPick: () => _pickDate(true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: restDaysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'İstirahat gün sayısı',
              ),
              onChanged: _onRestDaysChanged,
            ),
            const SizedBox(height: 12),
            _datePickerField(
              emptyLabel: 'Bitiş tarihi seçilmedi',
              selectedPrefix: 'Bitiş',
              date: endDate,
              buttonLabel: 'Bitiş',
              onPick: () => _pickDate(false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: restrictionNotesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Kısıtlama notu (rapor metni 2. paragraf)',
              ),
              onChanged: (_) => _syncIstirahatBodyFromFields(),
            ),
          ],
        );
      case ClinicalReportType.durumBildirir:
        return FormSectionCard(
          title: 'Durum Bildirir Bilgileri',
          icon: Icons.fact_check_outlined,
          children: [
            DropdownButtonFormField<ClinicalReportTreatmentApproach>(
              initialValue: treatmentApproach,
              decoration: const InputDecoration(labelText: 'Tedavi yaklaşımı'),
              items: ClinicalReportTreatmentApproach.values
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(treatmentApproachLabel(a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  treatmentApproach = v;
                  _syncDurumBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: statusDurationCtrl,
              decoration: const InputDecoration(
                labelText: 'Süre',
                hintText: 'Örn. 2 hafta, 1 ay',
              ),
              onChanged: (_) => _syncDurumBodyFromFields(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: statusRecommendationCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Öneri / kısıtlama',
                hintText: 'Örn. ağır aktiviteden kaçınması',
              ),
              onChanged: (_) => _syncDurumBodyFromFields(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClinicalReportStatusSuitability>(
              initialValue: statusSuitability,
              decoration: const InputDecoration(labelText: 'Uygunluk'),
              items: ClinicalReportStatusSuitability.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(statusSuitabilityFormLabel(s)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  statusSuitability = v;
                  _syncDurumBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: supplementaryNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Serbest anlatım (opsiyonel)',
              ),
              onChanged: (_) => _syncDurumBodyFromFields(),
            ),
          ],
        );
      case ClinicalReportType.ucabilir:
        return FormSectionCard(
          title: 'Uçuş Değerlendirmesi',
          icon: Icons.flight_outlined,
          children: [
            DropdownButtonFormField<ClinicalReportTreatmentApproach>(
              initialValue: treatmentApproach,
              decoration: const InputDecoration(labelText: 'Tedavi yaklaşımı'),
              items: ClinicalReportTreatmentApproach.values
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(treatmentApproachLabel(a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  treatmentApproach = v;
                  _syncUcabilirBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClinicalReportFlightDecision>(
              initialValue: flightDecision,
              decoration: const InputDecoration(labelText: 'Uçuş kararı'),
              items: ClinicalReportFlightDecision.values
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(flightDecisionFormLabel(d)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  flightDecision = v;
                  _syncUcabilirBodyFromFields();
                });
              },
            ),
            if (flightDecision == ClinicalReportFlightDecision.kosullu) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: flightNotesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Uçuş koşulları',
                  hintText:
                      'Kabin basıncı, mobilizasyon, refakatçi, ilaç, sedye vb.',
                ),
                onChanged: (_) => _syncUcabilirBodyFromFields(),
              ),
            ],
          ],
        );
      case ClinicalReportType.cihazKullanim:
        return FormSectionCard(
          title: 'Cihaz Kullanımı',
          icon: Icons.medical_services_outlined,
          children: [
            DropdownButtonFormField<ClinicalReportTreatmentApproach>(
              initialValue: treatmentApproach,
              decoration: const InputDecoration(labelText: 'Tedavi yaklaşımı'),
              items: ClinicalReportTreatmentApproach.values
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(treatmentApproachLabel(a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  treatmentApproach = v;
                  _syncCihazBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deviceNameCtrl,
              decoration: const InputDecoration(labelText: 'Cihaz adı'),
              onChanged: (_) => _syncCihazBodyFromFields(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deviceUsageDurationCtrl,
              decoration: const InputDecoration(
                labelText: 'Kullanım süresi',
                hintText: 'Örn. 4 hafta, 6 ay',
              ),
              onChanged: (_) => _syncCihazBodyFromFields(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deviceUsageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Kullanım talimatı',
                hintText: 'Sürekli / yürürken / gece vb.',
              ),
              onChanged: (_) => _syncCihazBodyFromFields(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClinicalReportWeightBearing?>(
              initialValue: weightBearing,
              decoration: const InputDecoration(
                labelText: 'Yük bindirme (opsiyonel)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Belirtilmedi'),
                ),
                ...ClinicalReportWeightBearing.values.map(
                  (w) => DropdownMenuItem(
                    value: w,
                    child: Text(weightBearingFormLabel(w)),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  weightBearing = v;
                  _syncCihazBodyFromFields();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: supplementaryNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Serbest anlatım (opsiyonel)',
              ),
              onChanged: (_) => _syncCihazBodyFromFields(),
            ),
          ],
        );
      case ClinicalReportType.diger:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  Widget _datePickerField({
    required String emptyLabel,
    required String selectedPrefix,
    required DateTime? date,
    required String buttonLabel,
    required VoidCallback onPick,
  }) {
    final label = date == null
        ? emptyLabel
        : '$selectedPrefix: ${_formatDate(date)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label),
              const SizedBox(height: 8),
              FilledButton(onPressed: onPick, child: Text(buttonLabel)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(label)),
            FilledButton(onPressed: onPick, child: Text(buttonLabel)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Rapor',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (widget.isEditMode && _existing == null) {
      return AppShell(
        title: 'Rapor',
        child: Center(
          child: Text(
            'Rapor kaydı bulunamadı.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Rapor Düzenle' : 'Yeni Rapor',
      onSave: _save,
      onCancel: () => context.pop(),
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: PageHeader(
        title: widget.isEditMode ? 'Rapor Düzenle' : 'Yeni Rapor',
        icon: Icons.description_outlined,
        leadingBack: true,
        fallbackRoute: '/clinical-reports',
      ),
      sections: [
                          FormSectionCard(
                            title: 'Hasta ve Rapor Tipi',
                            icon: Icons.person_outline,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: patientId,
                                lockSelection: _lockPatient,
                                onChanged: (v) => setState(() => patientId = v),
                                onPatientSelected: (p) => setState(() {
                                  patientId = p?.id;
                                  patientName = p?.fullName;
                                }),
                              ),
                              if (clinicalEncounterProtocolNumber != null &&
                                  clinicalEncounterProtocolNumber!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Muayene protokol no',
                                    isDense: true,
                                  ),
                                  child: Text(
                                    clinicalEncounterProtocolNumber!.trim(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                              DropdownButtonFormField<ClinicalReportDocumentDateSource>(
                                initialValue: documentDateSource,
                                decoration: const InputDecoration(
                                  labelText: 'PDF tarih kaynağı',
                                ),
                                items: ClinicalReportDocumentDateSource.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        enabled: s ==
                                                ClinicalReportDocumentDateSource
                                                    .belgeTarihi ||
                                            clinicalEncounterId
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true,
                                        child: Text(
                                          clinicalReportDocumentDateSourceLabel(
                                            s,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => documentDateSource = v);
                                },
                              ),
                              if (_existing?.displayReportNumber case final reportNo?)
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Rapor no',
                                    isDense: true,
                                  ),
                                  child: Text(reportNo),
                                ),
                              DropdownButtonFormField<ClinicalReportType>(
                                initialValue: reportType,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Rapor tipi'),
                                items: ClinicalReportType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          clinicalReportTypeLabel(t),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    reportType = v;
                                    if (v == ClinicalReportType.istirahat) {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      restrictionNotesCtrl.text =
                                          ClinicalReportIstirahatBodyTemplate
                                              .defaultRestrictionNotes;
                                      _applyDefaultIstirahatDates();
                                      _syncIstirahatBodyFromFields();
                                    } else if (v ==
                                        ClinicalReportType.durumBildirir) {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      _ucabilirBodyManual = false;
                                      _cihazBodyManual = false;
                                      _syncDurumBodyFromFields();
                                    } else if (v == ClinicalReportType.ucabilir) {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      _ucabilirBodyManual = false;
                                      _cihazBodyManual = false;
                                      _syncUcabilirBodyFromFields();
                                    } else if (v ==
                                        ClinicalReportType.cihazKullanim) {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      _ucabilirBodyManual = false;
                                      _cihazBodyManual = false;
                                      _syncCihazBodyFromFields();
                                    } else if (v == ClinicalReportType.diger) {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      _ucabilirBodyManual = false;
                                      _cihazBodyManual = false;
                                      bodyCtrl.clear();
                                    } else {
                                      _istirahatBodyManual = false;
                                      _durumBodyManual = false;
                                      _ucabilirBodyManual = false;
                                      _cihazBodyManual = false;
                                    }
                                  });
                                },
                              ),
                              DropdownButtonFormField<ClinicalReportStatus>(
                                initialValue: status,
                                decoration: const InputDecoration(labelText: 'Durum'),
                                items: ClinicalReportStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(clinicalReportStatusLabel(s)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => status = v);
                                },
                              ),
                              TextFormField(
                                controller: diagnosisCtrl,
                                decoration: const InputDecoration(labelText: 'Tanı'),
                                maxLines: 2,
                                onChanged: _onDiagnosisChanged,
                              ),
                            ],
                          ),
                          if (reportType != ClinicalReportType.diger)
                            _typeSpecificFields(),
                          FormSectionCard(
                            title: clinicalReportPdfSalutation,
                            icon: Icons.description_outlined,
                            children: [
                              if (reportType == ClinicalReportType.istirahat)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _refreshIstirahatTemplate,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Şablondan yenile'),
                                  ),
                                ),
                              if (reportType == ClinicalReportType.durumBildirir)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _refreshDurumTemplate,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Şablondan yenile'),
                                  ),
                                ),
                              if (reportType == ClinicalReportType.ucabilir)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _refreshUcabilirTemplate,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Şablondan yenile'),
                                  ),
                                ),
                              if (reportType == ClinicalReportType.cihazKullanim)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _refreshCihazTemplate,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Şablondan yenile'),
                                  ),
                                ),
                              TextFormField(
                                controller: bodyCtrl,
                                maxLines: 8,
                                decoration: InputDecoration(
                                  labelText: reportType == ClinicalReportType.diger
                                      ? 'Serbest metin'
                                      : 'Metin (yalnızca hitap satırı girintili)',
                                  alignLabelWithHint: true,
                                ),
                                onChanged: (_) {
                                  switch (reportType) {
                                    case ClinicalReportType.istirahat:
                                      _istirahatBodyManual = true;
                                    case ClinicalReportType.durumBildirir:
                                      _durumBodyManual = true;
                                    case ClinicalReportType.ucabilir:
                                      _ucabilirBodyManual = true;
                                    case ClinicalReportType.cihazKullanim:
                                      _cihazBodyManual = true;
                                    case ClinicalReportType.diger:
                                      break;
                                  }
                                },
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                              ),
                            ],
                          ),
      ],
    );
  }
}
