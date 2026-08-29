import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hisaab_typography.dart';
import '../../../trackers/data/trackers_providers.dart';
import '../../../trackers/model/tracker.dart';
import '../../../users/data/users_provider.dart';
import '../../../trackers/presentation/widgets/glass_card.dart';
import '../../../trackers/presentation/widgets/tracker_alert.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;
    final users = ref.watch(savedUsersProvider);
    final groups = ref.watch(userGroupsProvider);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
          children: [
            TrackerGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.people_alt_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Users & Groups',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFamily: fontFamily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Users from the Home tab appear here. Combine them into groups for one-tap trackkar setup.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.68,
                                ),
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _summaryTile(
                        context,
                        label: 'Users',
                        value: '${users.length}',
                      ),
                      const SizedBox(width: 12),
                      _summaryTile(
                        context,
                        label: 'Groups',
                        value: '${groups.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Users',
              child:
                  users.isEmpty
                      ? _emptyBody(
                        context,
                        'No users yet. Add people from the Home tab using the + button — they will appear here automatically.',
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                users.map((user) {
                                  return SizedBox(
                                    width: 115,
                                    child: Chip(
                                      label: Text(
                                        user,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(fontFamily: fontFamily),
                                      ),
                                      labelPadding: const EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Manage users from the Home tab.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              title: 'Groups',
              actionLabel: users.isEmpty ? null : 'Create Group',
              onAction: users.isEmpty ? null : () => _showGroupSheet(),
              child:
                  groups.isEmpty
                      ? _emptyBody(
                        context,
                        users.isEmpty
                            ? 'Add users first, then combine them into reusable groups.'
                            : 'No groups have been created yet. Create groups from existing users for one-tap trackkar setup.',
                      )
                      : Column(
                        children:
                            groups.map((group) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.05,
                                            )
                                            : Colors.white.withValues(
                                              alpha: 0.76,
                                            ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                              : const Color(0xFFD9E6EF),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(
                                            alpha: isDark ? 0.18 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.group_work_outlined,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              group.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withValues(
                                                          alpha: 0.68,
                                                        ),
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  group.members
                                                      .map(
                                                        (member) => _miniTag(
                                                          context,
                                                          member,
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? Colors.white.withValues(
                                                      alpha: 0.06,
                                                    )
                                                    : const Color(0xFFF1F6FA),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isDark
                                                      ? Colors.white.withValues(
                                                        alpha: 0.08,
                                                      )
                                                      : const Color(0xFFD9E6EF),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.more_horiz,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.76),
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        color:
                                            isDark
                                                ? const Color(0xFF142033)
                                                : Colors.white,
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteGroup(group.id, group.name);
                                          } else if (value == 'edit') {
                                            _showGroupSheet(group: group);
                                          }
                                        },
                                        itemBuilder:
                                            (context) => const [
                                              PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Text('Edit Group'),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text('Delete Group'),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
            ),
            const SizedBox(height: 24),
          ],
        ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final fontFamily = context.hisaabFontFamily;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: fontFamily),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final fontFamily = context.hisaabFontFamily;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionLabel, style: TextStyle(fontFamily: fontFamily)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _emptyBody(BuildContext context, String text) {
    final fontFamily = context.hisaabFontFamily;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
        fontFamily: fontFamily,
      ),
    );
  }

  Widget _miniTag(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF0F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontFamily: fontFamily),
      ),
    );
  }


  Future<void> _showGroupSheet({UserGroup? group}) async {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final savedUsers = ref.read(savedUsersProvider);
    final selectedUsers =
        group == null ? <String>{} : Set<String>.from(group.members);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group == null ? 'Create Group' : 'Edit Group',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Group name',
                          prefixIcon: Icon(Icons.group_add_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Choose users',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            savedUsers.map((user) {
                              final selected = selectedUsers.contains(user);
                              return FilterChip(
                                label: Text(user),
                                selected: selected,
                                onSelected: (value) {
                                  setModalState(() {
                                    if (value) {
                                      selectedUsers.add(user);
                                    } else {
                                      selectedUsers.remove(user);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              () => _saveGroupFromSheet(
                                groupId: group?.id,
                                groupName: nameCtrl.text,
                                members: selectedUsers.toList(),
                              ),
                          child: Text(
                            group == null ? 'Create Group' : 'Save Changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _saveGroupFromSheet({
    String? groupId,
    required String groupName,
    required List<String> members,
  }) async {
    final name = formatName(groupName);
    final normalizedMembers = normalizeNames(members);
    final groups = ref.read(userGroupsProvider);

    if (name.isEmpty) {
      showTrackerAlert(
        context,
        message: 'Group name field is empty.',
        tone: TrackerAlertTone.info,
        icon: Icons.info_outline,
      );
      return;
    }

    if (normalizedMembers.isEmpty) {
      showTrackerAlert(
        context,
        message: 'Cannot create an empty group. Select at least one user.',
        tone: TrackerAlertTone.info,
        icon: Icons.info_outline,
      );
      return;
    }

    final alreadyExists = groups.any(
      (group) =>
          group.name.toLowerCase() == name.toLowerCase() && group.id != groupId,
    );

    if (alreadyExists) {
      showTrackerAlert(
        context,
        message: '$name already exists as a group. Try using a different name.',
        tone: TrackerAlertTone.info,
        icon: Icons.info_outline,
      );
      return;
    }

    final id = groupId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final group = UserGroup(id: id, name: name, members: normalizedMembers);
    final previousGroup =
        groupId == null
            ? null
            : groups.where((g) => g.id == groupId).firstOrNull;
    final addedMembers =
        previousGroup == null
            ? const <String>[]
            : normalizedMembers
                .where((member) => !previousGroup.members.contains(member))
                .toList();
    final matchingTrackers =
        previousGroup == null || addedMembers.isEmpty
            ? const <Tracker>[]
            : ref
                .read(trackersProvider)
                .where(
                  (tracker) =>
                      !tracker.archived &&
                      previousGroup.members.every(tracker.users.contains) &&
                      addedMembers.any(
                        (member) => !tracker.users.contains(member),
                      ),
                )
                .toList();

    await ref.read(userGroupsProvider.notifier).save(group);
    if (!mounted) return;
    Navigator.pop(context);

    if (matchingTrackers.isNotEmpty) {
      final shouldUpdate =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Update existing trackers?'),
                  content: Text(
                    '${addedMembers.join(', ')} ${addedMembers.length == 1 ? 'was' : 'were'} added to $name.\n\n'
                    'Add ${addedMembers.length == 1 ? 'this person' : 'these people'} to ${matchingTrackers.length} matching active tracker${matchingTrackers.length == 1 ? '' : 's'}?\n\n'
                    '${matchingTrackers.map((tracker) => tracker.title).join(', ')}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Not Now'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Update Trackers'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (shouldUpdate) {
        await ref
            .read(trackersProvider.notifier)
            .addUsersToTrackers(
              matchingTrackers.map((tracker) => tracker.id),
              addedMembers,
            );
        if (!mounted) return;
        showTrackerAlert(
          context,
          message:
              '${matchingTrackers.length} tracker${matchingTrackers.length == 1 ? '' : 's'} updated.',
        );
        return;
      }
    }

    if (!mounted) return;
    showTrackerAlert(
      context,
      message:
          groupId == null ? '$name group created.' : '$name group updated.',
    );
  }

  Future<void> _deleteGroup(String groupId, String groupName) async {
    await ref.read(userGroupsProvider.notifier).delete(groupId);
    if (!mounted) return;
    showTrackerAlert(context, message: '$groupName deleted.');
  }
}
