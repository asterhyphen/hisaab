part of 'friend_list_page.dart';

extension _StatsPageTab on _FriendListPageState {
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

  Widget _buildStatisticsBody() {
    double added = 0;
    double removed = 0;
    int totalTransactions = 0;

    for (final key in box.keys) {
      final txns = box.get(key) as List;
      totalTransactions += txns.length;
      for (final tx in txns) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        if (tx['type'] == 'add') {
          added += amount;
        } else {
          removed += amount;
        }
      }
    }

    final net = added - removed;
    final totalUsers = box.keys.length;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildStatCard(
          'users_count',
          totalUsers.toString(),
          const Color(0xFF58A6FF),
        ),
        _buildStatCard(
          'transactions_count',
          totalTransactions.toString(),
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
      ],
    );
  }
}
