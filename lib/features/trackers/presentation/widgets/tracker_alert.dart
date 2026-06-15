import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_alert.dart';

enum TrackerAlertTone { success, error, info }

/// Shows a floating GlassAlert using Hisaab's native GlassAlert component
/// for consistent styling across the app.
void showTrackerAlert(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline,
  TrackerAlertTone tone = TrackerAlertTone.success,
}) {
  switch (tone) {
    case TrackerAlertTone.success:
      GlassAlert.showSuccess(context, message);
    case TrackerAlertTone.error:
      GlassAlert.showError(context, message);
    case TrackerAlertTone.info:
      GlassAlert.showInfo(context, message);
  }
}
