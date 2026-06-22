import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../features/surgery/data/surgery_procedure_note_lookup_data_source.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/post_op_protocol_detail_data_source.dart';
import 'models/post_op_protocol.dart';
import 'widgets/post_op_protocol_identity_band.dart';

class PostOpProtocolDetailScreen extends StatefulWidget {
  final String id;

  const PostOpProtocolDetailScreen({super.key, required this.id});

  @override
  State<PostOpProtocolDetailScreen> createState() =>
      _PostOpProtocolDetailScreenState();
}

class _PostOpProtocolDetailScreenState
    extends State<PostOpProtocolDetailScreen> {
  static const EdgeInsets _stackedCardMargin = EdgeInsets.zero;

  late Future<PostOpProtocolDetailLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = PostOpProtocolDetailDataSource.load(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostOpProtocolDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Post-op Takip',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final protocol = result?.protocol;
        if (snapshot.hasError ||
            result == null ||
            result.hasError ||
            protocol == null) {
          return AppShell(
            title: 'Post-op Takip',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Post-op protokol bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = PostOpProtocolDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        final createdStr = _formatDate(protocol.createdAt);
        final controlStr = protocol.controlDate != null
            ? _formatDate(protocol.controlDate!)
            : kDisplayUnspecified;

        return FutureBuilder<String>(
          future: _resolveSurgeryLine(protocol),
          builder: (context, surgerySnapshot) {
            final surgeryLine = surgerySnapshot.data ?? kDisplayUnspecified;
            return PatientLookupBuilder(
              patientId: protocol.patientId,
              builder: (context, patient) {
                final fileNo = patient?.fileNumber ?? '';
                return _buildPostOpBody(
                  context,
                  protocol,
                  createdStr,
                  controlStr,
                  fileNo,
                  surgeryLine,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _resolveSurgeryLine(PostOpProtocol protocol) async {
    final surgeryNoteId = protocol.surgeryNoteId?.trim();
    if (surgeryNoteId == null || surgeryNoteId.isEmpty) {
      return kDisplayUnspecified;
    }

    final note =
        await SurgeryProcedureNoteLookupDataSource.findById(surgeryNoteId);
    return note?.procedureName ?? 'Ameliyat notu: $surgeryNoteId';
  }

  Widget _buildPostOpBody(
    BuildContext context,
    PostOpProtocol protocol,
    String createdStr,
    String controlStr,
    String fileNo,
    String surgeryLine,
  ) {
    final sectionCards = _buildSectionCards(
      protocol,
      createdStr,
      controlStr,
      fileNo,
      surgeryLine,
    );

    return AppShell(
      title: 'Post-op Takip',
      child: ResponsiveListPage(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Post-op Takip',
                icon: Icons.assignment_turned_in_outlined,
                leadingBack: true,
                fallbackRoute: '/post-op-protocols',
              ),
              PostOpProtocolDetailHeader(
                protocol: protocol,
                fileNumber: fileNo.isEmpty ? null : fileNo,
              ),
              ClinicalStackedSections(children: sectionCards),
              if (AuthSession.canEditPdfOutputs) ...[
                const SizedBox(height: AppSpacing.sm),
                DetailActionsPanel(
                  title: 'İşlemler',
                  topSpacing: 0,
                  actions: [
                    DetailAction(
                      label: DetailActionLabels.pdfPrepare,
                      filled: true,
                      onPressed: () => context.push(
                        '/pdf-outputs/new?patientId=${protocol.patientId}&source=post_op_protocol&id=${protocol.id}',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  List<InfoSectionCard> _buildSectionCards(
    PostOpProtocol protocol,
    String createdStr,
    String controlStr,
    String fileNo,
    String surgeryLine,
  ) {
    return [
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Hasta ve Protokol Bilgisi',
        rows: [
          InfoSectionRow(
            'Hasta',
            protocol.patientName,
            emphasize: true,
          ),
          InfoSectionRow(
            'Hasta dosya no',
            fileNo.isEmpty ? kDisplayUnspecified : fileNo,
          ),
          InfoSectionRow(
            'Protokol başlığı',
            displayField(protocol.protocolTitle),
            emphasize: true,
          ),
          InfoSectionRow('Oluşturulma tarihi', createdStr),
          InfoSectionRow('Oluşturan', displayField(protocol.createdBy)),
          InfoSectionRow(
            'Durum',
            postOpProtocolStatusLabel(protocol.status),
          ),
        ],
      ),
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Ameliyat / Girişim Bağlantısı',
        rows: [
          InfoSectionRow(
            'İlgili ameliyat / girişim',
            surgeryLine,
          ),
          InfoSectionRow(
            'İşlem / tanı özeti',
            displayField(protocol.diagnosisOrProcedureSummary),
          ),
        ],
      ),
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Post-op Takip Planı',
        rows: [
          InfoSectionRow('Faz', postOpPhaseLabel(protocol.phase)),
          InfoSectionRow(
            'Yük verme',
            displayField(protocol.weightBearingStatus),
          ),
          InfoSectionRow(
            'ROM limitleri',
            displayField(protocol.rangeOfMotionLimits),
          ),
          InfoSectionRow(
            'Breys / immobilizasyon',
            displayField(protocol.braceOrImmobilization),
          ),
          InfoSectionRow(
            'Yara bakımı',
            displayField(protocol.woundCareNotes),
          ),
          InfoSectionRow(
            'Ağrı kontrolü / ilaç notları',
            displayField(protocol.medicationOrPainControlNotes),
          ),
        ],
      ),
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Fizyoterapi ve Egzersiz Önerileri',
        rows: [
          InfoSectionRow(
            'Fizyoterapi talimatları',
            displayField(protocol.physiotherapyInstructions),
          ),
          InfoSectionRow(
            'Egzersiz kısıtlamaları',
            displayField(protocol.exerciseRestrictions),
          ),
        ],
      ),
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Kontrol ve Uyarılar',
        rows: [
          InfoSectionRow('Kontrol tarihi', controlStr),
          InfoSectionRow(
            'Spora dönüş tahmini',
            displayField(protocol.returnToSportEstimate),
          ),
          InfoSectionRow(
            'Kırmızı bayraklar',
            displayField(protocol.redFlags),
          ),
        ],
      ),
      InfoSectionCard(
        margin: _stackedCardMargin,
        title: 'Ek Notlar',
        rows: [
          InfoSectionRow('Notlar', displayField(protocol.notes)),
        ],
      ),
    ];
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
