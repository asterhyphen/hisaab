part of 'friend_list_page.dart';

extension _StatsPageTab on _FriendListPageState {
  DateTime? _tryParseTxnDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy hh:mm a').parseStrict(text);
    } catch (_) {}
    try {
      return DateTime.tryParse(text);
    } catch (_) {}
    try {
      final n = int.parse(text);
      return n.toString().length <= 10
          ? DateTime.fromMillisecondsSinceEpoch(n * 1000)
          : DateTime.fromMillisecondsSinceEpoch(n);
    } catch (_) {}
    return null;
  }

  String _statsFilterLabel() {
    switch (_statsFilter) {
      case 'yearly':
        return 'Yearly';
      case 'custom':
        return 'Custom';
      default:
        return 'Monthly';
    }
  }

  bool _isTxnInSelectedRange(DateTime dt) {
    final now = DateTime.now();
    if (_statsFilter == 'yearly') {
      return dt.year == now.year;
    }
    if (_statsFilter == 'custom') {
      final range = _customStatsRange;
      if (range == null) return false;
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      return !dt.isBefore(start) && !dt.isAfter(end);
    }
    return dt.year == now.year && dt.month == now.month;
  }

  Future<void> _pickCustomStatsRange() async {
    final now = DateTime.now();
    final currentRange = _customStatsRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    PickerDateRange tempRange = PickerDateRange(
      currentRange.start,
      currentRange.end,
    );
    DateTime? lastHapticDay;
    int lastSelectionUpdateMs = 0;

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text(
            'Drag to select date range',
            style: TextStyle(color: Color(0xFFE6EDF3)),
          ),
          content: SizedBox(
            width: 360,
            height: 380,
            child: SfDateRangePicker(
              selectionMode: DateRangePickerSelectionMode.extendableRange,
              initialSelectedRange: tempRange,
              minDate: DateTime(2000),
              maxDate: DateTime(2100),
              showNavigationArrow: true,
              monthViewSettings: const DateRangePickerMonthViewSettings(
                firstDayOfWeek: 1,
              ),
              onSelectionChanged: (args) {
                final value = args.value;
                if (value is PickerDateRange) {
                  final currentDay = value.endDate ?? value.startDate;
                  if (currentDay != null) {
                    final normalized = DateTime(
                      currentDay.year,
                      currentDay.month,
                      currentDay.day,
                    );
                    if (lastHapticDay == null || lastHapticDay != normalized) {
                      HapticFeedback.selectionClick();
                      lastHapticDay = normalized;
                    }
                  }

                  // Tiny throttle for a slightly slower day-by-day drag feel.
                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                  if (nowMs - lastSelectionUpdateMs < 30) return;
                  lastSelectionUpdateMs = nowMs;
                  tempRange = value;
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final start = tempRange.startDate;
                final end = tempRange.endDate ?? tempRange.startDate;
                if (start == null || end == null) {
                  Navigator.pop(context);
                  return;
                }
                final normalized = DateTimeRange(
                  start: DateTime(start.year, start.month, start.day),
                  end: DateTime(end.year, end.month, end.day),
                );
                Navigator.pop(context, normalized);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (picked == null) return;
    _customStatsRange = picked;
    _statsFilter = 'custom';
    _refreshView();
  }

  Widget _buildStatsFilterBar() {
    final customLabel = _customStatsRange == null
        ? 'Select range'
        : '${DateFormat('dd MMM').format(_customStatsRange!.start)} - ${DateFormat('dd MMM').format(_customStatsRange!.end)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'time_filter',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontFamily: 'Courier New',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Monthly'),
                selected: _statsFilter == 'monthly',
                onSelected: (_) {
                  _statsFilter = 'monthly';
                  _refreshView();
                },
              ),
              ChoiceChip(
                label: const Text('Yearly'),
                selected: _statsFilter == 'yearly',
                onSelected: (_) {
                  _statsFilter = 'yearly';
                  _refreshView();
                },
              ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: _statsFilter == 'custom',
                onSelected: (_) => _pickCustomStatsRange(),
              ),
              if (_statsFilter == 'custom')
                OutlinedButton.icon(
                  onPressed: _pickCustomStatsRange,
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(customLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontFamily: 'Courier New',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier New',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF58A6FF),
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamily: 'Courier New',
        ),
      ),
    );
  }

  Widget _buildRankBar({
    required String name,
    required String subtitle,
    required double ratio,
    required Color color,
  }) {
    final safeRatio = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier New',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontFamily: 'Courier New',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeRatio,
              minHeight: 8,
              backgroundColor: const Color(0xFF30363D),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTransactionsChart(Map<String, int> monthCounts) {
    final keys = monthCounts.keys.toList();
    final maxCount = monthCounts.values.fold<int>(
      0,
      (prev, e) => e > prev ? e : prev,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: keys.map((month) {
          final count = monthCounts[month] ?? 0;
          final ratio = maxCount == 0 ? 0.0 : (count / maxCount);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8B949E),
                      fontFamily: 'Courier New',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 70 * ratio + 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF58A6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    month,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8B949E),
                      fontFamily: 'Courier New',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsBody() {
    double added = 0;
    double removed = 0;
    double biggestTxn = 0;
    int totalTransactions = 0;
    int activeUsers = 0;
    final userCountMap = <String, int>{};
    final userVolumeMap = <String, double>{};
    final now = DateTime.now();
    final monthCounts = <String, int>{};

    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(dt);
      monthCounts[key] = 0;
    }

    for (final key in box.keys) {
      final txns = (box.get(key) as List).cast<Map>();
      int userTxnsInRange = 0;
      double userVolumeInRange = 0;

      for (final tx in txns) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        final txnDate = _tryParseTxnDate(tx['date']);
        if (txnDate == null || !_isTxnInSelectedRange(txnDate)) {
          continue;
        }

        userTxnsInRange++;
        totalTransactions++;
        userVolumeInRange += amount.abs();
        if (amount.abs() > biggestTxn) biggestTxn = amount.abs();

        final month = DateFormat('MMM').format(txnDate);
        if (monthCounts.containsKey(month)) {
          monthCounts[month] = (monthCounts[month] ?? 0) + 1;
        }

        if (tx['type'] == 'add') {
          added += amount;
        } else {
          removed += amount;
        }
      }

      if (userTxnsInRange > 0) {
        activeUsers++;
        userCountMap[key.toString()] = userTxnsInRange;
        userVolumeMap[key.toString()] = userVolumeInRange;
      }
    }

    final net = added - removed;
    final totalUsers = box.keys.length;
    final avgTxnPerUser = activeUsers == 0 ? 0.0 : totalTransactions / activeUsers;
    final avgTxnAmount = totalTransactions == 0
        ? 0.0
        : (added + removed) / totalTransactions;

    final rankedByCount =
        userCountMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rankedByVolume =
        userVolumeMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final topCount = rankedByCount.isEmpty ? null : rankedByCount.first;
    final topVolume = rankedByVolume.isEmpty ? null : rankedByVolume.first;
    final maxCount = rankedByCount.isEmpty ? 1 : rankedByCount.first.value;
    final maxVolume = rankedByVolume.isEmpty ? 1.0 : rankedByVolume.first.value;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildStatsFilterBar(),
        _buildSectionTitle('overview (${_statsFilterLabel()})'),
        _buildStatCard('total_users', totalUsers.toString(), const Color(0xFF58A6FF)),
        _buildStatCard('active_users', activeUsers.toString(), const Color(0xFF58A6FF)),
        _buildStatCard(
          'total_transactions',
          totalTransactions.toString(),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'avg_txn_per_active_user',
          avgTxnPerUser.toStringAsFixed(2),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'avg_txn_amount',
          '₹${avgTxnAmount.toStringAsFixed(2)}',
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'largest_single_transaction',
          '₹${biggestTxn.toStringAsFixed(2)}',
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'total_added',
          '₹${added.toStringAsFixed(2)}',
          const Color(0xFF3FB950),
        ),
        _buildStatCard(
          'total_removed',
          '₹${removed.toStringAsFixed(2)}',
          const Color(0xFFF85149),
        ),
        _buildStatCard(
          'net_balance',
          '₹${net.toStringAsFixed(2)}',
          net >= 0 ? const Color(0xFF3FB950) : const Color(0xFFF85149),
        ),
        _buildSectionTitle('insights'),
        _buildStatCard(
          'most_transactions_with',
          topCount == null ? '--' : '${topCount.key} (${topCount.value})',
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'highest_transaction_volume',
          topVolume == null
              ? '--'
              : '${topVolume.key} (₹${topVolume.value.toStringAsFixed(2)})',
          const Color(0xFF58A6FF),
        ),
        _buildSectionTitle('top_users_by_transactions'),
        if (rankedByCount.isEmpty)
          _buildStatCard('top_users', 'No data in selected range', const Color(0xFF8B949E)),
        ...rankedByCount.take(5).map(
          (entry) => _buildRankBar(
            name: entry.key,
            subtitle: '${entry.value} txns',
            ratio: entry.value / maxCount,
            color: const Color(0xFF3FB950),
          ),
        ),
        _buildSectionTitle('top_users_by_volume'),
        if (rankedByVolume.isEmpty)
          _buildStatCard('top_volume', 'No data in selected range', const Color(0xFF8B949E)),
        ...rankedByVolume.take(5).map(
          (entry) => _buildRankBar(
            name: entry.key,
            subtitle: '₹${entry.value.toStringAsFixed(2)}',
            ratio: entry.value / maxVolume,
            color: const Color(0xFF58A6FF),
          ),
        ),
        _buildSectionTitle('last_6_months_transactions'),
        _buildMonthlyTransactionsChart(monthCounts),
      ],
    );
  }
}
