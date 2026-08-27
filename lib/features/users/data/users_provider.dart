import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../trackers/model/tracker.dart';

// ---------------------------------------------------------------------------
// Saved users  (reads from the ledger friends box so both systems share one
// source of truth – user names are the keys in HiveBoxes.friends)
// ---------------------------------------------------------------------------

final savedUsersProvider = NotifierProvider<SavedUsersNotifier, List<String>>(
  SavedUsersNotifier.new,
);

class SavedUsersNotifier extends Notifier<List<String>> {
  late final Box<dynamic> _box;

  @override
  List<String> build() {
    // The ledger stores each person's name as a key in the friends box.
    _box = Hive.box(HiveBoxes.friends);
    return _readUsers();
  }

  /// Adds a new person to the ledger friends box (creates an empty entry if
  /// they don't already exist).
  Future<void> add(String user) async {
    final formatted = formatName(user);
    if (formatted.isEmpty || _box.containsKey(formatted)) return;
    await _box.put(formatted, []);
    state = _readUsers();
  }

  /// Removes a person from the ledger friends box and also strips them from
  /// any tracker groups.
  Future<void> delete(String user) async {
    await _box.delete(user);
    state = _readUsers();
    ref.read(userGroupsProvider.notifier).removeMember(user);
  }

  List<String> _readUsers() {
    // Friends are stored as box keys (strings).
    final names = _box.keys.cast<String>().toList();
    return normalizeNames(names);
  }
}


// ---------------------------------------------------------------------------
// User groups
// ---------------------------------------------------------------------------

final userGroupsProvider =
    NotifierProvider<UserGroupsNotifier, List<UserGroup>>(
      UserGroupsNotifier.new,
    );

class UserGroupsNotifier extends Notifier<List<UserGroup>> {
  late final Box<dynamic> _box;

  @override
  List<UserGroup> build() {
    _box = Hive.box(HiveBoxes.trackers);
    return _readGroups();
  }

  Future<void> save(UserGroup group) async {
    final groupsMap = _readGroupMap();
    groupsMap[group.id] = group.toMap();
    await _box.put('userGroups', groupsMap);
    state = _readGroups();
  }

  Future<void> delete(String groupId) async {
    final groupsMap = _readGroupMap();
    groupsMap.remove(groupId);
    await _box.put('userGroups', groupsMap);
    state = _readGroups();
  }

  Future<void> removeMember(String user) async {
    final groupsMap = _readGroupMap();
    final updatedGroups = <String, dynamic>{};
    for (final entry in groupsMap.entries) {
      final group = UserGroup.fromMap(entry.value);
      final remainingMembers =
          group.members.where((member) => member != user).toList();
      if (remainingMembers.isEmpty) continue;
      updatedGroups[entry.key] =
          group.copyWith(members: normalizeNames(remainingMembers)).toMap();
    }
    await _box.put('userGroups', updatedGroups);
    state = _readGroups();
  }

  Map<String, dynamic> _readGroupMap() {
    return Map<String, dynamic>.from(
      _box.get('userGroups', defaultValue: <String, dynamic>{}) as Map,
    );
  }

  List<UserGroup> _readGroups() {
    final raw = _readGroupMap();
    return raw.values.map((value) => UserGroup.fromMap(value)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
