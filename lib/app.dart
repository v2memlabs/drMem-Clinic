import 'package:flutter/material.dart';
import 'core/auth/auth_callback_coordinator.dart';
import 'core/constants/app_branding.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/widgets/session_auto_lock_host.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthCallbackCoordinator.start(AppRouter.router);
    });
  }

  @override
  void dispose() {
    AuthCallbackCoordinator.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettingsController,
      builder: (context, _) {
        final settings = appSettingsController.settings;
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppBranding.productName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode.flutterThemeMode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: settings.timeFormat.use24Hour,
              ),
              child: SessionAutoLockHost(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
