import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/hisaab_typography.dart';
import '../../data/trackers_providers.dart';
import '../../model/tracker.dart';
import '../widgets/glass_card.dart';
import '../widgets/tracker_alert.dart';

class CyclePage extends ConsumerStatefulWidget {
  final String trackerId;
  const CyclePage({super.key, required this.trackerId});

  @override
  ConsumerState<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends ConsumerState<CyclePage> {
  late Tracker tracker;
  late Map<String, bool> paid;
  int total = 0;
  DateTime? due;

  late TextEditingController totalController;
  bool editingTotal = false;

  String get monthKey => '${DateTime.now().year}-${DateTime.now().month}';

  int get perHead =>
      tracker.users.isEmpty ? 0 : (total / tracker.users.length).ceil();

  void setAllPaid(bool value) {
    setState(() {
      for (final user in tracker.users) {
        paid[user] = value;
      }
    });
    persist();
  }

  @override
  void initState() {
    super.initState();
    tracker = ref.read(trackersProvider.notifier).byId(widget.trackerId)!;

    tracker = tracker.copyWith(
      users: List<String>.from(tracker.users)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );

    paid = {for (var u in tracker.users) u: false};

    final saved = ref
        .read(monthlyRecordsProvider.notifier)
        .recordFor(tracker.id, monthKey);
    if (saved != null) {
      paid = Map<String, bool>.from(saved['paid']);
      total = saved['total'];
    } else {
      total = tracker.amount ?? 0;
    }
    due = recurringDueDateForMonth(tracker.dueDate, DateTime.now());

    totalController = TextEditingController(text: total.toString());
  }

  @override
  void dispose() {
    totalController.dispose();
    super.dispose();
  }

  Future<void> persist() async {
    await ref
        .read(monthlyRecordsProvider.notifier)
        .save(
          trackerId: tracker.id,
          monthKey: monthKey,
          paid: paid,
          total: total,
        );
  }

  Future<void> persistTracker() async {
    await ref.read(trackersProvider.notifier).save(tracker);
  }

  void openEditTracker() {
    final titleCtrl = TextEditingController(text: tracker.title);
    final amountCtrl = TextEditingController(
      text: tracker.amount?.toString() ?? '',
    );
    final users = List<String>.from(tracker.users);
    DateTime newDue = tracker.dueDate;
    String iconId = tracker.iconId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder:
                  (context, setModal) => ListView(
                    shrinkWrap: true,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tracker name',
                        ),
                      ),
                      if (tracker.amount == null)
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                        ),
                      ListTile(
                        title: Text(
                          'Due: ${newDue.day}/${newDue.month}/${newDue.year}',
                        ),
                        trailing: const Icon(Icons.event),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: newDue,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModal(() => newDue = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Users', style: TextStyle(fontFamily: context.hisaabFontFamily)),
                      Wrap(
                        spacing: 8,
                        children:
                            users
                                .map(
                                  (u) => Chip(
                                    label: Text(u),
                                    onDeleted: () {
                                      setModal(() => users.remove(u));
                                      paid.remove(u);
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Add user',
                        ),
                        onSubmitted: (v) {
                          if (v.isNotEmpty && !users.contains(v)) {
                            setModal(() {
                              users.add(formatName(v));
                              users.sort(
                                (a, b) =>
                                    a.toLowerCase().compareTo(b.toLowerCase()),
                              );
                            });
                            paid[formatName(v)] = false;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children:
                            trackerIcons.entries.map((e) {
                              final selected = iconId == e.key;
                              return GestureDetector(
                                onTap: () => setModal(() => iconId = e.key),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      selected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    e.value,
                                    color:
                                        selected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            tracker = tracker.copyWith(
                              title: titleCtrl.text,
                              amount: int.tryParse(amountCtrl.text),
                              dueDate: newDue,
                              users: List<String>.from(users)..sort(
                                (a, b) =>
                                    a.toLowerCase().compareTo(b.toLowerCase()),
                              ),
                              iconId: iconId,
                            );
                            due = recurringDueDateForMonth(
                              newDue,
                              DateTime.now(),
                            );
                            total = tracker.amount ?? total;
                          });

                          await persist();
                          await persistTracker();
                          if (!context.mounted) return;
                          showTrackerAlert(
                            context,
                            message: 'Tracker updated.',
                          );
                          Navigator.pop(context);
                        },
                        child: Text('Save changes', style: TextStyle(fontFamily: context.hisaabFontFamily)),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  String _buildMessage() {
    final settings = ref.read(trackerSettingsProvider);
    final per =
        tracker.users.isEmpty ? 0 : (total / tracker.users.length).ceil();

    final paidUsers =
        tracker.users.where((u) => paid[u] == true).toList()..sort();
    final pendingUsers =
        tracker.users.where((u) => paid[u] != true).toList()..sort();
    final allPaid =
        tracker.users.isNotEmpty && paidUsers.length == tracker.users.length;

    final now = DateTime.now();
    final daysRemaining =
        due!.difference(DateTime(now.year, now.month, now.day)).inDays;
    final replacements = <String, String>{
      '{title}': tracker.title,
      '{status}': allPaid ? 'All paid' : 'Pending',
      '{dueDate}': '${due!.day}/${due!.month}/${due!.year}',
      '{daysRemaining}': '$daysRemaining',
      '{total}': '$total',
      '{perHead}': '$per',
      '{paidCount}': '${paidUsers.length}',
      '{paidAmount}': '${paidUsers.length * per}',
      '{paidUsers}': paidUsers.isEmpty ? '-' : paidUsers.join('\n'),
      '{pendingCount}': '${pendingUsers.length}',
      '{pendingAmount}': '${pendingUsers.length * per}',
      '{pendingUsers}': pendingUsers.isEmpty ? '-' : pendingUsers.join('\n'),
    };

    var template =
        allPaid ? settings.allPaidMessageTemplate : settings.messageTemplate;
    replacements.forEach((key, value) {
      template = template.replaceAll(key, value);
    });
    return template;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;
    final totalUsers = tracker.users.length;
    final paidCount = tracker.users.where((u) => paid[u] == true).length;
    final pendingCount = tracker.users.length - paidCount;
    final paidAmount = paidCount * perHead;
    final pendingAmount = pendingCount * perHead;
    final paidProgress = totalUsers == 0 ? 0.0 : paidCount / totalUsers;
    final allPaid = totalUsers > 0 && paidCount == totalUsers;
    final today = DateTime.now();
    final dueDateOnly = DateTime(due!.year, due!.month, due!.day);
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final daysRemaining = dueDateOnly.difference(todayDateOnly).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(iconDataFromId(tracker.iconId)),
            const SizedBox(width: 12),
            Text(tracker.title, style: TextStyle(fontFamily: fontFamily)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: openEditTracker),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => SharePlus.instance.share(ShareParams(text: _buildMessage())),
        icon: const Icon(Icons.share),
        label: Text('Share', style: TextStyle(fontFamily: fontFamily)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            children: [
              TrackerGlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹$total',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Per Head',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹$perHead',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.tertiary,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(paidProgress * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.tertiary,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: paidProgress,
                        backgroundColor:
                            isDark ? Colors.white12 : const Color(0xFFD8E4EC),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3ED9A6),
                        ),
                      ),
                    ),
                    if (tracker.amount == null) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        readOnly: !editingTotal,
                        decoration: InputDecoration(
                          labelText: 'Update total',
                          prefixText: '₹ ',
                          suffixIcon: IconButton(
                            icon: Icon(editingTotal ? Icons.check : Icons.edit),
                            onPressed: () {
                              setState(() {
                                if (editingTotal) {
                                  total =
                                      int.tryParse(totalController.text) ??
                                      total;
                                  persist();
                                }
                                editingTotal = !editingTotal;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      title: 'Paid',
                      value: '$paidCount',
                      subValue: '₹$paidAmount',
                      tint: const Color(0xFF3ED9A6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      title: 'Pending',
                      value: '$pendingCount',
                      subValue: '₹$pendingAmount',
                      tint: const Color(0xFFFFB85C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      title: 'Due',
                      value: _dueText(daysRemaining),
                      subValue: '${due!.day}/${due!.month}',
                      tint:
                          daysRemaining < 0
                              ? const Color(0xFFFF6E6E)
                              : const Color(0xFF8CCBFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          totalUsers == 0 ? null : () => setAllPaid(!allPaid),
                      icon: Icon(
                        allPaid
                            ? Icons.restart_alt_rounded
                            : Icons.done_all_rounded,
                      ),
                      label: Text(allPaid ? 'Reset all' : 'Mark all paid', style: TextStyle(fontFamily: fontFamily)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tracker.users.map((u) {
                final isPaid = paid[u] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TrackerGlassCard(
                    onTap: () {
                      setState(() => paid[u] = !paid[u]!);
                      persist();
                    },
                    child: Row(
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              isPaid
                                  ? const Color(0xFF3ED9A6)
                                  : colorScheme.onSurface.withValues(
                                    alpha: 0.56,
                                  ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: fontFamily,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPaid ? 'Paid' : 'Pending',
                                style: TextStyle(
                                  color:
                                      isPaid
                                          ? colorScheme.tertiary
                                          : colorScheme.secondary,
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹$perHead',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 88),
            ],
          ),
        ),
    );
  }

  Widget _miniStat({
    required String title,
    required String value,
    required String subValue,
    required Color tint,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: fontFamily),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(color: tint, fontWeight: FontWeight.w600, fontFamily: fontFamily),
          ),
        ],
      ),
    );
  }

  String _dueText(int daysRemaining) {
    if (daysRemaining == 0) return 'Today';
    if (daysRemaining == 1) return '1 day';
    if (daysRemaining > 1) return '$daysRemaining days';
    if (daysRemaining == -1) return 'Over 1d';
    return 'Over ${daysRemaining.abs()}d';
  }
}
