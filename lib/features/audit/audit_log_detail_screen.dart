import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_chip.dart';
import 'data/audit_log_detail_data_source.dart';
import 'data/audit_log_user_messages.dart';
import 'models/audit_log.dart';

class AuditLogDetailScreen extends StatefulWidget {
  final String id;
  const AuditLogDetailScreen({super.key, required this.id});

  @override
  State<AuditLogDetailScreen> createState() => _AuditLogDetailScreenState();
}

class _AuditLogDetailScreenState extends State<AuditLogDetailScreen> {
  late Future<AuditLogDetailLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = AuditLogDetailDataSource.load(widget.id);
  }

  void _reload() {
    setState(() {
      _loadFuture = AuditLogDetailDataSource.load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuditLogDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Audit Log',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final log = result?.log;
        if (snapshot.hasError ||
            result == null ||
            result.notConfigured ||
            result.hasError ||
            log == null) {
          return AppShell(
            title: 'Audit Log',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'İşlem kaydı bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? AuditLogUserMessages.notFound,
              ),
              onRetry: _reload,
            ),
          );
        }

        final dateTimeStr = _formatDateTime(log.createdAt);
        final patientId = log.patientId?.trim() ?? '';

        if (patientId.isEmpty) {
          return _buildAuditBody(context, log, dateTimeStr, '');
        }

        return PatientLookupBuilder(
          patientId: patientId,
          builder: (context, patient) {
            final fileNo = patient?.fileNumber ?? '';
            return _buildAuditBody(context, log, dateTimeStr, fileNo);
          },
        );
      },
    );
  }

  Widget _buildAuditBody(
    BuildContext context,
    AuditLog a,
    String dateTimeStr,
    String fileNo,
  ) {
    final patientDisplay = _patientDisplay(a, fileNo);

    return AppShell(
      title: 'İşlem Detayı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: actionTypeLabel(a.actionType),
              subtitle: '$dateTimeStr • ${a.userName}',
              icon: Icons.history,
              leadingBack: true,
              fallbackRoute: '/audit-logs',
            ),
            DetailHeaderCard(
              title: actionTypeLabel(a.actionType),
              subtitle: '${moduleTypeLabel(a.module)} • $dateTimeStr',
              chips: [
                StatusChip.module(a.module),
                StatusChip(
                  label: a.userRole,
                  tone: StatusChipTone.neutral,
                  icon: Icons.badge_outlined,
                ),
                if (_isSensitiveAction(a.actionType))
                  const StatusChip(
                    label: 'Önemli işlem',
                    tone: StatusChipTone.danger,
                    icon: Icons.priority_high_rounded,
                  ),
              ],
              actions: const [],
            ),
            const SizedBox(height: 12),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'İşlem Özeti',
                  rows: [
                    InfoSectionRow(
                      'İşlem tipi',
                      actionTypeLabel(a.actionType),
                      emphasize: true,
                    ),
                    InfoSectionRow('Modül', moduleTypeLabel(a.module)),
                    InfoSectionRow(
                      'Açıklama',
                      displayField(a.description),
                      emphasize: true,
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Kullanıcı ve Rol Bilgisi',
                  rows: [
                    InfoSectionRow('Kullanıcı', a.userName, emphasize: true),
                    InfoSectionRow('Rol', displayField(a.userRole)),
                    InfoSectionRow(
                      'Kullanıcı ID',
                      displayField(a.userId),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'İlişkili Kayıt / Hasta',
                  rows: [
                    InfoSectionRow('Hasta', patientDisplay, emphasize: true),
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    InfoSectionRow(
                      'Kayıt referansı',
                      a.patientId == null || a.patientId!.isEmpty
                          ? kDisplayUnspecified
                          : a.patientId!,
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Teknik Detaylar',
                  rows: [
                    InfoSectionRow(
                      'IP adresi',
                      a.ipAddress == null || a.ipAddress!.trim().isEmpty
                          ? kDisplayUnspecified
                          : a.ipAddress!.trim(),
                    ),
                    InfoSectionRow(
                      'Cihaz bilgisi',
                      a.deviceInfo == null || a.deviceInfo!.trim().isEmpty
                          ? kDisplayUnspecified
                          : a.deviceInfo!.trim(),
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Zaman Bilgisi',
                  rows: [
                    InfoSectionRow('İşlem zamanı', dateTimeStr, emphasize: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSensitiveAction(ActionType type) {
  return type == ActionType.yetkiDegisikligi || type == ActionType.dosyaSilme;
}

String _patientDisplay(AuditLog a, String fileNo) {
  if (a.patientName != null && a.patientName!.trim().isNotEmpty) {
    final name = a.patientName!.trim();
    return fileNo.isEmpty ? name : '$name • Dosya: $fileNo';
  }
  if (a.patientId != null && a.patientId!.isNotEmpty) {
    return 'Hasta ID: ${a.patientId}';
  }
  return 'Hasta ilişkisi yok';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$d.$m.${local.year} $time';
}
