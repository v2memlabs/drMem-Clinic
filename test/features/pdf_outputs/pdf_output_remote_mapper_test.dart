import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_remote_mapper.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';

void main() {
  group('PdfOutputRemoteMapper', () {
    test('fromRow maps remote row to PdfOutput with appointment source', () {
      final output = PdfOutputRemoteMapper.fromRow({
        'id': 'pdf-remote-1',
        'tenant_id': 'tenant-a',
        'patient_id': 'p1',
        'document_type': 'muayene_ozeti',
        'source_module': pdfSourceModuleAppointment,
        'source_record_id': 'appt-99',
        'storage_bucket': 'patient-files-private',
        'storage_path': 'tenant/p1/pdf-remote-1.pdf',
        'display_name': 'Randevu Özeti',
        'status': 'hazirlandi',
        'metadata': {
          'created_by_display': 'Dr. Remote',
          'related_diagnosis': 'Menisküs',
          'content_summary': 'Gizli özet metni',
        },
        'created_at': '2026-06-01T10:00:00Z',
        'patients': {'first_name': 'Ahmet', 'last_name': 'Yılmaz'},
      });

      expect(output.id, 'pdf-remote-1');
      expect(output.patientId, 'p1');
      expect(output.patientName, 'Ahmet Yılmaz');
      expect(output.title, 'Randevu Özeti');
      expect(output.documentType, DocumentType.muayeneOzeti);
      expect(output.status, PdfStatus.hazirlandi);
      expect(output.sourceModule, pdfSourceModuleAppointment);
      expect(output.sourceRecordId, 'appt-99');
      expect(output.createdBy, 'Dr. Remote');
      expect(output.relatedDiagnosis, 'Menisküs');
      expect(output.contentSummary, 'Gizli özet metni');
      expect(output.storagePath, 'tenant/p1/pdf-remote-1.pdf');
      expect(output.storageBucket, 'patient-files-private');
    });

    test('fromRow tolerates nullable patient embed and metadata fields', () {
      final output = PdfOutputRemoteMapper.fromRow({
        'id': 'pdf-min',
        'tenant_id': 'tenant-a',
        'patient_id': 'p2',
        'document_type': 'onam_formu',
        'status': 'draft',
        'display_name': '',
        'metadata': {},
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(output.patientName, 'Hasta');
      expect(output.title, isNotEmpty);
      expect(output.status, PdfStatus.taslak);
      expect(output.contentSummary, '');
      expect(output.warningNote, '');
      expect(output.storagePath, isNull);
    });
  });
}
