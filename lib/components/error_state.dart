import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';

/// Shared "we could not load this" placeholder with a Retry button, for the
/// screens that used to render an indistinguishable empty list when a request
/// failed.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isOffline = message.toLowerCase().contains('no internet');

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 16 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ??
                  (isOffline ? Icons.wifi_off_rounded : Icons.error_outline),
              size: compact ? 32 : 44,
              color: appTextColor2,
            ),
            SizedBox(height: compact ? 8 : 12),
            AppText(
              text: message,
              size: compact ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              isCentered: true,
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 10 : 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 18, color: appButtonColor),
                label: AppText(
                  text: 'Retry',
                  size: compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: appButtonColor,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: appButtonColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
