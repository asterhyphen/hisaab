part of 'friend_list_page.dart';

extension _SettingsPageTab on _FriendListPageState {
  Widget _buildSettingsBody() {
    final name = _profileName();
    final themeKey = _currentThemeKey();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'profile',
                style: TextStyle(
                  color: Color(0xFF00D084),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Courier New',
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
                          style: const TextStyle(
                            color: Color(0xFFE6EDF3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'This name is used across your app profile.',
                          style: TextStyle(color: Color(0xFF8B949E)),
                        ),
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
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('Change name'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _changeAppProfilePicture,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Change photo'),
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
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'appearance',
                style: TextStyle(
                  color: Color(0xFF00D084),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Courier New',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.palette_outlined,
                  color: Color(0xFF58A6FF),
                ),
                title: const Text(
                  'Theme',
                  style: TextStyle(color: Color(0xFFE6EDF3)),
                ),
                subtitle: Text(
                  _themeLabel(themeKey),
                  style: const TextStyle(color: Color(0xFF8B949E)),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8B949E),
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
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'data_management',
                style: TextStyle(
                  color: Color(0xFF00D084),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Courier New',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _importAllCsv,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import all CSV'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportAllCsv,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export all CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const FaIcon(
              FontAwesomeIcons.github,
              color: Color(0xFF58A6FF),
              size: 20,
            ),
            title: const Text(
              'Open GitHub',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontFamily: 'Courier New',
              ),
            ),
            trailing: const Icon(Icons.open_in_new, color: Color(0xFF8B949E)),
            onTap: _launchGitHub,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF8E2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'danger_zone',
                style: TextStyle(
                  color: Color(0xFFF85149),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Courier New',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _resetSingleUserHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF85149),
                  side: const BorderSide(color: Color(0xFFF85149)),
                ),
                icon: const Icon(Icons.person_remove_alt_1_outlined),
                label: const Text('Reset history of user'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _resetAllUsersHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF85149),
                  side: const BorderSide(color: Color(0xFFF85149)),
                ),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Reset history of all users'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _deleteAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF85149),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete all data'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Note: All data is local, nothing is shared or stored on the cloud.',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
