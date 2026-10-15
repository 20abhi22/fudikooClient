import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/utils/connectivity_service.dart';
import 'package:fudikoclient/utils/error_messages.dart';

/// Retries a request that failed for network reasons, once the device is back
/// online.
///
/// Deliberately limited to GET. A POST that fails with a connection error may
/// still have reached the server, and this app's POST bodies are `FormData`,
/// which is a single-use stream and cannot be replayed anyway — so writes are
/// left for the user to trigger again.
class RetryOnReconnectInterceptor extends Interceptor {
  RetryOnReconnectInterceptor({
    this.maxAttempts = 2,
    this.waitForConnection = const Duration(seconds: 6),
    this.backoff = const Duration(milliseconds: 600),
  });

  /// Total attempts *after* the original request.
  final int maxAttempts;
  final Duration waitForConnection;
  final Duration backoff;

  static const String _attemptKey = 'retry_attempt';

  final ConnectivityService _connectivity = ConnectivityService();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (attempt >= maxAttempts) {
      handler.next(err);
      return;
    }

    // If the transport is down, hold briefly for it to come back rather than
    // burning the retry immediately.
    if (_connectivity.isOffline) {
      final restored = await _connectivity.waitForConnection(
        timeout: waitForConnection,
      );
      if (!restored) {
        handler.next(err);
        return;
      }
    } else {
      await Future<void>.delayed(backoff * (attempt + 1));
    }

    options.extra[_attemptKey] = attempt + 1;

    if (kDebugMode) {
      debugPrint(
        'Retrying ${options.method} ${options.path} '
        '(attempt ${attempt + 1}/$maxAttempts)',
      );
    }

    try {
      // Replay through the shared client so the retry keeps the auth header,
      // timeouts and certificate handling. The attempt counter on
      // `options.extra` is what stops this from looping.
      final response = await DioClient.dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    if (err.type == DioExceptionType.cancel) return false;
    return isNetworkError(err);
  }
}
