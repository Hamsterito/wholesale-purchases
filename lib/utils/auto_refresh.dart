import 'dart:async';
import 'package:flutter/widgets.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;
  bool _autoRefreshActive = false;
  bool _isObserverAttached = false;
  late final _AutoRefreshObserver _observer =
      _AutoRefreshObserver(_handleLifecycleState);

  @protected
  Duration get autoRefreshInterval => const Duration(seconds: 20);

  @protected
  bool get refreshOnlyWhenVisible => true;

  @protected
  Future<void> onAutoRefresh();

  @protected
  void startAutoRefresh() {
    if (_autoRefreshActive) return;
    _autoRefreshActive = true;
    _attachObserver();
    _scheduleTimer();
  }

  @protected
  void stopAutoRefresh() {
    _autoRefreshActive = false;
    _cancelTimer();
    _detachObserver();
  }

  void _handleLifecycleState(AppLifecycleState state) {
    if (!_autoRefreshActive) return;
    if (state == AppLifecycleState.resumed) {
      _scheduleTimer();
      // ignore: unawaited_futures
      _tick();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cancelTimer();
    }
  }

  void _scheduleTimer() {
    if (!_autoRefreshActive) return;
    if (autoRefreshInterval <= Duration.zero) {
      _cancelTimer();
      return;
    }
    _cancelTimer();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) => _tick());
  }

  void _cancelTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _attachObserver() {
    if (_isObserverAttached) return;
    WidgetsBinding.instance.addObserver(_observer);
    _isObserverAttached = true;
  }

  void _detachObserver() {
    if (!_isObserverAttached) return;
    WidgetsBinding.instance.removeObserver(_observer);
    _isObserverAttached = false;
  }

  bool _isVisible() {
    if (!refreshOnlyWhenVisible) return true;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return false;
    }
    return TickerMode.of(context);
  }

  Future<void> _tick() async {
    if (!_autoRefreshActive || !mounted || _isRefreshing) return;
    if (!_isVisible()) return;
    _isRefreshing = true;
    try {
      await onAutoRefresh();
    } finally {
      _isRefreshing = false;
    }
  }
}

class _AutoRefreshObserver with WidgetsBindingObserver {
  _AutoRefreshObserver(this._onLifecycleState);

  final void Function(AppLifecycleState state) _onLifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onLifecycleState(state);
  }
}
