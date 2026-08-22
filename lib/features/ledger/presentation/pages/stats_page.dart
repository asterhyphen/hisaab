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
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      return !dt.isBefore(start) && !dt.isAfter(end);
    }
    return dt.year == now.year && dt.month == now.month;
  }

  Future<void> _pickCustomStatsRange() async {
    final now = DateTime.now();
    final currentRange =
        _customStatsRange ??
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Drag to select date range',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
              child: Text('Cancel'),
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
              child: Text('Apply'),
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
    final customLabel =
        _customStatsRange == null
            ? 'Select range'
            : '${DateFormat('dd MMM').format(_customStatsRange!.start)} - ${DateFormat('dd MMM').format(_customStatsRange!.end)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'time_filter',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: context.hisaabFontFamily,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Monthly'),
                selected: _statsFilter == 'monthly',
                onSelected: (_) {
                  _statsFilter = 'monthly';
                  _refreshView();
                },
              ),
              ChoiceChip(
                label: Text('Yearly'),
                selected: _statsFilter == 'yearly',
                onSelected: (_) {
                  _statsFilter = 'yearly';
                  _refreshView();
                },
              ),
              ChoiceChip(
                label: Text('Custom'),
                selected: _statsFilter == 'custom',
                onSelected: (_) => _pickCustomStatsRange(),
              ),
              if (_statsFilter == 'custom')
                OutlinedButton.icon(
                  onPressed: _pickCustomStatsRange,
                  icon: Icon(Icons.date_range_outlined, size: 18),
                  label: Text(customLabel),
                ),
            ],
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamily: context.hisaabFontFamily,
        ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            keys.map((month) {
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
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: context.hisaabFontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 70 * ratio + 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        month,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: context.hisaabFontFamily,
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

    final totalUsers = box.keys.length;
    final avgTxnPerUser =
        activeUsers == 0 ? 0.0 : totalTransactions / activeUsers;
    final avgTxnAmount =
        totalTransactions == 0 ? 0.0 : (added + removed) / totalTransactions;

    final rankedByCount =
        userCountMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final rankedByVolume =
        userVolumeMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topCount = rankedByCount.isEmpty ? null : rankedByCount.first;
    final topVolume = rankedByVolume.isEmpty ? null : rankedByVolume.first;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildStatsFilterBar(),
        _buildSectionTitle('overview (${_statsFilterLabel()})'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildStatBox(
                title: 'USERS',
                children: [
                  _buildStatRow(
                    'Total',
                    totalUsers.toString(),
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  _buildStatRow(
                    'Active',
                    activeUsers.toString(),
                    Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              _buildStatBox(
                title: 'TRANSACTIONS',
                children: [
                  _buildStatRow(
                    'Total',
                    totalTransactions.toString(),
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  _buildStatRow(
                    'Avg/Active',
                    avgTxnPerUser.toStringAsFixed(1),
                    Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              _buildStatBox(
                title: 'VALUES',
                children: [
                  _buildStatRow(
                    'Avg Txn',
                    '₹${avgTxnAmount.toStringAsFixed(0)}',
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  _buildStatRow(
                    'Largest',
                    '₹${biggestTxn.toStringAsFixed(0)}',
                    Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              _buildStatBox(
                title: 'INSIGHTS',
                children: [
                  _buildStatRow(
                    'Top Contact',
                    topCount == null ? '--' : topCount.key,
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  _buildStatRow(
                    'Top Volume',
                    topVolume == null ? '--' : topVolume.key,
                    Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCashFlowComparisonChart(added, removed),
        _buildTopUsersDonutChart(
          title: 'top_users_by_transactions',
          data:
              rankedByCount
                  .take(5)
                  .map((e) => MapEntry(e.key, e.value.toDouble()))
                  .toList(),
          palette: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.error,
            Theme.of(context).colorScheme.outline,
          ],
          formatValue: (val) => '${val.toInt()} txns',
        ),
        _buildTopUsersDonutChart(
          title: 'top_users_by_volume',
          data: rankedByVolume.take(5).toList(),
          palette: [
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.error,
            Theme.of(context).colorScheme.outline,
          ],
          formatValue: (val) => '₹${val.toStringAsFixed(0)}',
        ),
        _buildSectionTitle('last_6_months_transactions'),
        _buildMonthlyTransactionsChart(monthCounts),
      ],
    );
  }

  Widget _buildStatBox({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: context.hisaabFontFamily,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: context.hisaabFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: context.hisaabFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowComparisonChart(double given, double received) {
    final maxVal =
        given > received
            ? (given > 0 ? given : 1.0)
            : (received > 0 ? received : 1.0);
    final givenRatio = given / maxVal;
    final receivedRatio = received / maxVal;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'money_flow_comparison()',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: context.hisaabFontFamily,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '₹${given.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontFamily: context.hisaabFontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 45,
                      height: 100 * givenRatio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.tertiary.withOpacity(0.6),
                            Theme.of(context).colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Given',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: context.hisaabFontFamily,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '₹${received.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                        fontFamily: context.hisaabFontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 45,
                      height: 100 * receivedRatio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.6),
                            Theme.of(context).colorScheme.error,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: context.hisaabFontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Balance:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: context.hisaabFontFamily,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '₹${(given - received).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: context.hisaabFontFamily,
                  color:
                      (given - received) >= 0
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersDonutChart({
    required String title,
    required List<MapEntry<String, double>> data,
    required List<Color> palette,
    required String Function(double) formatValue,
  }) {
    if (data.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: context.hisaabFontFamily,
            ),
          ),
        ),
      );
    }

    final double totalVal = data.fold(0, (sum, item) => sum + item.value);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: context.hisaabFontFamily,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    values: data.map((e) => e.value).toList(),
                    colors: palette,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(data.length, (index) {
                    final item = data[index];
                    final color = palette[index % palette.length];
                    final pct =
                        totalVal == 0 ? 0.0 : (item.value / totalVal) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: context.hisaabFontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${formatValue(item.value)} (${pct.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                              fontFamily: context.hisaabFontFamily,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.35;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;

    double startAngle = -3.1415926535 / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 3.1415926535 * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
