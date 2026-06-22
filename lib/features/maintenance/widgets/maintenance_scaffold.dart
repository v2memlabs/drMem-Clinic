import 'package:flutter/material.dart';

import 'maintenance_shell.dart';

/// Bakım ekranı sarmalayıcı — [MaintenanceShell] üzerinden sunulur.
class MaintenanceScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const MaintenanceScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return MaintenanceShell(
      title: title,
      actions: actions,
      child: child,
    );
  }
}
