import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/consents/data/consent_remote_mapper.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';

void main() {
  test('fromRow maps remote row with patient join', () {
    final record = ConsentRemoteMapper.fromRow({
      'id': 'c0000001-0001-4001-8001-000000000001',
      'patient_id': 'b0000001-0001-4001-8001-000000000001',
      'consent_type': 'kvkkAydinlatma',
      'status': 'bekliyor',
      'given_at': null,
      'expires_at': '2027-01-01T00:00:00Z',
      'document_file_name': 'kvkk.pdf',
      'notes': 'Not',
      'recorded_by_display': 'Asistan',
      'created_at': '2026-05-01T09:00:00Z',
      'patients': {
        'first_name': 'Mehmet',
        'last_name': 'Kaya',
      },
    });

    expect(record.patientName, 'Mehmet Kaya');
    expect(record.consentType, ConsentType.kvkkAydinlatma);
    expect(record.status, ConsentStatus.bekliyor);
    expect(record.documentFileName, 'kvkk.pdf');
    expect(record.expiresAt, isNotNull);
  });

  test('toInsertRow maps enum names', () {
    final row = ConsentRemoteMapper.toInsertRow(
      tenantId: 't-1',
      consent: ConsentRecord(
        id: 'c-mock',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 5, 1),
        consentType: ConsentType.acikRiza,
        status: ConsentStatus.bekliyor,
        recordedBy: 'Asistan',
      ),
    );

    expect(row['consent_type'], 'acikRiza');
    expect(row['status'], 'bekliyor');
    expect(row.containsKey('id'), isFalse);
  });

  test('toUpdateRow allowlists mutable fields only', () {
    final row = ConsentRemoteMapper.toUpdateRow(
      ConsentRecord(
        id: 'c-1',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 5, 1),
        consentType: ConsentType.smsIzin,
        status: ConsentStatus.alindi,
        givenAt: DateTime(2026, 5, 2),
        recordedBy: 'Asistan',
        notes: 'Güncellendi',
      ),
    );

    expect(row['status'], 'alindi');
    expect(row['consent_type'], 'smsIzin');
    expect(row.containsKey('patient_id'), isFalse);
    expect(row.containsKey('tenant_id'), isFalse);
  });
}
