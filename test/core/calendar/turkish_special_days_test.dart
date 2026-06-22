import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/calendar/turkish_special_days.dart';

void main() {
  test('includes fixed national holidays', () {
    final days = TurkishSpecialDays.forYear(2026);
    expect(
      days.any((d) => d.title.contains('Cumhuriyet Bayramı')),
      isTrue,
    );
    expect(
      days.any((d) => d.title.contains('Ramazan Bayramı')),
      isTrue,
    );
  });

  test('upcoming filters within range', () {
    final upcoming = TurkishSpecialDays.upcoming(withinDays: 400);
    expect(upcoming, isNotEmpty);
    for (final day in upcoming) {
      expect(day.date.year, greaterThanOrEqualTo(DateTime.now().year));
    }
  });
}
