import '../../../shared/widgets/info_section_card.dart';
import '../models/physiotherapy_session_note.dart';

const int _kSessionShortMax = 60;

/// Hasta detay — son FTR seansı güvenli özet satırları.
abstract final class PatientRehabLastSessionDisplay {
  static PhysiotherapySessionNote? latestSessionFromSorted(
    List<PhysiotherapySessionNote> sessions,
  ) {
    if (sessions.isEmpty) return null;
    final sorted = List<PhysiotherapySessionNote>.from(sessions)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return sorted.first;
  }

  static List<InfoSectionRow> summaryRows(PhysiotherapySessionNote session) {
    final rows = <InfoSectionRow>[
      InfoSectionRow(
        'Son seans tarihi',
        _formatDate(session.sessionDate),
        emphasize: true,
      ),
      InfoSectionRow('Ağrı (VAS)', 'VAS: ${session.painScore}/10'),
      InfoSectionRow(
        'Spora dönüş aşaması',
        session.returnToSportLabel,
      ),
    ];

    if (session.doctorNotificationNeeded) {
      rows.add(
        const InfoSectionRow(
          'Doktor bildirimi',
          'Doktor değerlendirmesi gerekli',
          emphasize: true,
        ),
      );
    }

    final optional = _optionalComplianceOrWarning(session);
    if (optional != null) {
      rows.add(optional);
    }

    return rows;
  }

  static InfoSectionRow? _optionalComplianceOrWarning(
    PhysiotherapySessionNote session,
  ) {
    final warning = session.warningSigns.trim();
    if (warning.isNotEmpty) {
      return InfoSectionRow('Uyarı bulgusu', _truncate(warning, _kSessionShortMax));
    }

    final adherence = session.homeProgramCompliance.trim();
    if (adherence.isNotEmpty &&
        adherence.toLowerCase() != 'bilinmiyor') {
      return InfoSectionRow('Ev programı uyumu', _truncate(adherence, _kSessionShortMax));
    }

    return null;
  }

  static String _truncate(String value, int maxLen) {
    final t = value.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen - 1)}…';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}
