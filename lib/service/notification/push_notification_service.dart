import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fudikoclient/screens/tabs/reservation/verifiedModal.dart';

/// Attached to the MaterialApp so dialogs can be shown without a BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Attached to the MaterialApp so a push that arrives while the app is open
/// can be shown from anywhere, without a BuildContext.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Runs in its own isolate when a push arrives with the app in the
/// background or terminated, so it must be top-level and bring up Firebase
/// itself. Messages that carry a `notification` payload are already drawn by
/// the OS; this exists so data-only messages don't throw.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logPush('BACKGROUND', message);
}

void _logPush(String source, RemoteMessage message) {
  debugPrint(
    '[PUSH][$source] id=${message.messageId}\n'
    '  title=${message.notification?.title}\n'
    '  body=${message.notification?.body}\n'
    '  data=${message.data}',
  );
}

class PushNotificationService {
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Call once from main() after Firebase.initializeApp(). The OS does not
  /// draw a notification while the app is in the foreground, so those are
  /// shown as a snackbar instead.
  static void init() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSub?.cancel();
    FirebaseMessaging.instance.getToken().then(
      (token) => debugPrint('[PUSH] FCM token: $token'),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _logPush('OPENED', message),
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      _logPush('FOREGROUND', message);
      final notification = message.notification;
      final title = notification?.title;
      final body = notification?.body;
      if (title == null && body == null) return;

      if (_isOfferCodeVerified(message, title, body) &&
          _showVerifiedDialog(message)) {
        return;
      }

      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (body != null) Text(body),
              ],
            ),
          ),
        );
    });
  }

  static bool _isOfferCodeVerified(
    RemoteMessage message,
    String? title,
    String? body,
  ) {
    final type = message.data['type']?.toString().toLowerCase() ?? '';
    if (type.contains('verified') || type.contains('complete')) return true;
    // Fallback on the text so reservation, catering and banquet completions
    // still get the popup if their `type` key is named differently.
    final text = '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return text.contains('completed') ||
        (text.contains('offer code') && text.contains('verified'));
  }

  /// Returns false when no navigator is available so the caller can fall
  /// back to the snackbar.
  static bool _showVerifiedDialog(RemoteMessage message) {
    // The navigator's own context sits above its Navigator, so use the overlay's.
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null) return false;

    final points = message.data['points']?.toString();
    messengerKey.currentState?.hideCurrentSnackBar();
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: VerifiedModal(points: points),
      ),
    );
    return true;
  }
}
