import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/widgets/appointment_week_strip.dart';

void main() {
  testWidgets('week strip shows range label and day cells', (tester) async {
    final weekStart = DateTime(2026, 6, 1);
    final selected = DateTime(2026, 6, 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentWeekStrip(
            weekStart: weekStart,
            selectedDay: selected,
            appointmentCountsByDay: {
              DateTime(2026, 6, 3): 2,
            },
            onDaySelected: (_) {},
            onPreviousWeek: () {},
            onNextWeek: () {},
          ),
        ),
      ),
    );

    expect(find.text('1–7 Haziran 2026'), findsOneWidget);
    expect(find.text('Çar'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  test('weekRangeLabel spans months', () {
    final label = AppointmentWeekStrip.weekRangeLabel(DateTime(2026, 6, 29));
    expect(label, contains('Haziran'));
    expect(label, contains('Temmuz'));
  });
}
