import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/premium_surface.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/surgery_note_detail_data_source.dart';
import 'data/surgery_note_list_refresh.dart';
import 'data/surgery_note_ownership.dart';
import 'models/surgery_procedure_note.dart';

class SurgeryNoteDetailScreen extends StatefulWidget {
  final String id;

  const SurgeryNoteDetailScreen({super.key, required this.id});

  @override
  State<SurgeryNoteDetailScreen> createState() => _SurgeryNoteDetailScreenState();
}

class _SurgeryNoteDetailScreenState extends State<SurgeryNoteDetailScreen> {
  late Future<SurgeryNoteDetailLoadResult> _loadFuture;
  int _lastRefreshVersion = SurgeryNoteListRefresh.version;
  bool _activatedOnce = false;

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
    if (SurgeryNoteListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = SurgeryNoteListRefresh.version;
    setState(() {
      _loadFuture = SurgeryNoteDetailDataSource.load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ameliyat / Girişim Notu',
      child: FutureBuilder<SurgeryNoteDetailLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;
          if (result == null || result.hasError || result.note == null) {
            return ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Ameliyat / girişim notu bulunamadı',
              description: result?.errorMessage ?? 'Kayıt bulunamadı.',
              onRetry: _reload,
            );
          }

          final note = result.note!;
          final dateStr = _formatDate(note.procedureDate);

          return PatientLookupBuilder(
            patientId: note.patientId,
            builder: (context, patient) {
              final fileNo = patient?.fileNumber ?? '';
              return _buildBody(context, note, dateStr, fileNo);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SurgeryProcedureNote note,
    String dateStr,
    String fileNo,
  ) {
    final canEditNote = SurgeryNoteOwnership.canEditNote(note);

    return ResponsiveDetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Ameliyat / Girişim Notu',
            icon: Icons.medical_services_outlined,
            leadingBack: true,
            fallbackRoute: '/surgery-notes',
          ),
          ClinicalStackedSections(
            children: [
              _SurgeryPatientSummaryCard(
                patientName: note.patientName,
                fileNo: fileNo,
                procedureType: procedureTypeLabel(note.procedureType),
                procedureDate: dateStr,
                side: surgerySideLabel(note.side),
                bodyRegion: surgeryBodyRegionLabel(note.bodyRegion),
                diagnosis: displayField(note.diagnosis),
                surgeon: displayField(note.surgeonName),
                team: displayField(note.assistantInfo),
              ),
              _SurgeryProcedureDetailCard(
                title: surgeryDetailNoteCardTitle(note.procedureType),
                procedureName: displayField(note.procedureName),
                anesthesia: displayField(note.anesthesiaType),
                asaScore: note.asaScore.trim().isEmpty
                    ? kDisplayUnspecified
                    : note.asaScore.trim(),
                tourniquet: tourniquetLabel(note.tourniquetUsed),
                procedureDetails: displayField(note.procedureDetails),
                arthroscopyFindings: note.arthroscopyFindings.trim().isEmpty
                    ? null
                    : displayField(note.arthroscopyFindings),
                implantRows: _implantRows(note.implantOrMaterialInfo),
              ),
              InfoSectionCard(
                title: 'Komplikasyon ve Takip',
                rows: [
                  InfoSectionRow(
                    'Komplikasyon',
                    displayField(note.complications),
                  ),
                  InfoSectionRow(
                    'Post-op öneriler',
                    displayField(note.postOpRecommendations),
                  ),
                  InfoSectionRow(
                    'FTR başlangıç',
                    displayField(note.physiotherapyStartRecommendation),
                  ),
                  InfoSectionRow(
                    'Kontrol planı',
                    displayField(note.controlSchedule),
                  ),
                ],
              ),
              if (note.notes.trim().isNotEmpty)
                InfoSectionCard(
                  title: 'Notlar',
                  rows: [
                    InfoSectionRow('Notlar', displayField(note.notes)),
                  ],
                ),
            ],
          ),
          if (canEditNote ||
              AuthSession.canEditPostOpProtocols ||
              AuthSession.canEditPdfOutputs) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailActionsPanel(
              title: 'İşlemler',
              topSpacing: 0,
              actions: [
                if (canEditNote)
                  DetailAction(
                    label: DetailActionLabels.edit,
                    filled: true,
                    onPressed: () =>
                        context.push('/surgery-notes/${note.id}/edit'),
                  ),
                if (AuthSession.canEditPostOpProtocols)
                  DetailAction(
                    label: DetailActionLabels.postOpProtocolCreate,
                    filled: !canEditNote,
                    onPressed: () => context.push(
                      '/post-op-protocols/new?patientId=${note.patientId}&surgeryNoteId=${note.id}',
                    ),
                  ),
                if (AuthSession.canEditPdfOutputs)
                  DetailAction(
                    label: DetailActionLabels.pdfPrepare,
                    onPressed: () => context.push(
                      '/pdf-outputs/new?patientId=${note.patientId}&source=surgery_note&id=${note.id}',
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

List<InfoSectionRow> _implantRows(String raw) {
  final lines = decodeImplantMaterialLines(raw);
  if (lines.isEmpty) {
    return [
      InfoSectionRow('İmplant / malzeme', kDisplayUnspecified),
    ];
  }
  return [
    for (var i = 0; i < lines.length; i++)
      InfoSectionRow(
        lines.length == 1 ? 'İmplant / malzeme' : 'İmplant / malzeme ${i + 1}',
        lines[i],
      ),
  ];
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String _patientCardTitle(String patientName, String fileNo) {
  final fileLabel =
      fileNo.trim().isEmpty ? kDisplayUnspecified : fileNo.trim();
  return '$patientName · Dosya No: $fileLabel';
}

class _SurgeryPatientSummaryCard extends StatelessWidget {
  final String patientName;
  final String fileNo;
  final String procedureType;
  final String procedureDate;
  final String side;
  final String bodyRegion;
  final String diagnosis;
  final String surgeon;
  final String team;

  const _SurgeryPatientSummaryCard({
    required this.patientName,
    required this.fileNo,
    required this.procedureType,
    required this.procedureDate,
    required this.side,
    required this.bodyRegion,
    required this.diagnosis,
    required this.surgeon,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return _SurgeryDetailSectionCard(
      title: _patientCardTitle(patientName, fileNo),
      children: [
        _SurgeryDetailInlineRow(
          fields: [
            _SurgeryDetailInlineField('İşlem tipi', procedureType),
            _SurgeryDetailInlineField('İşlem tarihi', procedureDate),
          ],
        ),
        _SurgeryDetailInlineRow(
          fields: [
            _SurgeryDetailInlineField('Taraf', side),
            _SurgeryDetailInlineField('Bölge', bodyRegion),
            _SurgeryDetailInlineField('Tanı', diagnosis),
          ],
        ),
        _SurgeryDetailInlineRow(
          fields: [
            _SurgeryDetailInlineField('Cerrah', surgeon),
            _SurgeryDetailInlineField('Ekip', team),
          ],
        ),
      ],
    );
  }
}

class _SurgeryProcedureDetailCard extends StatelessWidget {
  final String title;
  final String procedureName;
  final String anesthesia;
  final String asaScore;
  final String tourniquet;
  final String procedureDetails;
  final String? arthroscopyFindings;
  final List<InfoSectionRow> implantRows;

  const _SurgeryProcedureDetailCard({
    required this.title,
    required this.procedureName,
    required this.anesthesia,
    required this.asaScore,
    required this.tourniquet,
    required this.procedureDetails,
    required this.implantRows,
    this.arthroscopyFindings,
  });

  @override
  Widget build(BuildContext context) {
    return _SurgeryDetailSectionCard(
      title: title,
      children: [
        _SurgeryDetailLabeledValue(
          label: 'İşlem adı',
          value: procedureName,
          emphasize: true,
        ),
        _SurgeryDetailInlineRow(
          fields: [
            _SurgeryDetailInlineField('Anestezi', anesthesia),
            _SurgeryDetailInlineField('ASA', asaScore),
            _SurgeryDetailInlineField('Turnike', tourniquet),
          ],
        ),
        Text(
          procedureDetails,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        if (arthroscopyFindings != null)
          _SurgeryDetailLabeledValue(
            label: 'Artroskopi bulguları',
            value: arthroscopyFindings!,
          ),
        for (final row in implantRows)
          _SurgeryDetailLabeledValue(
            label: row.label,
            value: row.value,
            emphasize: row.emphasize,
          ),
      ],
    );
  }
}

class _SurgeryDetailSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SurgeryDetailSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PremiumSurface.panel(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumSurface.sectionTitle(context, title),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SurgeryDetailInlineField {
  final String label;
  final String value;

  const _SurgeryDetailInlineField(this.label, this.value);
}

class _SurgeryDetailInlineRow extends StatelessWidget {
  final List<_SurgeryDetailInlineField> fields;

  const _SurgeryDetailInlineRow({required this.fields});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560 && fields.length > 2;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                _SurgeryDetailInlineFieldWidget(field: fields[i]),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SurgeryDetailInlineFieldWidget(field: fields[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SurgeryDetailInlineFieldWidget extends StatelessWidget {
  final _SurgeryDetailInlineField field;

  const _SurgeryDetailInlineFieldWidget({required this.field});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
        );
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        );

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: valueStyle,
        children: [
          TextSpan(text: '${field.label}: ', style: labelStyle),
          TextSpan(text: field.value),
        ],
      ),
    );
  }
}

class _SurgeryDetailLabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SurgeryDetailLabeledValue({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: (emphasize
                    ? Theme.of(context).textTheme.bodyMedium
                    : Theme.of(context).textTheme.bodySmall)
                ?.copyWith(
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: emphasize ? 6 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
