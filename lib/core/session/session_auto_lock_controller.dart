import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_session.dart';
import '../settings/app_settings.dart';

final sessionAutoLockController = SessionAutoLockController();

/// Hareketsizlik süresi dolunca oturumu kilitler.
class SessionAutoLockController extends ChangeNotifier {
  Timer? _timer;
  bool _locked = false;
  Duration? _idleTimeout;
  DateTime _lastActivity = DateTime.now();
  bool _armed = false;

  bool get isLocked => _locked;

  void configure(AutoLockDurationKind kind) {
    _idleTimeout = kind.idleTimeout;
    if (_armed && !_locked) {
      _reschedule();
    }
  }

  void arm() {
    if (!AuthSession.isLoggedIn || AuthSession.isMaintenanceOperator) {
      disarm();
      return;
    }
    _armed = true;
    _locked = false;
    recordActivity();
  }

  void disarm() {
    _armed = false;
    _timer?.cancel();
    _timer = null;
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }

  void recordActivity() {
    if (!_armed || _locked) return;
    _lastActivity = DateTime.now();
    _reschedule();
  }

  void lock() {
    if (!_armed || _locked) return;
    _timer?.cancel();
    _locked = true;
    notifyListeners();
  }

  void onAppResumed() {
    final timeout = _idleTimeout;
    if (!_armed || timeout == null || _locked) return;
    if (DateTime.now().difference(_lastActivity) >= timeout) {
      lock();
    }
  }

  @visibleForTesting
  void lockForTest() => lock();

  void _reschedule() {
    _timer?.cancel();
    final timeout = _idleTimeout;
    if (!_armed || timeout == null) return;
    _timer = Timer(timeout, lock);
  }
}
