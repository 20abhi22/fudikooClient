import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fudikoclient/model/notification/notification_badges_model.dart';
import 'package:fudikoclient/service/notification/notification_badges_service.dart';

/// Owns the notification badge counts and the single timer that polls for them.
///
/// The restaurant, banquet and catering bottom bars all read the same endpoint,
/// so polling lives here instead of in each nav: whichever bars are mounted,
/// there is one request every [_pollInterval]. Widgets [subscribe] while they
/// need counts and read [badges]; only the first subscriber starts the timer
/// and only the last one stops it.
///
/// The timer also stops while the app is backgrounded and refetches on resume,
/// so a backgrounded app is not making a request every 15 seconds.
class BadgeController extends ChangeNotifier with WidgetsBindingObserver {
  BadgeController._private();

  static final BadgeController instance = BadgeController._private();

  static const Duration _pollInterval = Duration(seconds: 15);

  final NotificationBadgesService _service = NotificationBadgesService();

  Timer? _timer;
  int _subscribers = 0;
  bool _isFetching = false;
  bool _refetchWhenIdle = false;
  NotificationBadgesModel _badges = const NotificationBadgesModel();
  bool _hasFetchedOnce = false;

  /// Latest counts. All zeros until the first successful fetch.
  NotificationBadgesModel get badges => _badges;

  /// False until a fetch has landed. Lets a listener tell "no badges yet" apart
  /// from "genuinely zero", so it does not read the first counts as a change.
  bool get hasFetchedOnce => _hasFetchedOnce;

  /// Registers interest in the counts. Pair every call with [unsubscribe].
  void subscribe() {
    _subscribers++;
    if (_subscribers == 1) {
      WidgetsBinding.instance.addObserver(this);
      _startPolling();
    }
    // Newly mounted widget: get it current counts without waiting a full tick.
    refresh();
  }

  void unsubscribe() {
    if (_subscribers == 0) return;
    _subscribers--;
    if (_subscribers == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _stopPolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_subscribers == 0) return;

    if (state == AppLifecycleState.resumed) {
      _startPolling();
      refresh();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _timer ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fetches the counts now and notifies listeners. Call this after an action
  /// that changes them instead of waiting for the next tick.
  ///
  /// A call made while a fetch is already running is not dropped: it runs once
  /// that one finishes, because the in-flight request may have been sent before
  /// the action that prompted this call.
  Future<void> refresh() async {
    if (_isFetching) {
      _refetchWhenIdle = true;
      return;
    }

    _isFetching = true;
    try {
      final data = await _service.fetchBadges();
      _badges = data;
      _hasFetchedOnce = true;
      notifyListeners();
    } catch (_) {
      // Offline or a failed request: keep the counts we already have rather
      // than zeroing them, which listeners would read as "the badge cleared".
    } finally {
      _isFetching = false;
    }

    if (_refetchWhenIdle) {
      _refetchWhenIdle = false;
      await refresh();
    }
  }
}
