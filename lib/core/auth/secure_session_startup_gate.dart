import 'package:flutter/material.dart';

import '../config/app_env_bootstrap.dart';
import '../settings/app_settings_controller.dart';
import '../../app.dart';
import '../../features/system/secure_session_preparing_screen.dart';
import 'startup_session_purge.dart';

/// Ortam init + oturum purge bitene kadar login/router göstermez.
class SecureSessionStartupGate extends StatefulWidget {
  const SecureSessionStartupGate({super.key});

  @override
  State<SecureSessionStartupGate> createState() =>
      _SecureSessionStartupGateState();
}

class _SecureSessionStartupGateState extends State<SecureSessionStartupGate> {
  late final Future<void> _startupFuture = _prepare();

  Future<void> _prepare() async {
    await AppEnvBootstrap.ensureInitialized();
    await StartupSessionPurge.run();
    await appSettingsController.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SecureSessionPreparingScreen(),
          );
        }
        return const App();
      },
    );
  }
}
