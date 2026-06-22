import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_mapper.dart';
import 'package:v2mem_clinic/features/patient_tags/models/patient_tag.dart';

void main() {
  test('fromRow maps patient tag fields', () {
    final tag = PatientTagMapper.fromRow({
      'id': 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
      'name': 'Sporcu',
      'color': 'teal',
      'description': 'Aktif sporcu',
      'is_active': true,
      'created_at': '2026-06-11T10:00:00Z',
      'updated_at': '2026-06-11T10:00:00Z',
    });

    expect(tag.id, 'a1b2c3d4-e5f6-4789-a012-3456789abcde');
    expect(tag.name, 'Sporcu');
    expect(tag.color, PatientTagColor.teal);
    expect(tag.description, 'Aktif sporcu');
    expect(tag.isActive, isTrue);
  });

  test('toInsertRow uses color name and trims name', () {
    final row = PatientTagMapper.toInsertRow(
      tenantId: 'tenant-1',
      name: '  Post-op  ',
      color: PatientTagColor.orange,
      description: 'Takip',
    );

    expect(row['tenant_id'], 'tenant-1');
    expect(row['name'], 'Post-op');
    expect(row['color'], 'orange');
    expect(row['description'], 'Takip');
    expect(row['is_active'], isTrue);
  });
}
