import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../trackers/model/tracker.dart';

// ---------------------------------------------------------------------------
// Saved users
// ---------------------------------------------------------------------------

final savedUsersProvider = NotifierProvider<SavedUsersNotifier, List<String>>(
  SavedUsersNotifier.new,
);

class SavedUsersNotifier extends Notifier<List<String>> {
  late final Box<dynamic> _box;

  @override
  List<String> build() {
    _box = Hive.box(HiveBoxes.trackers);
    return _readUsers();
  }

  Future<void> saveAll(List<String> users) async {
    await _box.put('savedUsers', normalizeNames(users));
    state = _readUsers();
  }

  Future<void> add(String user) async {
    await saveAll([...state, user]);
  }

  Future<void> delete(String user) async {
    await saveAll(state.where((value) => value != user).toList());
    ref.read(userGroupsProvider.notifier).removeMember(user);
  }

  List<String> _readUsers() {
    final raw = _box.get('savedUsers', defaultValue: <String>[]) as List;
    return normalizeNames(raw);
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
