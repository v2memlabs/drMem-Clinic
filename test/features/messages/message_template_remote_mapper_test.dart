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
  });
}
