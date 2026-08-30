import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hisaab_typography.dart';
import '../../data/trackers_providers.dart';
import '../../model/tracker.dart';
import '../widgets/glass_card.dart';
import '../widgets/tracker_alert.dart';
import 'cycle_page.dart';

class TrackersHomePage extends ConsumerStatefulWidget {
  const TrackersHomePage({super.key});

  @override
  ConsumerState<TrackersHomePage> createState() => _TrackersHomePageState();
}

class _TrackersHomePageState extends ConsumerState<TrackersHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;
    final trackkars = ref.watch(activeTrackersProvider);
    final records = ref.watch(monthlyRecordsProvider);
    final settings = ref.watch(trackerSettingsProvider);
    final monthKey = ref.watch(currentMonthKeyProvider);
    final totalMembers = _userCount(trackkars);
    final activeTrackers = _activeCount(trackkars, records, monthKey);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            trackkars.isEmpty
                ? const Center(child: _TrackersEmptyState())
                : Column(
                  children: [
                    TrackerGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: isDark ? 0.18 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.analytics_outlined,
                                  color:
                                      isDark
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
                                      'Trackkars',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Track and manage shared expenses',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: 13,
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
                              _statTile(
                                context,
                                label: 'Total',
                                value: '${trackkars.length}',
                              ),
                              const SizedBox(width: 12),
                              _statTile(
                                context,
                                label: 'Active',
                                value: '$activeTrackers',
                              ),
                              const SizedBox(width: 12),
                              _statTile(
                                context,
                                label: 'Users',
                                value: '$totalMembers',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: trackkars.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (c, i) {
                          final tracker = trackkars[i];
                          final monthlyKey = '${tracker.id}_$monthKey';
                          final monthlyData = records[monthlyKey];
                          final active = monthlyData != null;
                          final paidCount =
                              monthlyData == null
                                  ? 0
                                  : Map<String, dynamic>.from(
                                    monthlyData['paid'] ?? <String, dynamic>{},
                                  ).values.where((v) => v == true).length;
                          final totalCount = tracker.users.length;
                          final progress =
                              totalCount == 0 ? 0.0 : paidCount / totalCount;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(tracker.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                if (!settings.confirmDelete) return true;
                                return await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: const Text(
                                              'Delete tracker?',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this tracker? This action is irreversible.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      false,
                                                    ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      true,
                                                    ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) async {
                                await ref
                                    .read(trackersProvider.notifier)
                                    .delete(tracker.id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: TrackerGlassCard(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              CyclePage(trackerId: tracker.id),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color:
                                                active
                                                    ? colorScheme.primary
                                                    : (isDark
                                                        ? Colors.white10
                                                        : const Color(
                                                          0xFFE8EFF5,
                                                        )),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Icon(
                                            iconDataFromId(tracker.iconId),
                                            color:
                                                active
                                                    ? colorScheme.onPrimary
                                                    : colorScheme.onSurface
                                                        .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tracker.title,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: fontFamily,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                active
                                                    ? '$paidCount/$totalCount paid'
                                                    : 'Not started this month',
                                                style: TextStyle(
                                                  color:
                                                      active
                                                          ? (isDark
                                                              ? const Color(
                                                                0xFF77FFD8,
                                                              )
                                                              : colorScheme
                                                                  .primary)
                                                          : colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.58,
                                                              ),
                                                  fontWeight:
                                                      active
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                  fontFamily: fontFamily,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.outline,
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
                                          color: colorScheme.surface,
                                          onSelected: (value) {
                                            if (value == 'archive') {
                                              _updateTracker(
                                                tracker.copyWith(
                                                  archived: true,
                                                ),
                                              );
                                            } else if (value == 'delete') {
                                              _deleteTracker(tracker.id);
                                            }
                                          },
                                          itemBuilder:
                                              (context) => const [
                                                PopupMenuItem<String>(
                                                  value: 'archive',
                                                  child: Text('Archive'),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _chipLabel(
                                          context: context,
                                          icon: Icons.people_alt_outlined,
                                          label:
                                              '$totalCount member${totalCount == 1 ? '' : 's'}',
                                        ),
                                      ],
                                    ),
                                    if (active) ...[
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          minHeight: 8,
                                          value: progress,
                                          backgroundColor:
                                              isDark
                                                  ? Colors.white12
                                                  : const Color(0xFFD8E4EC),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFF3ED9A6)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _updateTracker(Tracker tracker) async {
    await ref.read(trackersProvider.notifier).save(tracker);
    if (!mounted) return;
    showTrackerAlert(context, message: '${tracker.title} moved to archive.');
  }

  Future<void> _deleteTracker(String trackerId) async {
    final tracker = await ref.read(trackersProvider.notifier).delete(trackerId);
    if (!mounted) return;
    showTrackerAlert(
      context,
      message:
          tracker == null ? 'Tracker deleted.' : '${tracker.title} deleted.',
      icon: Icons.delete_outline,
    );
  }

  int _activeCount(
    List<Tracker> trackkars,
    Map<String, Map<String, dynamic>> records,
    String monthKey,
  ) {
    return trackkars
        .where((t) => records.containsKey('${t.id}_$monthKey'))
        .length;
  }

  int _userCount(List<Tracker> trackkars) {
    return trackkars.fold<int>(0, (sum, t) => sum + t.users.length);
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: context.hisaabFontFamily,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
              fontFamily: context.hisaabFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFD7E3EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              fontFamily: context.hisaabFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackersEmptyState extends StatelessWidget {
  const _TrackersEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : theme.colorScheme.outline.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Trackkars Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: context.hisaabFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first tracker using the + icon below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                fontFamily: context.hisaabFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
