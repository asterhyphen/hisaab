import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_alert.dart';
import '../../trackers/application/trackers_provider.dart';
import '../application/app_settings_provider.dart';
import '../domain/app_settings.dart';
import 'message_template_editor_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _save(AppSettings value) async {
    await ref.read(appSettingsProvider.notifier).save(value);
  }

  Future<void> _editMessageTemplate() async {
    final settings = ref.read(appSettingsProvider);
    final updatedTemplates = await Navigator.push<MessageTemplateEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MessageTemplateEditorPage(
          initialTemplate: settings.messageTemplate,
          initialAllPaidTemplate: settings.allPaidMessageTemplate,
        ),
      ),
    );

    if (!mounted) return;
    if (updatedTemplates == null) return;
    if (updatedTemplates.messageTemplate.trim().isEmpty ||
        updatedTemplates.allPaidMessageTemplate.trim().isEmpty) {
      showAppAlert(
        context,
        message: 'Both message templates need some text.',
        icon: Icons.info_outline,
        tone: AppAlertTone.info,
      );
      return;
    }
    await _save(
      settings.copyWith(
        messageTemplate: updatedTemplates.messageTemplate,
        allPaidMessageTemplate: updatedTemplates.allPaidMessageTemplate,
      ),
    );
    if (!mounted) return;
    showAppAlert(context, message: 'Message templates updated.');
  }

  Future<void> _clearMonthlyData() async {
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear monthly records?'),
            content: const Text(
              'This removes paid and pending records for all months, but keeps your trackkars.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear) return;

    await ref.read(monthlyRecordsProvider.notifier).clearAll();

    if (!mounted) return;
    showAppAlert(context, message: 'Monthly records cleared.');
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    final settings = ref.read(appSettingsProvider);

    if (!enabled) {
      await _save(settings.copyWith(notificationsEnabled: false));
      if (!mounted) return;
      showAppAlert(context, message: 'Due reminders turned off.');
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;

    if (!granted) {
      showAppAlert(
        context,
        message:
            'Notification permission was denied. Enable it from system settings to use due reminders.',
        icon: Icons.notifications_off_outlined,
        tone: AppAlertTone.error,
      );
      return;
    }

    await _save(settings.copyWith(notificationsEnabled: true));
    if (!mounted) return;
    showAppAlert(
      context,
      message:
          'Due reminders turned on ${settings.reminderDaysBefore} day${settings.reminderDaysBefore == 1 ? '' : 's'} before due date.',
      icon: Icons.notifications_active_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF10192B), Color(0xFF090F1B)]
              : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [Colors.white, const Color(0xFFF1F7FB)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFD9E6EF),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.24)
                      : const Color(0xFF8FA8BA).withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: isDark
                            ? const Color(0xFF77FFD8)
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Preferences',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalize the look and experience of the app.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.66,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
            title: 'Appearance',
            icon: Icons.palette_outlined,
            headerTrailing: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'light', label: Text('Light')),
                  ButtonSegment(value: 'dark', label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                multiSelectionEnabled: false,
                showSelectedIcon: false,
                onSelectionChanged: (selected) async {
                  await _save(settings.copyWith(themeMode: selected.first));
                },
              ),
            ),
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
            title: 'Behavior',
            icon: Icons.touch_app_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.confirmDelete,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirm before deleting tracker'),
                  onChanged: (value) async {
                    await _save(settings.copyWith(confirmDelete: value));
                    if (!context.mounted) return;
                    showAppAlert(
                      context,
                      message: value
                          ? 'Delete confirmation enabled.'
                          : 'Delete confirmation disabled.',
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Edit message template'),
                  subtitle: const Text(
                    'Customise pending and all-paid share messages.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editMessageTemplate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
            title: 'Notifications',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.notificationsEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable due reminders'),
                  subtitle: const Text(
                    'Notification permission is required for this feature to work.',
                  ),
                  onChanged: _setNotificationsEnabled,
                ),
                _animatedReveal(
                  visible: settings.notificationsEnabled,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Send reminder ${settings.reminderDaysBefore} day${settings.reminderDaysBefore == 1 ? '' : 's'} before due date',
                        ),
                        subtitle: const Text(
                          'Customise when to send reminders.',
                        ),
                      ),
                      Slider(
                        min: 1,
                        max: 7,
                        divisions: 6,
                        value: settings.reminderDaysBefore.toDouble(),
                        onChanged: (value) async {
                          await _save(
                            settings.copyWith(
                              reminderDaysBefore: value.round(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
            title: 'Data',
            icon: Icons.storage_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear monthly records'),
              subtitle: const Text('Trackkars remain unchanged'),
              trailing: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
              onTap: _clearMonthlyData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedReveal({required bool visible, required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
        );
      },
      child: visible
          ? KeyedSubtree(
              key: const ValueKey('notification-options'),
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey('notification-options-hidden')),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    required IconData icon,
    Widget? headerTrailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.065)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFD9E6EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF77FFD8)
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 12),
                Flexible(child: headerTrailing),
              ],
            ],
          ),
          if (child is! SizedBox) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}
