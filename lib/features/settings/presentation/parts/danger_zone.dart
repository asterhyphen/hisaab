part of '../../../ledger/presentation/pages/friend_list_page.dart';

extension _FriendListPageDangerZone on _FriendListPageState {
  Future<bool> _confirmDangerAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
    return res == true;
  }

  Future<void> _resetSingleUserHistory() async {
    final users =
        box.keys.cast<String>().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (users.isEmpty) {
      GlassAlert.showInfo(context, 'No users found');
      return;
    }

    final selectedUser = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Reset history of user',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: SizedBox(
              width: 320,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder:
                    (_, i) => ListTile(
                      title: Text(
                        users[i],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
    GlassAlert.showSuccess(context, '$selectedUser history reset');
  }

  Future<void> _resetAllUsersHistory() async {
    if (box.keys.isEmpty) {
      GlassAlert.showInfo(context, 'No users found');
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
    GlassAlert.showSuccess(context, 'All user histories reset');
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
    GlassAlert.showSuccess(context, 'All local data deleted');
    _maybeRunFirstInstallSetup();
  }
}
