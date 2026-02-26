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

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontFamily: 'Courier New',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier New',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier New',
                  ),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontFamily: 'Courier New',
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
        children:
            keys.map((month) {
              final count = monthCounts[month] ?? 0;
              final ratio = maxCount == 0 ? 0.0 : (count / maxCount);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
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
      final txns = box.get(key) as List;
      totalTransactions += txns.length;
      if (txns.isNotEmpty) activeUsers++;
      userCountMap[key.toString()] = txns.length;
      userVolumeMap[key.toString()] = 0.0;

      for (final tx in txns) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        userVolumeMap[key.toString()] =
            (userVolumeMap[key.toString()] ?? 0) + amount.abs();

        final date = _tryParseTxnDate(tx['date']);
        if (date != null) {
          final month = DateFormat('MMM').format(date);
          if (monthCounts.containsKey(month)) {
            monthCounts[month] = (monthCounts[month] ?? 0) + 1;
          }
        }

        if (tx['type'] == 'add') {
          added += amount;
        } else {
          removed += amount;
        }
      }
    }

    final net = added - removed;
    final totalUsers = box.keys.length;
    final avgTxnPerUser = totalUsers == 0 ? 0.0 : totalTransactions / totalUsers;

    final rankedByCount =
        userCountMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rankedByVolume =
        userVolumeMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topCount = rankedByCount.isEmpty ? null : rankedByCount.first;
    final topVolume = rankedByVolume.isEmpty ? null : rankedByVolume.first;
    final maxCount = rankedByCount.isEmpty ? 1 : rankedByCount.first.value;
    final maxVolume =
        rankedByVolume.isEmpty ? 1.0 : rankedByVolume.first.value;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSectionTitle('overview'),
        _buildStatCard(
          'total_users',
          totalUsers.toString(),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'active_users',
          activeUsers.toString(),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'total_transactions',
          totalTransactions.toString(),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'avg_txn_per_user',
          avgTxnPerUser.toStringAsFixed(2),
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
          _buildStatCard('top_users', 'No data yet', const Color(0xFF8B949E)),
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
          _buildStatCard('top_volume', 'No data yet', const Color(0xFF8B949E)),
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
