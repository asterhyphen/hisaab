import 'package:flutter/material.dart';

/// Icon options for tracker categories.
const trackerIcons = {
  'Bill': Icons.receipt_long,
  'Electricity': Icons.bolt,
  'Rent': Icons.home,
  'Music': Icons.music_note,
  'Movies': Icons.movie,
  'Internet': Icons.wifi,
  'Food': Icons.restaurant,
};

IconData iconDataFromId(String id) => trackerIcons[id] ?? Icons.receipt_long;

/// Auto-selects an icon based on keywords in the tracker title.
String autoIconIdFromText(String text) {
  final t = text.toLowerCase();
  if (RegExp(r'\b(electric|electricity|power|current|bill)\b').hasMatch(t)) {
    return 'Electricity';
  }
  if (RegExp(r'\b(rent|house|home|flat|room)\b').hasMatch(t)) {
    return 'Rent';
  }
  if (RegExp(r'\b(wifi|internet|broadband|fiber|network)\b').hasMatch(t)) {
    return 'Internet';
  }
  if (RegExp(r'\b(music|spotify|song|playlist)\b').hasMatch(t)) {
    return 'Music';
  }
  if (RegExp(r'\b(movie|film|cinema|netflix|prime)\b').hasMatch(t)) {
    return 'Movies';
  }
  if (RegExp(r'\b(food|lunch|dinner|meal|restaurant)\b').hasMatch(t)) {
    return 'Food';
  }
  return 'Bill';
}

/// Title-cases a name string.
String formatName(String input) {
  if (input.trim().isEmpty) return '';
  return input
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Returns the due date for the given month, clamped to the last day.
DateTime recurringDueDateForMonth(DateTime template, DateTime month) {
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
  final targetDay = template.day.clamp(1, lastDayOfMonth);
  return DateTime(month.year, month.month, targetDay);
}

/// Deduplicates, title-cases, and sorts a list of user names.
List<String> normalizeNames(Iterable<dynamic> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final formatted = formatName('$value');
    if (formatted.isEmpty) continue;
    if (seen.add(formatted.toLowerCase())) {
      result.add(formatted);
    }
  }
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

/// A named group of saved users.
class UserGroup {
  final String id;
  final String name;
  final List<String> members;

  const UserGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  UserGroup copyWith({String? id, String? name, List<String>? members}) {
    return UserGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'members': members};

  static UserGroup fromMap(Map map) => UserGroup(
    id: '${map['id']}',
    name: formatName('${map['name']}'),
    members: normalizeNames(List<String>.from(map['members'] ?? const [])),
  );
}

/// Domain model for a single recurring expense tracker.
class Tracker {
  final String id;
  final String title;
  final int? amount;
  final DateTime startDate;
  final DateTime dueDate;
  final List<String> users;
  final String iconId;
  final bool archived;

  Tracker({
    required this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.users,
    required this.iconId,
    required this.archived,
  });

  Tracker copyWith({
    String? title,
    int? amount,
    DateTime? dueDate,
    List<String>? users,
    String? iconId,
    bool? archived,
  }) {
    return Tracker(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      startDate: startDate,
      dueDate: dueDate ?? this.dueDate,
      users: users == null ? this.users : normalizeNames(users),
      iconId: iconId ?? this.iconId,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'users': users,
    'icon': iconId,
    'archived': archived,
  };

  static Tracker fromMap(Map map) {
    final iconRaw = map['icon'];
    final iconId =
        iconRaw is String
            ? iconRaw
            : (iconRaw is int
                ? trackerIcons.entries
                    .firstWhere(
                      (entry) => entry.value.codePoint == iconRaw,
                      orElse: () => const MapEntry('Bill', Icons.receipt_long),
                    )
                    .key
                : 'Bill');

    return Tracker(
      id: map['id'],
      title: formatName(map['title']),
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      dueDate: DateTime.parse(map['dueDate']),
      users: normalizeNames(List<String>.from(map['users'] ?? const [])),
      iconId: iconId,
      archived: map['archived'] == true,
    );
  }
}
