import 'package:flutter_test/flutter_test.dart';

import 'package:v2mem_clinic/features/messages/data/sent_message_remote_mapper.dart';
import 'package:v2mem_clinic/features/messages/models/message_template.dart';
import 'package:v2mem_clinic/features/messages/models/sent_message.dart';

void main() {
  group('SentMessageRemoteMapper', () {
    test('fromRow maps enum names to display labels', () {
      final row = {
        'id': 'msg-1',
        'patient_id': 'p-1',
        'patient_phone': '+905551112233',
        'channel': 'sms',
        'category': 'kontrol_hatirlatma',
        'template_title': 'Kontrol Hatırlatma',
        'status': 'gonderildi',
        'content_preview': 'Kontrol randevunuz...',
        'related_module': 'Mesajlaşma',
        'notes': '',
        'sent_by_display': 'Asistan',
        'sent_at': '2026-06-21T10:00:00.000Z',
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      };

      final message = SentMessageRemoteMapper.fromRow(row);

      expect(message.id, 'msg-1');
      expect(message.patientName, 'Ayşe Yılmaz');
      expect(message.channel, 'SMS');
      expect(message.category, 'Kontrol Hatırlatma');
      expect(message.status, SendStatus.gonderildi);
      expect(message.sentBy, 'Asistan');
    });

    test('toInsertRow converts display labels to enum names', () {
      final message = SentMessage(
        id: '',
        patientId: 'p-1',
        patientName: 'Ayşe Yılmaz',
        patientPhone: '+905551112233',
        channel: 'WhatsApp',
        category: 'Randevu Hatırlatma',
        templateTitle: 'Randevu Hatırlatma',
        sentAt: DateTime.utc(2026, 6, 21, 10),
        sentBy: 'Asistan',
        status: SendStatus.gonderildi,
        contentPreview: 'Merhaba',
        relatedModule: 'Mesajlaşma',
      );

      final row = SentMessageRemoteMapper.toInsertRow(
        tenantId: 't-1',
        message: message,
        templateId: 'tmpl-1',
        content: 'Merhaba tam içerik',
      );

      expect(row['tenant_id'], 't-1');
      expect(row['patient_id'], 'p-1');
      expect(row['channel'], Channel.whatsapp.name);
      expect(row['category'], Category.randevu_hatirlatma.name);
      expect(row['status'], SendStatus.gonderildi.name);
      expect(row['template_id'], 'tmpl-1');
      expect(row['content'], 'Merhaba tam içerik');
    });
  });
}
