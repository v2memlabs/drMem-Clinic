import 'package:flutter/material.dart';

import '../../../core/router/maintenance_route_guard.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../data/maintenance_repository.dart';

/// maintenance_ping başarılı olana kadar içerik göstermez.
class MaintenanceGate extends StatefulWidget {
  final Widget child;

  const MaintenanceGate({super.key, required this.child});

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  late Future<bool> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = _check();
  }

  Future<bool> _check() {
    if (!MaintenanceRouteGuard.canAttemptAccess) {
      return Future.value(false);
    }
    return MaintenanceRouteGuard.verifyOperatorAccess(
      MaintenanceRepository.fromSupabase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (!MaintenanceRouteGuard.routesShouldRegister) {
          return ClinicalStateMessage.empty(
            icon: Icons.lock_outline,
            title: 'Bakım konsolu kapalı',
            description: 'Bu ortamda bakım modu etkin değil.',
          );
        }
        if (!MaintenanceRouteGuard.canAttemptAccess) {
          return ClinicalStateMessage.empty(
            icon: Icons.lock_outline,
            title: 'Oturum gerekli',
            description: 'Bakım konsoluna erişmek için giriş yapın.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ClinicalStateMessage.loading(
            message: 'Bakım yetkisi doğrulanıyor…',
          );
        }
        if (snapshot.data != true) {
          return ClinicalStateMessage.empty(
            icon: Icons.block,
            title: 'Erişim reddedildi',
            description:
                'Bakım operatörü yetkisi veya sunucu bakım modu gerekli.',
          );
        }
        return widget.child;
      },
    );
  }
}
