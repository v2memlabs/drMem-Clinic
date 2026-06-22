import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../core/session/auth_session_lifecycle.dart';
import '../../core/session/session_auto_lock_controller.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Kullanıcı etkileşimini izler ve otomatik kilit katmanını gösterir.
class SessionAutoLockHost extends StatefulWidget {
  final Widget child;

  const SessionAutoLockHost({super.key, required this.child});

  @override
  State<SessionAutoLockHost> createState() => _SessionAutoLockHostState();
}

class _SessionAutoLockHostState extends State<SessionAutoLockHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sessionAutoLockController.configure(
      appSettingsController.settings.autoLockDuration,
    );
    appSettingsController.addListener(_onSettingsChanged);
    sessionAutoLockController.addListener(_onLockChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appSettingsController.removeListener(_onSettingsChanged);
    sessionAutoLockController.removeListener(_onLockChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    sessionAutoLockController.configure(
      appSettingsController.settings.autoLockDuration,
    );
  }

  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sessionAutoLockController.onAppResumed();
      return;
    }
    if (state == AppLifecycleState.detached) {
      unawaited(AuthSessionLifecycle.signOutBestEffort());
    }
  }

  void _recordActivity() {
    sessionAutoLockController.recordActivity();
  }

  void _unlock(BuildContext context) {
    unawaited(AuthSessionLifecycle.signOut(context: context));
  }

  @override
  Widget build(BuildContext context) {
    final locked = sessionAutoLockController.isLocked;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (locked)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.72),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 40,
                              color: AppColors.navy,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Oturum kilitlendi',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Hareketsizlik nedeniyle oturum güvenliği için kilitlendi. Devam etmek için yeniden giriş yapın.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton(
                              onPressed: () => _unlock(context),
                              child: const Text('Yeniden giriş yap'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
