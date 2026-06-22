import 'dart:async';

import 'package:flutter/material.dart';

import 'date_time_chip.dart';
import 'holiday_calendar_sheet.dart';

/// Canlı tarih/saat pill — PageHeader ile aynı satırda kullanılır.
class ShellClockChip extends StatefulWidget {
  const ShellClockChip({super.key});

  @override
  State<ShellClockChip> createState() => _ShellClockChipState();
}

class _ShellClockChipState extends State<ShellClockChip> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openCalendar() {
    showHolidayCalendarSheet(context, initialDate: _now);
  }

  @override
  Widget build(BuildContext context) {
    return DateTimeChip(
      dateTime: _now,
      onTap: _openCalendar,
    );
  }
}
