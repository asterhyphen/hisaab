import 'package:flutter/material.dart';

enum AppAlertTone { success, error, info }

void showAppAlert(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline,
  AppAlertTone tone = AppAlertTone.success,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final accentColor = switch (tone) {
    AppAlertTone.success => theme.colorScheme.primary,
    AppAlertTone.error => const Color(0xFFFF6B6B),
    AppAlertTone.info => const Color(0xFFFFB85C),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: isDark ? const Color(0xFF142033) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: tone == AppAlertTone.error
                ? accentColor.withValues(alpha: isDark ? 0.45 : 0.35)
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFD7E3EB),
          ),
        ),
        content: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
