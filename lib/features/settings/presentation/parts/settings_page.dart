part of '../../../ledger/presentation/pages/friend_list_page.dart';

extension _SettingsPageTab on _FriendListPageState {
  Widget _buildSettingsBody() {
    final name = _profileName();
    final themeKey = _currentThemeKey();
    final upi = _profileUpi();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'profile',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: context.hisaabFontFamily,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _appProfileAvatar(radius: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This name is used across your app profile.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (upi.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UPI: $upi',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _editProfileName,
                    icon: Icon(Icons.badge_outlined),
                    label: Text('Change name'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _changeAppProfilePicture,
                    icon: Icon(Icons.image_outlined),
                    label: Text('Change photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _editAppUpi,
                    icon: Icon(Icons.qr_code_outlined),
                    label: Text('Change UPI'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'appearance',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: context.hisaabFontFamily,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  'Theme',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  _themeLabel(themeKey),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: _editThemePreference,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'data_management',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: context.hisaabFontFamily,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _importAllCsv,
                icon: Icon(Icons.upload_file),
                label: Text('Import all CSV'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportAllCsv,
                icon: Icon(Icons.download_rounded),
                label: Text('Export all CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: FaIcon(
              FontAwesomeIcons.github,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
            title: Text(
              'Open GitHub',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: context.hisaabFontFamily,
              ),
            ),
            trailing: Icon(
              Icons.open_in_new,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: _launchGitHub,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'danger_zone',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontFamily: context.hisaabFontFamily,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _resetSingleUserHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                icon: Icon(Icons.person_remove_alt_1_outlined),
                label: Text('Reset history of user'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _resetAllUsersHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                icon: Icon(Icons.groups_2_outlined),
                label: Text('Reset history of all users'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _deleteAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor:
                      Theme.of(context).colorScheme.onErrorContainer,
                ),
                icon: Icon(Icons.delete_forever_outlined),
                label: Text('Delete all data'),
              ),
              const SizedBox(height: 10),
              Text(
                'Note: All data is local, nothing is shared or stored on the cloud.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
