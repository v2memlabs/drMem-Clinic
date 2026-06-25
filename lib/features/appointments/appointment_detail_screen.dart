import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../consents/widgets/consent_gate_modal.dart';
import '../pdf_outputs/contextual_pdf_actions.dart';
import 'data/appointment_clinical_handoff.dart';
import 'data/appointment_clinical_handoff_data_source.dart';
import 'data/appointment_detail_data_source.dart';
import 'data/appointment_detail_display.dart';
import 'data/appointment_detail_load_result.dart';
import 'data/appointment_detail_user_messages.dart';
import 'data/appointment_list_refresh.dart';
import 'data/appointment_remote_display.dart';
import 'models/appointment.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String id;

  const AppointmentDetailScreen({super.key, required this.id});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Future<AppointmentDetailLoadResult> _loadFuture;
  AppointmentDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = 0;

  bool get _usesRemote => RepositoryRegistry.usesRemoteAppointments;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (AppointmentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = AppointmentListRefresh.version;
    setState(() {
      _loadFuture = AppointmentDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppointmentDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (result != null && !result.hasError && result.appointment != null) {
          _cachedResult = result;
        }

        if (waiting && _cachedResult == null) {
          return AppShell(
            title: 'Randevu Detayı',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _statusShell(
            title: 'Randevu detayı yüklenemedi',
            message: AppointmentDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        if (result == null && _cachedResult == null) {
          return _statusShell(
            title: 'Randevu detayı yüklenemedi',
            message: AppointmentDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        final active = result ?? _cachedResult!;
        if (active.hasError && _cachedResult == null) {
          return _statusShell(
            title: 'Randevu detayı yüklenemedi',
            message: active.errorMessage,
            showRetry: true,
          );
        }

        if (active.hasError && result != null) {
          return _statusShell(
            title: 'Randevu detayı yüklenemedi',
            message: active.errorMessage,
            showRetry: true,
            showRefreshBar: waiting,
          );
        }

        if (active.appointment == null) {
          return AppShell(
            title: 'Randevu',
            child: ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: 'Randevu bulunamadı',
              description: 'Kayıt bulunamadı veya erişim yok.',
            ),
          );
        }

        return _AppointmentDetailLoadedView(
          appointment: active.appointment!,
          patientFileNumber: active.patientFileNumber,
          usesRemote: _usesRemote,
          refreshing: waiting,
          onEditComplete: _reload,
        );
      },
    );
  }

  Widget _statusShell({
    required String title,
    required String? message,
    required bool showRetry,
    bool showRefreshBar = false,
  }) {
    return AppShell(
      title: 'Randevu Detayı',
      child: Column(
        children: [
          if (showRefreshBar) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: title,
              description: ClinicalStateMessage.safeErrorDescription(message),
              onRetry: showRetry ? _reload : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailLoadedView extends StatefulWidget {
  final Appointment appointment;
  final String? patientFileNumber;
  final bool usesRemote;
  final bool refreshing;
  final VoidCallback onEditComplete;

  const _AppointmentDetailLoadedView({
    required this.appointment,
    required this.patientFileNumber,
    required this.usesRemote,
    required this.refreshing,
    required this.onEditComplete,
  });

  @override
  State<_AppointmentDetailLoadedView> createState() =>
      _AppointmentDetailLoadedViewState();
}

class _AppointmentDetailLoadedViewState
    extends State<_AppointmentDetailLoadedView> {
  bool _handoffInProgress = false;

  Appointment get appointment => widget.appointment;

  Future<void> _startClinicalEncounter(BuildContext context) async {
    if (_handoffInProgress) return;
    setState(() => _handoffInProgress = true);

    try {
      await AppointmentClinicalHandoffDataSource.prepareForClinicalEncounter(
        appointment,
      );
      if (!context.mounted) return;
      AppointmentListRefresh.markStale();
      widget.onEditComplete();
      final location = AppointmentClinicalHandoff.buildNewEncounterLocation(
        patientId: appointment.patientId,
        appointmentId: appointment.id,
      );
      await context.push(location);
    } on AppointmentClinicalHandoffException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            AppointmentClinicalHandoffUserMessages.statusUpdateFailure,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _handoffInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeStr = _formatDateTime(appointment.appointmentDateTime);
    final sections = _buildSections(dateTimeStr);
    final patientLabel = AppointmentRemoteDisplay.patientDisplayName(
      appointment.patientName,
    );

    return ConsentGateScope(
      patientId: appointment.patientId,
      child: AppShell(
        title: 'Randevu Detayı',
        child: Column(
          children: [
            if (widget.refreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ResponsiveDetailPage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: 'Randevu Detayı',
                      icon: Icons.event_outlined,
                      leadingBack: true,
                      fallbackRoute: '/appointments',
                    ),
                    DetailHeaderCard(
                      title: patientLabel,
                      subtitle:
                          '$dateTimeStr · ${appointmentTypeLabel(appointment.type)} · ${appointmentStatusLabel(appointment.status)}',
                    ),
                    ClinicalStackedSections(children: sections),
                    DetailActionsPanel(
                      title: 'İşlemler',
                      topSpacing: 0,
                      actions: _buildActions(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(String dateTimeStr) {
    final patientRows = <InfoSectionRow>[
      if (AppointmentDetailDisplay.showPatientFileNumber(widget.patientFileNumber))
        InfoSectionRow('Hasta dosya no', widget.patientFileNumber!),
      InfoSectionRow('Randevu türü', appointmentTypeLabel(appointment.type)),
      if (AppointmentDetailDisplay.showDuration(
        appointment,
        usesRemote: widget.usesRemote,
      ))
        InfoSectionRow('Süre', '${appointment.durationMinutes} dakika'),
    ];

    final sections = <Widget>[
      InfoSectionCard(
        title: 'Hasta ve Randevu Bilgisi',
        rows: patientRows,
      ),
    ];

    if (AppointmentDetailDisplay.showReasonSection(appointment)) {
      sections.add(
        InfoSectionCard(
          title: 'Randevu Detayı',
          rows: [
            InfoSectionRow(
              'Randevu nedeni',
              appointment.reason.trim(),
              emphasize: true,
            ),
          ],
        ),
      );
    }

    final statusRows = <InfoSectionRow>[
      InfoSectionRow(
        'Durum',
        appointmentStatusLabel(appointment.status),
        emphasize: true,
      ),
    ];
    if (AppointmentDetailDisplay.showControlDate(appointment)) {
      statusRows.add(
        InfoSectionRow(
          'Kontrol tarihi',
          _formatDate(appointment.controlDate!),
        ),
      );
    }

    sections.add(
      InfoSectionCard(
        title: 'Durum ve Takip',
        rows: statusRows,
      ),
    );

    if (AppointmentDetailDisplay.showNotesSection(appointment)) {
      sections.add(
        InfoSectionCard(
          title: 'Notlar',
          rows: [
            InfoSectionRow('Notlar', appointment.notes.trim()),
          ],
        ),
      );
    }

    return sections;
  }

  List<DetailAction> _buildActions(BuildContext context) {
    final patientQuery = '?patientId=${appointment.patientId}';
    final actions = <DetailAction>[];

    if (AppointmentClinicalHandoff.canShowStartEncounter(
      canEditClinicalEncounters: AuthSession.canEditClinicalEncounters,
      patientId: appointment.patientId,
      status: appointment.status,
    )) {
      actions.add(
        DetailAction(
          label: AppointmentClinicalHandoff.startEncounterLabel,
          icon: Icons.medical_information_outlined,
          filled: true,
          onPressed: _handoffInProgress
              ? null
              : () => _startClinicalEncounter(context),
        ),
      );
    }

    if (ContextualPdfActions.canShowCreateAction(
      patientId: appointment.patientId,
    )) {
      actions.add(
        DetailAction(
          label: ContextualPdfActions.createLabel,
          icon: Icons.picture_as_pdf_outlined,
          onPressed: () => context.push(
            ContextualPdfActions.newFromAppointment(
              patientId: appointment.patientId,
              appointmentId: appointment.id,
            ),
          ),
        ),
      );
    }

    actions.addAll([
      DetailAction(
        label: DetailActionLabels.edit,
        icon: Icons.edit_outlined,
        onPressed: () async {
          await context.push('/appointments/${appointment.id}/edit');
          widget.onEditComplete();
        },
      ),
      DetailAction(
        label: DetailActionLabels.viewFile,
        icon: Icons.folder_outlined,
        onPressed: () => context.push('/patients/${appointment.patientId}'),
      ),
      if (AuthSession.canEditAppointments)
        DetailAction(
          label: DetailActionLabels.appointmentCreate,
          onPressed: () => context.push('/appointments/new$patientQuery'),
        ),
    ]);

    return actions;
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${_formatDate(local)} $time';
}
