import 'package:flutter/material.dart';

/// A glassmorphism-style card used across the Trackers feature.
class TrackerGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TrackerGlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.03),
                  ]
                  : [Colors.white, const Color(0xFFF1F6FA)],
        ),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFFD9E6EF),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF8FA8BA).withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}
