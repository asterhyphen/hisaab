import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hisaab_typography.dart';
import '../../data/trackers_providers.dart';
import '../../model/tracker.dart';
import '../widgets/glass_card.dart';
import '../widgets/tracker_alert.dart';

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final trackkars = ref.watch(archivedTrackersProvider);

    final fontFamily = context.hisaabFontFamily;

    return Scaffold(
      appBar: AppBar(title: Text('Archive', style: TextStyle(fontFamily: fontFamily))),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [Color(0xFF111A2B), Color(0xFF090F1B)]
                    : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
          ),
        ),
        child: SafeArea(
          child:
              trackkars.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No trackkars have been archived yet.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trackkars.length,
                    itemBuilder: (context, index) {
                      final tracker = trackkars[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TrackerGlassCard(
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.white10
                                          : const Color(0xFFE8EFF5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  iconDataFromId(tracker.iconId),
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tracker.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tracker.users.length} member${tracker.users.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.64,
                                        ),
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
                                    color:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.06,
                                            )
                                            : const Color(0xFFF1F6FA),
                                    borderRadius: BorderRadius.circular(12),
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
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.76,
                                    ),
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color:
                                    isDark
                                        ? const Color(0xFF142033)
                                        : Colors.white,
                                onSelected: (value) {
                                  if (value == 'restore') {
                                    _updateTracker(
                                      tracker.copyWith(archived: false),
                                    );
                                  } else if (value == 'delete') {
                                    _deleteTracker(tracker.id);
                                  }
                                },
                                itemBuilder:
                                    (context) => const [
                                      PopupMenuItem<String>(
                                        value: 'restore',
                                        child: Text('Restore'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Future<void> _updateTracker(Tracker tracker) async {
    await ref.read(trackersProvider.notifier).save(tracker);
    if (!mounted) return;
    showTrackerAlert(context, message: '${tracker.title} restored.');
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
}
