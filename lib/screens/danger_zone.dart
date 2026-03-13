part of 'friend_list_page.dart';

extension _FriendListPageDangerZone on _FriendListPageState {
  Future<bool> _confirmDangerAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(title, style: const TextStyle(color: Color(0xFFE6EDF3))),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF8B949E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _resetSingleUserHistory() async {
    final users = box.keys.cast<String>().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (users.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No users found')));
      return;
    }

    final selectedUser = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Reset history of user',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(
                users[i],
                style: const TextStyle(color: Color(0xFFE6EDF3)),
              ),
              onTap: () => Navigator.pop(context, users[i]),
            ),
          ),
        ),
      ),
    );
    if (selectedUser == null) return;

    final confirmed = await _confirmDangerAction(
      title: 'Reset $selectedUser history?',
      message: 'This will delete all transactions for $selectedUser.',
      confirmLabel: 'Reset',
    );
    if (!confirmed) return;

    await box.put(selectedUser, []);
    if (!mounted) return;
    _refreshView();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$selectedUser history reset')));
  }

  Future<void> _resetAllUsersHistory() async {
    if (box.keys.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No users found')));
      return;
    }
    final confirmed = await _confirmDangerAction(
      title: 'Reset history of all users?',
      message:
          'This will delete all transactions for every user. Users and profile icons stay intact.',
      confirmLabel: 'Reset all',
    );
    if (!confirmed) return;

    for (final key in box.keys.cast<String>()) {
      await box.put(key, []);
    }
    if (!mounted) return;
    _refreshView();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All user histories reset')));
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _confirmDangerAction(
      title: 'Delete all data?',
      message:
          'This will clear all users, transactions, profile settings, and app settings from this device.',
      confirmLabel: 'Delete everything',
    );
    if (!confirmed) return;

    await box.clear();
    await metaBox.clear();
    await appMetaBox.clear();
    if (!mounted) return;
    displayedKeys = [];
    _refreshView();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All local data deleted')));
    _maybeRunFirstInstallSetup();
  }
}
