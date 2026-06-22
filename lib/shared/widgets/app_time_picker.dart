import 'package:flutter/material.dart';

import '../../core/settings/app_settings_controller.dart';

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  final use24Hour = appSettingsController.settings.timeFormat.use24Hour;
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}
