import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/trackers/data/trackers_providers.dart';
import '../../../../features/trackers/model/tracker.dart';
import '../../../../features/users/data/users_provider.dart';
import '../widgets/tracker_alert.dart';
import 'users_page.dart';

class TrackerPage extends ConsumerStatefulWidget {
  const TrackerPage({super.key});

  @override
  ConsumerState<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends ConsumerState<TrackerPage> {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final userCtrl = TextEditingController();

  final List<String> users = [];
  DateTime startDate = DateTime.now();
  DateTime dueDate = DateTime.now();
  bool isConstantBill = false;

  String iconId = 'Bill';
  bool iconManuallySelected = false;

  Future<void> _openUsersPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    titleCtrl.addListener(() {
      if (!iconManuallySelected) {
        setState(() {
          iconId = autoIconIdFromText(titleCtrl.text);
        });
      }
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    userCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final savedUsers = ref.watch(savedUsersProvider);
    final savedGroups = ref.watch(userGroupsProvider);
    final peopleCount = users.length;
    final baseAmount = isConstantBill ? int.tryParse(amountCtrl.text) ?? 0 : 0;
    final perHead = peopleCount == 0 ? 0 : (baseAmount / peopleCount).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tracker')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [Color(0xFF10192B), Color(0xFF090F1B)]
                    : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tracker name',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Variable Bill'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Constant Bill'),
                      ),
                    ],
                    selected: {isConstantBill},
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    onSelectionChanged: (selected) {
                      setState(() {
                        isConstantBill = selected.first;
                        if (!isConstantBill) amountCtrl.clear();
                      });
                    },
                  ),
                ),
                if (isConstantBill) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                if (savedGroups.isNotEmpty || savedUsers.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select from saved groups or users',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openUsersPage,
                        child: const Text('Manage saved users'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (savedGroups.isNotEmpty) ...[
                  Text(
                    'Quick Add Groups',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final group = savedGroups[index];
                        final allAdded = group.members.every(users.contains);
                        return InkWell(
                          onTap: () => _addUsers(group.members),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  allAdded
                                      ? colorScheme.primary.withValues(
                                        alpha: isDark ? 0.16 : 0.12,
                                      )
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white.withValues(
                                            alpha: 0.82,
                                          )),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    allAdded
                                        ? colorScheme.primary.withValues(
                                          alpha: 0.4,
                                        )
                                        : (isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.08,
                                            )
                                            : const Color(0xFFD9E6EF)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.groups_rounded,
                                      color:
                                          allAdded
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                    ),
                                    const Spacer(),
                                    Icon(
                                      allAdded
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      size: 18,
                                      color:
                                          allAdded
                                              ? colorScheme.primary
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.64),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (savedUsers.isNotEmpty) ...[
                  Text(
                    'Pick Saved Users',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        savedUsers.map((savedUser) {
                          final added = users.contains(savedUser);
                          return FilterChip(
                            label: Text(savedUser),
                            selected: added,
                            onSelected: (selected) {
                              if (selected) {
                                _addUsers([savedUser]);
                              } else {
                                setState(() => users.remove(savedUser));
                              }
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                if (savedGroups.isEmpty && savedUsers.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFD9E6EF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save users before creating trackers',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Go to the Users tab to save people or create groups, then pick them here when making a new tracker.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _openUsersPage,
                          child: const Text('Open Users page'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        context: context,
                        icon: Icons.calendar_month,
                        label: 'Start Date',
                        value:
                            '${startDate.day}/${startDate.month}/${startDate.year}',
                        onTap: () => pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateTile(
                        context: context,
                        icon: Icons.event,
                        label: 'Recurring Due Date',
                        value:
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                        onTap: () => pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add user manually',
                          prefixIcon: Icon(Icons.person_add_alt_1),
                        ),
                        onSubmitted: (_) => _addUser(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _addUser,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      users
                          .map(
                            (u) => Chip(
                              label: Text(u),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => users.remove(u)),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFD9E6EF),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Per Head'),
                      Text(
                        !isConstantBill
                            ? 'Set monthly total later'
                            : peopleCount == 0 || baseAmount == 0
                            ? 'Add amount & users'
                            : '₹$perHead each',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The selected due date repeats automatically every month.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pick Icon',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      trackerIcons.entries.map((e) {
                        final selected = iconId == e.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              iconId = e.key;
                              iconManuallySelected = true;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  selected
                                      ? const Color(0xFF00B894)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF0F5F9)),
                            ),
                            child: Icon(
                              e.value,
                              color:
                                  selected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _createTracker,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Create Tracker'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addUser() {
    final formatted = formatName(userCtrl.text);
    if (formatted.isEmpty) return;
    _addUsers([formatted], clearInput: true);
  }

  void _addUsers(List<String> newUsers, {bool clearInput = false}) {
    final merged = normalizeNames([...users, ...newUsers]);
    if (merged.length == users.length) {
      if (clearInput) userCtrl.clear();
      return;
    }
    setState(() {
      users
        ..clear()
        ..addAll(merged);
      if (clearInput) userCtrl.clear();
    });
  }

  Widget _dateTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFD9E6EF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _createTracker() async {
    if (titleCtrl.text.trim().isEmpty) {
      showTrackerAlert(
        context,
        message: 'Please enter a tracker name.',
        tone: TrackerAlertTone.info,
        icon: Icons.info_outline,
      );
      return;
    }

    if (isConstantBill && (int.tryParse(amountCtrl.text) ?? 0) <= 0) {
      showTrackerAlert(
        context,
        message: 'Enter an amount for a constant bill.',
        tone: TrackerAlertTone.info,
        icon: Icons.info_outline,
      );
      return;
    }

    final id = '${titleCtrl.text}_${DateTime.now().millisecondsSinceEpoch}';

    final tracker = Tracker(
      id: id,
      title: titleCtrl.text,
      amount: isConstantBill ? int.tryParse(amountCtrl.text) : null,
      startDate: startDate,
      dueDate: dueDate,
      users: List<String>.from(users)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      iconId: iconId,
      archived: false,
    );

    await ref.read(trackersProvider.notifier).create(tracker);
    if (!mounted) return;
    showTrackerAlert(context, message: 'Tracker created.');
    Navigator.pop(context);
  }
}
