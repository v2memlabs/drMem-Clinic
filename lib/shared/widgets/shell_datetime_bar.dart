import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'date_time_chip.dart';
import 'holiday_calendar_sheet.dart';

/// AppShell üst bandı — tüm ekranlarda sabit tarih/saat.
class ShellDateTimeBar extends StatefulWidget {
  const ShellDateTimeBar({super.key});

  @override
  State<ShellDateTimeBar> createState() => _ShellDateTimeBarState();
}

class _ShellDateTimeBarState extends State<ShellDateTimeBar> {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: DateTimeChip(
          dateTime: _now,
          onTap: _openCalendar,
        ),
      ),
    );
  }
}
