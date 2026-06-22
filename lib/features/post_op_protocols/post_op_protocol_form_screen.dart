import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/auth/user_display_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/post_op_protocol_form_data_source.dart';
import 'models/post_op_protocol.dart';

class PostOpProtocolFormScreen extends StatefulWidget {
  final String? patientId;
  final String? surgeryNoteId;

  const PostOpProtocolFormScreen({
    super.key,
    this.patientId,
    this.surgeryNoteId,
  });

  @override
  State<PostOpProtocolFormScreen> createState() =>
      _PostOpProtocolFormScreenState();
}

class _PostOpProtocolFormScreenState extends State<PostOpProtocolFormScreen> {
  late String? selectedPatientId;
  final surgeryNoteIdCtrl = TextEditingController();
  final protocolTitle = TextEditingController();
  final diagnosisSummary = TextEditingController();
  PostOpPhase? phase;
  final weightBearing = TextEditingController();
  final romLimits = TextEditingController();
  final braceImmobilization = TextEditingController();
  final woundCare = TextEditingController();
  final medicationNotes = TextEditingController();
  final physioInstructions = TextEditingController();
  final exerciseRestrictions = TextEditingController();
  final redFlags = TextEditingController();
  final controlDateCtrl = TextEditingController();
  final returnToSport = TextEditingController();
  final notes = TextEditingController();
  PostOpProtocolStatus status = PostOpProtocolStatus.taslak;
  bool _saving = false;

  static const _denseDecoration = InputDecoration(isDense: true);
  static const EdgeInsets _stackedCardMargin = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    selectedPatientId = widget.patientId;
    if (widget.surgeryNoteId != null) {
      surgeryNoteIdCtrl.text = widget.surgeryNoteId!;
    }
  }

  @override
  void dispose() {
    surgeryNoteIdCtrl.dispose();
    protocolTitle.dispose();
    diagnosisSummary.dispose();
    weightBearing.dispose();
    romLimits.dispose();
    braceImmobilization.dispose();
    woundCare.dispose();
    medicationNotes.dispose();
    physioInstructions.dispose();
    exerciseRestrictions.dispose();
    redFlags.dispose();
    controlDateCtrl.dispose();
    returnToSport.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    if (selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin')),
      );
      return;
    }

    DateTime? controlDate;
    if (controlDateCtrl.text.trim().isNotEmpty) {
      try {
        controlDate = DateTime.parse(controlDateCtrl.text.trim());
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontrol tarihi YYYY-MM-DD formatında olmalı'),
          ),
        );
        return;
      }
    }

    final patient = await PatientLookupDataSource.findById(selectedPatientId!);
    if (!mounted) return;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin')),
      );
      return;
    }

    final protocol = PostOpProtocol(
      id: 'pop${DateTime.now().millisecondsSinceEpoch}',
      patientId: patient.id,
      patientName: patient.fullName,
      surgeryNoteId: surgeryNoteIdCtrl.text.trim().isEmpty
          ? null
          : surgeryNoteIdCtrl.text.trim(),
      createdAt: DateTime.now(),
      protocolTitle: protocolTitle.text.trim().isEmpty
          ? 'Yeni Post-op Protokol'
          : protocolTitle.text.trim(),
      diagnosisOrProcedureSummary: diagnosisSummary.text.trim().isEmpty
          ? '-'
          : diagnosisSummary.text.trim(),
      phase: phase ?? PostOpPhase.genelProtokol,
      weightBearingStatus: weightBearing.text.trim(),
      rangeOfMotionLimits: romLimits.text.trim(),
      braceOrImmobilization: braceImmobilization.text.trim(),
      woundCareNotes: woundCare.text.trim(),
      medicationOrPainControlNotes: medicationNotes.text.trim(),
      physiotherapyInstructions: physioInstructions.text.trim(),
      exerciseRestrictions: exerciseRestrictions.text.trim(),
      redFlags: redFlags.text.trim(),
      controlDate: controlDate,
      returnToSportEstimate:
          returnToSport.text.trim().isEmpty ? '-' : returnToSport.text.trim(),
      createdBy: AuthSession.currentUser?.displayName ??
          UserDisplayNames.mockDoctorLabel,
      status: status,
      notes: notes.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final saved = await PostOpProtocolFormDataSource.create(protocol);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post-op protokol kaydedildi')),
      );
      context.go('/post-op-protocols/${saved.id}');
    } on PostOpProtocolFormException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post-op protokol kaydedilemedi.')),
      );
      setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/post-op-protocols');
    }
  }

  List<Widget> _buildSectionCards() {
    return [
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Hasta ve Protokol Bilgisi',
        children: [
          PatientSelectorField(
            selectedPatientId: selectedPatientId,
            onChanged: (v) => setState(() => selectedPatientId = v),
          ),
          TextFormField(
            controller: protocolTitle,
            decoration: _denseDecoration.copyWith(
              labelText: 'Protokol başlığı',
            ),
          ),
          DropdownButtonFormField<PostOpProtocolStatus>(
            initialValue: status,
            decoration: _denseDecoration.copyWith(labelText: 'Durum'),
            isExpanded: true,
            items: PostOpProtocolStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      postOpProtocolStatusLabel(s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => status = v);
            },
          ),
        ],
      ),
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Ameliyat / Girişim Bağlantısı',
        children: [
          TextFormField(
            controller: surgeryNoteIdCtrl,
            decoration: _denseDecoration.copyWith(
              labelText: 'Ameliyat notu ID (opsiyonel)',
            ),
          ),
          TextFormField(
            controller: diagnosisSummary,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'İşlem / tanı özeti',
            ),
          ),
        ],
      ),
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Post-op Takip Planı',
        children: [
          DropdownButtonFormField<PostOpPhase>(
            initialValue: phase,
            decoration: _denseDecoration.copyWith(labelText: 'Faz'),
            isExpanded: true,
            items: PostOpPhase.values
                .map(
                  (ph) => DropdownMenuItem(
                    value: ph,
                    child: Text(
                      postOpPhaseLabel(ph),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => phase = v),
          ),
          TextFormField(
            controller: weightBearing,
            decoration: _denseDecoration.copyWith(
              labelText: 'Yük verme durumu',
            ),
          ),
          TextFormField(
            controller: romLimits,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'ROM limitleri',
            ),
          ),
          TextFormField(
            controller: braceImmobilization,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'Breys / immobilizasyon',
            ),
          ),
          TextFormField(
            controller: woundCare,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'Yara bakımı',
            ),
          ),
          TextFormField(
            controller: medicationNotes,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'Ağrı kontrolü / ilaç notları',
            ),
          ),
        ],
      ),
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Fizyoterapi ve Egzersiz Önerileri',
        children: [
          TextFormField(
            controller: physioInstructions,
            maxLines: 3,
            decoration: _denseDecoration.copyWith(
              labelText: 'Fizyoterapi talimatları',
            ),
          ),
          TextFormField(
            controller: exerciseRestrictions,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'Egzersiz kısıtlamaları',
            ),
          ),
        ],
      ),
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Kontrol ve Uyarılar',
        children: [
          TextFormField(
            controller: controlDateCtrl,
            decoration: _denseDecoration.copyWith(
              labelText: 'Kontrol tarihi (YYYY-MM-DD)',
            ),
          ),
          TextFormField(
            controller: returnToSport,
            decoration: _denseDecoration.copyWith(
              labelText: 'Spora dönüş tahmini',
            ),
          ),
          TextFormField(
            controller: redFlags,
            maxLines: 2,
            decoration: _denseDecoration.copyWith(
              labelText: 'Kırmızı bayraklar',
            ),
          ),
        ],
      ),
      FormSectionCard(
        panel: true,
        margin: _stackedCardMargin,
        title: 'Ek Notlar',
        children: [
          TextFormField(
            controller: notes,
            maxLines: 3,
            decoration: _denseDecoration.copyWith(labelText: 'Notlar'),
          ),
        ],
      ),
    ];
  }

  Widget _stackedSections(List<Widget> sections) {
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          sections[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalFormScaffold(
      shellTitle: 'Yeni Post-op Protokol',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: _saving ? 'Kaydediliyor...' : 'Kaydet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Yeni Post-op Protokol',
            icon: Icons.assignment_turned_in_outlined,
            leadingBack: true,
            fallbackRoute: '/post-op-protocols',
          ),
          _stackedSections(_buildSectionCards()),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
