import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassAlertType { success, error, info }

class GlassAlert extends StatefulWidget {
  final String message;
  final GlassAlertType type;
  final Duration duration;
  final VoidCallback? onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GlassAlert({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  static void show(
    BuildContext context, {
    required String message,
    required GlassAlertType type,
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return GlassAlert(
          message: message,
          type: type,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismissed: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: GlassAlertType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      message: message,
      type: GlassAlertType.error,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: GlassAlertType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  State<GlassAlert> createState() => _GlassAlertState();
}

class _GlassAlertState extends State<GlassAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yTranslation;
  late Animation<double> _opacity;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _yTranslation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.of(context).padding;
    final isDark = theme.brightness == Brightness.dark;

    Color glassBg;
    Color borderCol;
    Color iconCol;
    IconData icon;

    switch (widget.type) {
      case GlassAlertType.success:
        glassBg = Colors.green.withValues(alpha: 0.12);
        borderCol = Colors.green.withValues(alpha: 0.35);
        iconCol = isDark ? Colors.greenAccent : Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case GlassAlertType.error:
        glassBg = theme.colorScheme.error.withValues(alpha: 0.12);
        borderCol = theme.colorScheme.error.withValues(alpha: 0.35);
        iconCol = theme.colorScheme.error;
        icon = Icons.error_outline;
        break;
      case GlassAlertType.info:
        glassBg = theme.colorScheme.primary.withValues(alpha: 0.12);
        borderCol = theme.colorScheme.primary.withValues(alpha: 0.35);
        iconCol = theme.colorScheme.primary;
        icon = Icons.info_outline;
        break;
    }

    final baseBgColor =
        isDark
            ? Colors.black.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.75);

    final textColor = isDark ? Colors.white : Colors.black87;

    return Positioned(
      bottom: padding.bottom + 25,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -4) {
              _dismiss();
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _yTranslation.value),
                child: Opacity(opacity: _opacity.value, child: child),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(glassBg, baseBgColor),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: iconCol, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            _dismiss();
                            widget.onAction!();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: iconCol.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              color: iconCol,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
