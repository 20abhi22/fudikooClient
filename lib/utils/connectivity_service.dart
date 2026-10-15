import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// App-wide "is there a network?" signal.
///
/// This reports whether the device has a usable *transport* (wifi/mobile/etc).
/// It cannot tell us the API is reachable — a captive portal or a dead server
/// still looks "online" here — so it complements, rather than replaces, the
/// per-request error handling in `error_messages.dart`.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;
  bool _started = false;

  /// Last known state. Optimistic until [start] has produced a first reading,
  /// so nothing is blocked behind a connectivity check at launch.
  bool get isOnline => _online;
  bool get isOffline => !_online;

  /// Emits on every change of the online/offline state (not on every raw
  /// connectivity event).
  Stream<bool> get onStatusChange => _controller.stream;

  /// Emits once each time the device goes from offline back to online.
  Stream<void> get onRestored =>
      _controller.stream.where((online) => online).map((_) => null);

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      // Bounded so a wedged platform channel cannot hold up launch; the
      // subscription below corrects the state moments later either way.
      _online = _isOnline(
        await _connectivity.checkConnectivity().timeout(
          const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      _online = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _update(_isOnline(results)),
      onError: (_) {},
    );
  }

  /// Forces a fresh reading; useful right before a retry.
  Future<bool> refresh() async {
    try {
      _update(_isOnline(await _connectivity.checkConnectivity()));
    } catch (_) {}
    return _online;
  }

  /// Completes as soon as the device is online again, or after [timeout].
  /// Returns whether we came back online in time.
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_online) return true;
    try {
      await onStatusChange.firstWhere((online) => online).timeout(timeout);
      return true;
    } catch (_) {
      return _online;
    }
  }

  void _update(bool online) {
    if (_online == online) return;
    _online = online;
    if (kDebugMode) {
      debugPrint('Connectivity: ${online ? 'online' : 'offline'}');
    }
    if (!_controller.isClosed) _controller.add(online);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
