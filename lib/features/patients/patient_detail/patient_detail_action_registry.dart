import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../clinical_encounter/data/clinical_summary_module_availability.dart';
import '../../patient_tags/data/patient_tag_module_availability.dart';
import '../../pdf_outputs/contextual_pdf_actions.dart';
import '../../../shared/widgets/detail_action_labels.dart';
import 'patient_detail_action_context.dart';

/// Stable action ids — architecture / registry tests.
abstract final class PatientDetailActionIds {
  static const materialCharge = 'material_charge';
  static const pdfCreate = 'pdf_create';
  static const physioRefer = 'physio_refer';
  static const appointments = 'appointments';
  static const newAppointment = 'new_appointment';
  static const ftrAppointment = 'ftr_appointment';
  static const files = 'files';
  static const consents = 'consents';
  static const payments = 'payments';
  static const diagnosisSummary = 'diagnosis_summary';
  static const messages = 'messages';
  static const patientTags = 'patient_tags';
  static const physioReferrals = 'physio_referrals';
  static const physioSessions = 'physio_sessions';
  static const paymentCreate = 'payment_create';
  static const inventory = 'inventory';
}

enum PatientDetailCardKind { file, rehab, assistantSummary }

class PatientDetailAction {
  final String id;
  final String label;
  final IconData icon;
  final bool Function(PatientDetailActionContext ctx) isVisible;
  final bool Function(PatientDetailActionContext ctx) hideFromList;
  final PatientDetailCardKind? cardKind;
  final bool launchesMaterialCharge;
  final String Function(PatientDetailActionContext ctx)? routeBuilder;
  final void Function(BuildContext context, PatientDetailActionContext ctx)?
      onNavigate;

  const PatientDetailAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.isVisible,
    this.hideFromList = _neverHide,
    this.cardKind,
    this.launchesMaterialCharge = false,
    this.routeBuilder,
    this.onNavigate,
  });

  static bool _neverHide(PatientDetailActionContext ctx) => false;

  void invoke(BuildContext context, PatientDetailActionContext ctx) {
    if (onNavigate != null) {
      onNavigate!(context, ctx);
      return;
    }
    final route = routeBuilder?.call(ctx);
    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }
}

abstract final class PatientDetailActionRegistry {
  static const listTitle = 'Hasta İşlemleri';

  static bool _hideWhenFileCard(PatientDetailActionContext ctx) =>
      ctx.showsFilePreviewCard;

  static bool _hideWhenRehabCard(PatientDetailActionContext ctx) =>
      ctx.showsRehabPreviewCard;

  static bool _hideWhenAssistantSummaryCard(PatientDetailActionContext ctx) =>
      ctx.showsAssistantSummaryCard;

  static final List<PatientDetailAction> _all = [
    PatientDetailAction(
      id: PatientDetailActionIds.materialCharge,
      label: 'Malzeme Şarjı',
      icon: Icons.medical_services_outlined,
      isVisible: (_) => AuthSession.canChargePatientMaterials,
      launchesMaterialCharge: true,
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.pdfCreate,
      label: ContextualPdfActions.createLabel,
      icon: Icons.picture_as_pdf_outlined,
      cardKind: PatientDetailCardKind.file,
      isVisible: (ctx) =>
          ContextualPdfActions.canShowCreateAction(patientId: ctx.patientId),
      hideFromList: _hideWhenFileCard,
      onNavigate: (context, ctx) => context.push(
        ContextualPdfActions.newFromPatient(ctx.patientId),
      ),
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.files,
      label: 'Tümünü gör',
      icon: Icons.folder_outlined,
      cardKind: PatientDetailCardKind.file,
      isVisible: (ctx) => ctx.showsFilePreviewCard,
      hideFromList: _hideWhenFileCard,
      routeBuilder: (ctx) => '/files${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.physioRefer,
      label: DetailActionLabels.physiotherapyRefer,
      icon: Icons.person_search_outlined,
      cardKind: PatientDetailCardKind.rehab,
      isVisible: (_) =>
          AuthSession.canViewClinicalEncounters &&
          AuthSession.canViewPhysiotherapy,
      hideFromList: _hideWhenRehabCard,
      onNavigate: (context, ctx) {
        final encounterId = ctx.latestClinicalEncounterId;
        final path = encounterId != null
            ? '/physiotherapy/referrals/new?patientId=${ctx.patientId}&clinicalEncounterId=$encounterId'
            : '/physiotherapy/referrals/new?patientId=${ctx.patientId}';
        context.push(path);
      },
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.diagnosisSummary,
      label: 'Tüm özetler',
      icon: Icons.healing_outlined,
      cardKind: PatientDetailCardKind.assistantSummary,
      isVisible: (_) =>
          AuthSession.canViewClinicalDiagnosisSummary &&
          ClinicalSummaryModuleAvailability.assistantOperational,
      hideFromList: _hideWhenAssistantSummaryCard,
      routeBuilder: (ctx) =>
          '/clinical-records/diagnosis-summary${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.appointments,
      label: 'Randevular',
      icon: Icons.event_outlined,
      isVisible: (_) => AuthSession.canViewAppointments,
      routeBuilder: (ctx) => '/appointments${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.newAppointment,
      label: 'Yeni randevu',
      icon: Icons.event_available_outlined,
      isVisible: (_) => AuthSession.canEditAppointments,
      routeBuilder: (ctx) => '/appointments/new${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.ftrAppointment,
      label: 'FTR randevusu',
      icon: Icons.healing_outlined,
      isVisible: (_) => AuthSession.canBookReferralAppointments,
      routeBuilder: (ctx) =>
          '/appointments/new?patientId=${ctx.patientId}&type=fizikTedavi',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.consents,
      label: 'Onamlar',
      icon: Icons.shield_outlined,
      isVisible: (_) => AuthSession.canViewConsents,
      routeBuilder: (ctx) => '/consents${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.payments,
      label: 'Ödeme / Tahsilat',
      icon: Icons.payments_outlined,
      isVisible: (_) => AuthSession.canViewPayments,
      routeBuilder: (ctx) => '/payments${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.messages,
      label: 'Mesajlar',
      icon: Icons.mail_outline,
      isVisible: (_) => AuthSession.canViewMessages,
      routeBuilder: (ctx) => '/messages/sent${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.patientTags,
      label: 'Hasta Etiketleri',
      icon: Icons.label_outline,
      isVisible: (_) =>
          AuthSession.canViewPatientTags &&
          PatientTagModuleAvailability.isOperational,
      routeBuilder: (ctx) => '/patient-tags${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.physioReferrals,
      label: 'Fizyoterapi Yönlendirmeleri',
      icon: Icons.person_search_outlined,
      isVisible: (_) =>
          AuthSession.canViewPhysiotherapy &&
          !AuthSession.canViewClinicalEncounters,
      routeBuilder: (ctx) => '/physiotherapy/referrals${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.physioSessions,
      label: 'Seans Notları',
      icon: Icons.note_alt_outlined,
      isVisible: (_) =>
          AuthSession.canViewPhysiotherapy &&
          !AuthSession.canViewClinicalEncounters,
      routeBuilder: (ctx) => '/physiotherapy/sessions${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.paymentCreate,
      label: 'Tahsilat ekle',
      icon: Icons.add_card_outlined,
      isVisible: (_) =>
          AuthSession.canViewPhysiotherapy &&
          !AuthSession.canViewClinicalEncounters &&
          AuthSession.canCreatePayments,
      routeBuilder: (ctx) => '/payments/new${ctx.patientQuery}',
    ),
    PatientDetailAction(
      id: PatientDetailActionIds.inventory,
      label: 'Stok / Sarf',
      icon: Icons.inventory_2_outlined,
      isVisible: (_) => AuthSession.canViewInventory,
      routeBuilder: (_) => '/inventory',
    ),
  ];

  static List<PatientDetailAction> listActions(PatientDetailActionContext ctx) {
    return _resolve(ctx, includeList: true, cardKind: null);
  }

  static List<PatientDetailAction> cardTrailingActions(
    PatientDetailActionContext ctx,
    PatientDetailCardKind cardKind,
  ) {
    return _resolve(ctx, includeList: false, cardKind: cardKind);
  }

  static List<PatientDetailAction> _resolve(
    PatientDetailActionContext ctx, {
    required bool includeList,
    required PatientDetailCardKind? cardKind,
  }) {
    return _all.where((action) {
      if (!action.isVisible(ctx)) return false;
      if (includeList) {
        if (action.cardKind != null) return false;
        if (action.hideFromList(ctx)) return false;
        return _roleAllowsListAction(action.id);
      }
      return action.cardKind == cardKind;
    }).toList(growable: false);
  }

  static bool _roleAllowsListAction(String id) {
    if (AuthSession.canViewClinicalEncounters) {
      return const {
        PatientDetailActionIds.materialCharge,
        PatientDetailActionIds.appointments,
        PatientDetailActionIds.newAppointment,
        PatientDetailActionIds.ftrAppointment,
      }.contains(id);
    }
    if (AuthSession.canViewClinicalDiagnosisSummary) {
      return const {
        PatientDetailActionIds.materialCharge,
        PatientDetailActionIds.appointments,
        PatientDetailActionIds.consents,
        PatientDetailActionIds.payments,
        PatientDetailActionIds.messages,
        PatientDetailActionIds.patientTags,
      }.contains(id);
    }
    if (AuthSession.canViewPhysiotherapy &&
        !AuthSession.canViewClinicalEncounters) {
      return const {
        PatientDetailActionIds.materialCharge,
        PatientDetailActionIds.appointments,
        PatientDetailActionIds.physioReferrals,
        PatientDetailActionIds.physioSessions,
        PatientDetailActionIds.payments,
        PatientDetailActionIds.paymentCreate,
      }.contains(id);
    }
    return const {
      PatientDetailActionIds.materialCharge,
      PatientDetailActionIds.inventory,
    }.contains(id);
  }
}
