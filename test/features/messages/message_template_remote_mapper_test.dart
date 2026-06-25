import 'package:flutter_test/flutter_test.dart';

import 'package:v2mem_clinic/features/messages/data/message_template_remote_mapper.dart';
import 'package:v2mem_clinic/features/messages/models/message_template.dart';

void main() {
  group('MessageTemplateRemoteMapper', () {
    test('fromRow maps channel and category enums', () {
      final row = {
        'id': 'tmpl-1',
        'title': 'Randevu Hatırlatma',
        'channel': 'whatsapp',
        'category': 'randevu_hatirlatma',
        'content': 'Merhaba {{hastaAdi}}',
        'is_active': true,
        'created_by_display': 'Sistem',
      };

      final template = MessageTemplateRemoteMapper.fromRow(row);

      expect(template.id, 'tmpl-1');
      expect(template.title, 'Randevu Hatırlatma');
      expect(template.channel, Channel.whatsapp);
      expect(template.category, Category.randevu_hatirlatma);
      expect(template.content, 'Merhaba {{hastaAdi}}');
      expect(template.createdBy, 'Sistem');
      expect(template.isActive, isTrue);
      expect(template.channelLabel, 'WhatsApp');
      expect(template.categoryLabel, 'Randevu Hatırlatma');
    });

    test('toInsertRow maps template fields to db columns', () {
      final template = MessageTemplate(
        id: '',
        title: 'Randevu Hatırlatma',
        channel: Channel.whatsapp,
        category: Category.randevu_hatirlatma,
        content: 'Merhaba {{hastaAdi}}',
        createdBy: 'Dr. Enes',
        isActive: true,
      );

      final row = MessageTemplateRemoteMapper.toInsertRow(
        tenantId: 't-1',
        template: template,
        createdByProfileId: 'profile-1',
        createdByDisplay: 'Dr. Enes',
      );

      expect(row['tenant_id'], 't-1');
      expect(row['title'], 'Randevu Hatırlatma');
      expect(row['channel'], Channel.whatsapp.name);
      expect(row['category'], Category.randevu_hatirlatma.name);
      expect(row['content'], 'Merhaba {{hastaAdi}}');
      expect(row['is_active'], isTrue);
      expect(row['created_by'], 'profile-1');
      expect(row['created_by_display'], 'Dr. Enes');
    });

    test('toUpdateRow maps editable fields', () {
      final template = MessageTemplate(
        id: 'tmpl-1',
        title: 'Güncel Başlık',
        channel: Channel.sms,
        category: Category.kontrol_hatirlatma,
        content: 'Güncel içerik',
        createdBy: 'Dr. Enes',
        isActive: false,
      );

      final row = MessageTemplateRemoteMapper.toUpdateRow(template);

      expect(row['title'], 'Güncel Başlık');
      expect(row['channel'], Channel.sms.name);
      expect(row['category'], Category.kontrol_hatirlatma.name);
      expect(row['content'], 'Güncel içerik');
      expect(row['is_active'], isFalse);
      expect(row.containsKey('tenant_id'), isFalse);
    });
  });
}
