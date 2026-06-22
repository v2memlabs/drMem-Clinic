import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/session/record_ownership_context.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/premium_surface.dart';
import '../../features/settings/models/tenant_membership_user.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/appointment_availability_data_source.dart';
import 'data/appointment_form_data_source.dart';
import 'data/appointment_schedule_bootstrap.dart';
import 'data/appointment_form_user_messages.dart';
import 'data/appointment_date_query_parser.dart';
import 'data/appointment_type_query_parser.dart';
import 'data/appointment_list_refresh.dart';
import 'data/appointment_repository_failure.dart';
import '../physiotherapy/data/physiotherapy_referral_appointment_bridge_data_source.dart';
import '../physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'models/appointment.dart';
import 'models/clinic_schedule_config.dart';
import 'widgets/appointment_schedule_section.dart';
import 'widgets/doctor_selector_field.dart';

class AppointmentFormScreen extends StatefulWidget {
  final String? patientId;
  final String? referralId;
  final String? appointmentId;
  final String? initialTypeQuery;
  final String? initialDateQuery;

  const AppointmentFormScreen({
    super.key,
    this.patientId,
    this.referralId,
    this.appointmentId,
    this.initialTypeQuery,
    this.initialDateQuery,
  });

  bool get isEditMode =>
      appointmentId != null && appointmentId!.isNotEmpty;

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  Patient? _selectedPatient;
  Appointment? _existing;
  DateTime date = DateTime.now();
  DateTime? _selectedSlotStart;
  DateTime? _initialAppointmentSlotStart;
  int duration = ClinicScheduleConfig.defaultClinic().slotDurationMinutes;
  AppointmentType type = AppointmentType.ilkMuayene;
  AppointmentStatus status = AppointmentStatus.planlandi;
  final reasonCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? _assignedDoctorProfileId;
  String? _assignedDoctorName;

  bool _loaded = false;
  bool _saving = false;
  String? _initError;

  bool get _usesRemote => RepositoryRegistry.usesRemoteAppointments;

  bool get _lockPatientFromRoute =>
      !widget.isEditMode &&
      widget.patientId != null &&
      widget.patientId!.trim().isNotEmpty;

  bool get _showPhysiotherapySchedulingNotice =>
      !widget.isEditMode && type == AppointmentType.fizikTedavi;

  String? _effectivePatientId() {
    final stateId = patientId?.trim();
    if (stateId != null && stateId.isNotEmpty) return stateId;
    final routeId = widget.patientId?.trim();
    if (routeId != null && routeId.isNotEmpty) return routeId;
    return null;
  }

  Future<void> _initForm() async {
    if (!widget.isEditMode) {
      final pid = _effectivePatientId();
      if (pid != null) {
        final exists = await AppointmentFormDataSource.patientExists(pid);
        if (!exists && mounted) {
          setState(() {
            _loaded = true;
            _initError =
                'Hasta kaydı bulunamadı veya erişim yok. Lütfen hasta detayından tekrar deneyin.';
          });
          return;
        }
      }
      if (mounted) setState(() => _loaded = true);
      return;
    }

    try {
      final appointment =
          await AppointmentFormDataSource.loadForEdit(widget.appointmentId!);
      if (appointment == null) {
        if (mounted) {
          setState(() {
            _loaded = true;
            _initError = 'Randevu bulunamadı.';
          });
        }
        return;
      }

      _existing = appointment;
      _populateFromAppointment(appointment);
      if (mounted) setState(() => _loaded = true);
    } on AppointmentRepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = AppointmentFormUserMessages.forFailure(
            e.reason,
            isEdit: true,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = AppointmentFormUserMessages.loadFailure;
        });
      }
    }
  }

  void _populateFromAppointment(Appointment ap) {
    patientId = ap.patientId;
    final local = ap.appointmentDateTime.toLocal();
    date = DateTime(local.year, local.month, local.day);
    _selectedSlotStart = DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    _initialAppointmentSlotStart = _selectedSlotStart;
    duration = ap.durationMinutes;
    type = ap.type;
    status = ap.status;
    reasonCtrl.text = ap.reason;
    notesCtrl.text = ap.notes;
    _assignedDoctorProfileId = ap.assignedDoctorProfileId;
    _assignedDoctorName = ap.assignedDoctorName;
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureSlotDurationFromConfig() async {
    final config = await AppointmentAvailabilityDataSource.loadScheduleConfig();
    if (!mounted) return;
    if (!widget.isEditMode) {
      setState(() => duration = config.slotDurationMinutes);
    }
  }

  Future<void> _bootstrapInitialDate() async {
    final resolved = await AppointmentScheduleBootstrap.resolveInitialDay();
    if (!mounted) return;
    setState(() => date = resolved);
  }

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId?.trim().isNotEmpty == true
        ? widget.patientId!.trim()
        : null;
    if (!widget.isEditMode) {
      final parsed =
          AppointmentTypeQueryParser.fromQuery(widget.initialTypeQuery);
      if (parsed != null) type = parsed;

      final parsedDate =
          AppointmentDateQueryParser.fromQuery(widget.initialDateQuery);
      date = parsedDate ?? DateTime.now();
      if (!AuthSession.canSelectAppointmentDoctor &&
          !(AuthSession.isPhysiotherapist && type == AppointmentType.fizikTedavi)) {
        _assignedDoctorProfileId = RecordOwnershipContext.currentProfileId();
        _assignedDoctorName = RecordOwnershipContext.currentDisplayName();
      }
      if (parsedDate == null) {
        unawaited(_bootstrapInitialDate());
      }
    }
    _ensureSlotDurationFromConfig();
    _initForm();
  }

  void _cancel() {
    if (_saving) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (widget.isEditMode && widget.appointmentId != null) {
      context.go('/appointments/${widget.appointmentId}');
      return;
    }
    context.go('/appointments');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Appointment _applyOwnershipFields(Appointment draft) {
    final profileId = RecordOwnershipContext.currentProfileId();

    if (AuthSession.isPhysiotherapist &&
        draft.type == AppointmentType.fizikTedavi) {
      return Appointment(
        id: draft.id,
        patientId: draft.patientId,
        patientName: draft.patientName,
        appointmentDateTime: draft.appointmentDateTime,
        durationMinutes: draft.durationMinutes,
        type: draft.type,
        status: draft.status,
        reason: draft.reason,
        controlDate: draft.controlDate,
        notes: draft.notes,
        assignedDoctorProfileId: draft.assignedDoctorProfileId,
        assignedDoctorName: draft.assignedDoctorName,
        assignedPhysiotherapistProfileId:
            profileId ?? draft.assignedPhysiotherapistProfileId,
        createdByProfileId: profileId ?? draft.createdByProfileId,
      );
    }

    var doctorId = _assignedDoctorProfileId;
    var doctorName = _assignedDoctorName;
    if (!AuthSession.canSelectAppointmentDoctor) {
      doctorId = profileId;
      doctorName = RecordOwnershipContext.currentDisplayName();
    }

    return Appointment(
      id: draft.id,
      patientId: draft.patientId,
      patientName: draft.patientName,
      appointmentDateTime: draft.appointmentDateTime,
      durationMinutes: draft.durationMinutes,
      type: draft.type,
      status: draft.status,
      reason: draft.reason,
      controlDate: draft.controlDate,
      notes: draft.notes,
      assignedDoctorProfileId: doctorId,
      assignedDoctorName: doctorName,
      assignedPhysiotherapistProfileId: draft.assignedPhysiotherapistProfileId ??
          (_existing?.assignedPhysiotherapistProfileId),
      createdByProfileId: profileId ?? _existing?.createdByProfileId,
    );
  }

  Future<Appointment?> _buildAppointmentFromForm() async {
    if (!widget.isEditMode) {
      final pid = _effectivePatientId();
      if (pid == null || pid.isEmpty) {
        return null;
      }
      if (!await AppointmentFormDataSource.patientExists(pid)) {
        _showMessage('Seçilen hasta bulunamadı. Lütfen tekrar seçin.');
        return null;
      }
    }

    final slot = _selectedSlotStart;
    if (slot == null) {
      _showMessage('Lütfen bir randevu saati seçin.');
      return null;
    }
    final dt = slot;

    if (widget.isEditMode) {
      final existing = _existing;
      if (existing == null) {
        _showMessage('Randevu bulunamadı.');
        return null;
      }

      return _applyOwnershipFields(
        Appointment(
          id: existing.id,
          patientId: existing.patientId,
          patientName: existing.patientName,
          appointmentDateTime: dt,
          durationMinutes: _usesRemote ? existing.durationMinutes : duration,
          type: type,
          status: status,
          reason: _usesRemote ? existing.reason : reasonCtrl.text.trim(),
          controlDate: existing.controlDate,
          notes: notesCtrl.text.trim(),
          assignedPhysiotherapistProfileId:
              existing.assignedPhysiotherapistProfileId,
          createdByProfileId: existing.createdByProfileId,
        ),
      );
    }

    final pid = _effectivePatientId()!;
    final resolvedName = await AppointmentFormDataSource.resolvePatientName(
      patientId: pid,
      selectedPatient: _selectedPatient,
    );

    return _applyOwnershipFields(
      Appointment(
        id: '',
        patientId: pid,
        patientName: resolvedName,
        appointmentDateTime: dt,
        durationMinutes: _usesRemote ? 30 : duration,
        type: type,
        status: status,
        reason: _usesRemote ? '' : reasonCtrl.text.trim(),
        controlDate: null,
        notes: notesCtrl.text.trim(),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_loaded) return;
    if (_initError != null) return;

    final effectivePid = _effectivePatientId();
    if (effectivePid != null && effectivePid.isNotEmpty) {
      patientId = effectivePid;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedSlotStart == null) {
      _showMessage('Lütfen bir randevu saati seçin.');
      return;
    }

    if (AuthSession.canSelectAppointmentDoctor &&
        (_assignedDoctorProfileId == null ||
            _assignedDoctorProfileId!.trim().isEmpty)) {
      _showMessage('Lütfen randevu verilecek doktoru seçin.');
      return;
    }

    final draft = await _buildAppointmentFromForm();
    if (draft == null) return;

    setState(() => _saving = true);

    try {
      final saved = widget.isEditMode
          ? await AppointmentFormDataSource.update(draft)
          : await AppointmentFormDataSource.create(draft);

      final referralId = widget.referralId?.trim();
      if (!widget.isEditMode &&
          referralId != null &&
          referralId.isNotEmpty &&
          saved.id.trim().isNotEmpty) {
        await PhysiotherapyReferralAppointmentBridgeDataSource
            .syncAfterAppointmentCreate(
          referralId: referralId,
          appointmentId: saved.id,
          plannedStartDate: saved.appointmentDateTime,
        );
        PhysiotherapyReferralListRefresh.markStale();
      }

      if (!mounted) return;
      _showMessage(
        AppointmentFormUserMessages.successMessage(
          isEdit: widget.isEditMode,
        ),
      );
      AppointmentListRefresh.markStale();
      if (referralId != null && referralId.isNotEmpty) {
        context.go('/physiotherapy/referrals/$referralId');
      } else {
        context.go('/appointments/${saved.id}');
      }
    } on AppointmentRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(
        AppointmentFormUserMessages.forFailure(
          e.reason,
          isEdit: widget.isEditMode,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        AppointmentFormUserMessages.forFailure(
          AppointmentRepositoryFailure.unknown,
          isEdit: widget.isEditMode,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle =
        widget.isEditMode ? 'Randevu Düzenle' : 'Randevu Oluştur';
    final headerTitle = widget.isEditMode ? 'Randevu Düzenle' : 'Yeni Randevu';

    if (!_loaded) {
      return AppShell(
        title: screenTitle,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );
    }

    if (_initError != null) {
      return AppShell(
        title: screenTitle,
        child: ClinicalStateMessage.error(
          icon: Icons.error_outline,
          title: 'Form yüklenemedi',
          description: ClinicalStateMessage.safeErrorDescription(_initError),
          onRetry: widget.isEditMode
              ? () {
                  setState(() {
                    _loaded = false;
                    _initError = null;
                  });
                  _initForm();
                }
              : null,
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: screenTitle,
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: PageHeader(
        title: headerTitle,
        icon: Icons.event_outlined,
        leadingBack: true,
        fallbackRoute: widget.isEditMode && widget.appointmentId != null
            ? '/appointments/${widget.appointmentId}'
            : '/appointments',
      ),
      beforeSections: [
        if (_showPhysiotherapySchedulingNotice)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClinicalNotice(
              tone: ClinicalNoticeTone.info,
              dense: true,
              message: AppointmentFormUserMessages.physiotherapySchedulingNotice,
            ),
          ),
      ],
      sections: [
        Container(
          decoration: PremiumSurface.panel(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PatientSelectorField(
                  selectedPatientId: patientId,
                  lockSelection: _lockPatientFromRoute,
                  enabled: !widget.isEditMode &&
                      !_saving &&
                      !_lockPatientFromRoute,
                  onChanged: widget.isEditMode || _saving
                      ? null
                      : (v) => setState(() => patientId = v),
                  onPatientSelected: (p) =>
                      setState(() => _selectedPatient = p),
                ),
                const SizedBox(height: AppSpacing.sm),
                DoctorSelectorField(
                  selectedDoctorProfileId: _assignedDoctorProfileId,
                  readOnly: !AuthSession.canSelectAppointmentDoctor,
                  enabled: !_saving,
                  onChanged: AuthSession.canSelectAppointmentDoctor && !_saving
                      ? (value) => setState(() {
                            _assignedDoctorProfileId = value;
                          })
                      : null,
                  onDoctorSelected: (TenantMembershipUser? doctor) => setState(() {
                    _assignedDoctorName = doctor?.displayName;
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppointmentScheduleSection(
                  key: const Key('appointment_schedule_section'),
                  selectedDate: date,
                  selectedSlotStart: _selectedSlotStart,
                  excludeAppointmentId:
                      widget.isEditMode ? widget.appointmentId : null,
                  preserveCurrentSlotStart: widget.isEditMode
                      ? _initialAppointmentSlotStart
                      : null,
                  preserveCurrentDurationMinutes:
                      widget.isEditMode ? duration : null,
                  isEditMode: widget.isEditMode,
                  enabled: !_saving,
                  onDateChanged: (d) => setState(() {
                    date = DateTime(d.year, d.month, d.day);
                    _selectedSlotStart = null;
                  }),
                  onSlotSelected: (slot) => setState(() {
                    _selectedSlotStart = slot;
                    if (slot != null && !widget.isEditMode) {
                      duration = ClinicScheduleConfig.defaultClinic()
                          .slotDurationMinutes;
                    }
                  }),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AppointmentType>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Randevu Türü',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: AppointmentType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  appointmentTypeLabel(t),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            _saving ? null : (v) => setState(() => type = v!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<AppointmentStatus>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: AppointmentStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  appointmentStatusLabel(s),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => status = v!),
                      ),
                    ),
                  ],
                ),
                if (!_usesRemote) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Randevu Nedeni',
                      isDense: true,
                    ),
                    enabled: !_saving,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  enabled: !_saving,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
