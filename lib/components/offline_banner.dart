import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/connectivity_service.dart';

/// Wraps the whole app and slides a thin bar in from the bottom whenever the
/// device loses its network, so an empty list or a stalled screen always has a
/// visible explanation.
///
/// Installed once via `MaterialApp.builder`; individual screens do nothing.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _subscription;

  bool _offline = false;
  // Kept visible for a moment after reconnecting so the "Back online" state is
  // actually readable rather than flashing past.
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    _offline = _connectivity.isOffline;
    _subscription = _connectivity.onStatusChange.listen(_handleChange);
  }

  void _handleChange(bool online) {
    if (!mounted) return;
    _restoredTimer?.cancel();

    setState(() {
      _offline = !online;
      _showRestored = online;
    });

    if (online) {
      _restoredTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showRestored = false);
      });
    }
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool visible = _offline || _showRestored;
    final bool isRestored = !_offline && _showRestored;

    return Stack(
      // Tight constraints for the app itself; the bar is positioned over it.
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _BannerBar(isRestored: isRestored),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerBar extends StatelessWidget {
  const _BannerBar({required this.isRestored});

  final bool isRestored;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
        color: isRestored ? const Color(0xFF1E9E4A) : const Color(0xFF3A3A38),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRestored ? Icons.wifi : Icons.wifi_off_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AppText(
                text: isRestored ? 'Back online' : 'No internet connection',
                size: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                isCentered: true,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
