import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../model/tracker.dart';
import '../model/tracker_settings.dart';

// ---------------------------------------------------------------------------
// Box provider
// ---------------------------------------------------------------------------

final trackerBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxes.trackers);
});

// ---------------------------------------------------------------------------
// Settings provider
// ---------------------------------------------------------------------------

final trackerSettingsProvider =
    NotifierProvider<TrackerSettingsNotifier, TrackerSettings>(
      TrackerSettingsNotifier.new,
    );

class TrackerSettingsNotifier extends Notifier<TrackerSettings> {
  late final Box<dynamic> _box;

  @override
  TrackerSettings build() {
    _box = ref.watch(trackerBoxProvider);
    return TrackerSettings.fromMap(_box.get('settings'));
  }

  Future<void> save(TrackerSettings value) async {
    state = value;
    await _box.put('settings', value.toMap());
    await NotificationService.instance.syncForAllTrackers(_box);
  }
}

// ---------------------------------------------------------------------------
// Trackers providers
// ---------------------------------------------------------------------------

final trackersProvider = NotifierProvider<TrackersNotifier, List<Tracker>>(
  TrackersNotifier.new,
);

final activeTrackersProvider = Provider<List<Tracker>>((ref) {
  return ref
      .watch(trackersProvider)
      .where((tracker) => !tracker.archived)
      .toList();
});

final archivedTrackersProvider = Provider<List<Tracker>>((ref) {
  return ref
      .watch(trackersProvider)
      .where((tracker) => tracker.archived)
      .toList();
});

final currentMonthKeyProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month}';
});

class TrackersNotifier extends Notifier<List<Tracker>> {
  late final Box<dynamic> _box;

  @override
  List<Tracker> build() {
    _box = ref.watch(trackerBoxProvider);
    return _readTrackers();
  }

  Future<void> create(Tracker tracker) async {
    final all = Map<String, dynamic>.from(
      _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map,
    );
    all[tracker.id] = tracker.toMap();
    await _box.put('trackkars', all);
    state = _readTrackers();
    await NotificationService.instance.syncForAllTrackers(_box);
  }

  Future<void> save(Tracker tracker) async {
    final all = Map<String, dynamic>.from(
      _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map,
    );
    all[tracker.id] = tracker.toMap();
    await _box.put('trackkars', all);
    state = _readTrackers();
    await NotificationService.instance.syncForAllTrackers(_box);
  }

  Future<void> addUsersToTrackers(
    Iterable<String> trackerIds,
    Iterable<String> users,
  ) async {
    final ids = trackerIds.toSet();
    final newUsers = normalizeNames(users);
    if (ids.isEmpty || newUsers.isEmpty) return;

    final all = Map<String, dynamic>.from(
      _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map,
    );

    for (final id in ids) {
      final raw = all[id];
      if (raw is! Map) continue;
      final tracker = Tracker.fromMap(raw);
      all[id] = tracker
          .copyWith(users: [...tracker.users, ...newUsers])
          .toMap();
    }

    await _box.put('trackkars', all);
    state = _readTrackers();
    await NotificationService.instance.syncForAllTrackers(_box);
  }

  Future<Tracker?> delete(String trackerId) async {
    final all = Map<String, dynamic>.from(
      _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map,
    );
    final deleted =
        all[trackerId] == null ? null : Tracker.fromMap(all[trackerId]);
    all.remove(trackerId);
    await _box.put('trackkars', all);
    state = _readTrackers();
    await NotificationService.instance.syncForAllTrackers(_box);
    return deleted;
  }

  Tracker? byId(String trackerId) {
    for (final tracker in state) {
      if (tracker.id == trackerId) return tracker;
    }
    return null;
  }

  List<Tracker> _readTrackers() {
    final raw =
        _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map;
    return raw.values.map((value) => Tracker.fromMap(value)).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
}

// ---------------------------------------------------------------------------
// Monthly records provider
// ---------------------------------------------------------------------------

final monthlyRecordsProvider =
    NotifierProvider<MonthlyRecordsNotifier, Map<String, Map<String, dynamic>>>(
      MonthlyRecordsNotifier.new,
    );

class MonthlyRecordsNotifier
    extends Notifier<Map<String, Map<String, dynamic>>> {
  late final Box<dynamic> _box;

  @override
  Map<String, Map<String, dynamic>> build() {
    _box = ref.watch(trackerBoxProvider);
    return _readRecords();
  }

  Map<String, dynamic>? recordFor(String trackerId, String monthKey) {
    return state['${trackerId}_$monthKey'];
  }

  Future<void> save({
    required String trackerId,
    required String monthKey,
    required Map<String, bool> paid,
    required int total,
  }) async {
    await _box.put('${trackerId}_$monthKey', {'paid': paid, 'total': total});
    state = _readRecords();
  }

  Future<void> clearAll() async {
    final trackkars = Map<String, dynamic>.from(
      _box.get('trackkars', defaultValue: <String, dynamic>{}) as Map,
    );
    final trackerIds = trackkars.keys.toSet();

    for (final key in _box.keys.toList()) {
      if (key is! String || key == 'trackkars' || key == 'settings') continue;
      final idPart = key.split('_').first;
      if (trackerIds.contains(idPart)) {
        await _box.delete(key);
      }
    }

    state = _readRecords();
  }

  Map<String, Map<String, dynamic>> _readRecords() {
    final records = <String, Map<String, dynamic>>{};
    for (final key in _box.keys) {
      if (key is! String || !key.contains('_')) continue;
      final value = _box.get(key);
      if (value is Map &&
          value.containsKey('paid') &&
          value.containsKey('total')) {
        records[key] = Map<String, dynamic>.from(value);
      }
    }
    return records;
  }
}
