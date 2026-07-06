import 'package:flutter/material.dart';

class AppSettings {
  static const String defaultMessageTemplate = '''*_{title}_*
_Status:_ {status}
_Due:_ {dueDate} ({daysRemaining} days remaining)
_Total:_ ₹{total} (₹{perHead} each)

_Paid ({paidCount}; ₹{paidAmount})_
```
{paidUsers}
```

_Pending ({pendingCount}; ₹{pendingAmount})_
```
{pendingUsers}
```''';

  static const String defaultAllPaidMessageTemplate = '''*_{title}_*
_Status:_ {status}
_Due:_ {dueDate}
_Total:_ ₹{total} (₹{perHead} each)

All payments are complete. Bill paid.

_Paid ({paidCount}; ₹{paidAmount})_
```
{paidUsers}
```''';

  final String themeMode;
  final bool confirmDelete;
  final String messageTemplate;
  final String allPaidMessageTemplate;
  final bool notificationsEnabled;
  final int reminderDaysBefore;

  const AppSettings({
    required this.themeMode,
    required this.confirmDelete,
    required this.messageTemplate,
    required this.allPaidMessageTemplate,
    required this.notificationsEnabled,
    required this.reminderDaysBefore,
  });

  static const AppSettings defaults = AppSettings(
    themeMode: 'dark',
    confirmDelete: true,
    messageTemplate: defaultMessageTemplate,
    allPaidMessageTemplate: defaultAllPaidMessageTemplate,
    notificationsEnabled: false,
    reminderDaysBefore: 2,
  );

  factory AppSettings.fromMap(Map? map) {
    if (map == null) return defaults;
    return AppSettings(
      themeMode: _normalizeThemeMode(map['themeMode']),
      confirmDelete:
          map['confirmDelete'] is bool
              ? map['confirmDelete'] as bool
              : defaults.confirmDelete,
      messageTemplate: _normalizeMessageTemplate(map['messageTemplate']),
      allPaidMessageTemplate: _normalizeAllPaidMessageTemplate(
        map['allPaidMessageTemplate'],
      ),
      notificationsEnabled:
          map['notificationsEnabled'] is bool
              ? map['notificationsEnabled'] as bool
              : defaults.notificationsEnabled,
      reminderDaysBefore: _normalizeReminderDays(map['reminderDaysBefore']),
    );
  }

  AppSettings copyWith({
    String? themeMode,
    bool? confirmDelete,
    String? messageTemplate,
    String? allPaidMessageTemplate,
    bool? notificationsEnabled,
    int? reminderDaysBefore,
  }) {
    return AppSettings(
      themeMode: _normalizeThemeMode(themeMode ?? this.themeMode),
      confirmDelete: confirmDelete ?? this.confirmDelete,
      messageTemplate: _normalizeMessageTemplate(
        messageTemplate ?? this.messageTemplate,
      ),
      allPaidMessageTemplate: _normalizeAllPaidMessageTemplate(
        allPaidMessageTemplate ?? this.allPaidMessageTemplate,
      ),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderDaysBefore: _normalizeReminderDays(
        reminderDaysBefore ?? this.reminderDaysBefore,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'confirmDelete': confirmDelete,
      'messageTemplate': messageTemplate,
      'allPaidMessageTemplate': allPaidMessageTemplate,
      'notificationsEnabled': notificationsEnabled,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static String _normalizeThemeMode(Object? value) {
    final mode = (value ?? '').toString().toLowerCase();
    if (mode == 'light' || mode == 'dark') return mode;
    return defaults.themeMode;
  }

  static String _normalizeMessageTemplate(Object? value) {
    final template = (value ?? '').toString().trim();
    if (template.isEmpty) return defaultMessageTemplate;
    return template;
  }

  static String _normalizeAllPaidMessageTemplate(Object? value) {
    final template = (value ?? '').toString().trim();
    if (template.isEmpty) return defaultAllPaidMessageTemplate;
    return template;
  }

  static int _normalizeReminderDays(Object? value) {
    final days = value is int ? value : int.tryParse('${value ?? ''}');
    if (days == null) return defaults.reminderDaysBefore;
    return days.clamp(1, 7);
  }
}
