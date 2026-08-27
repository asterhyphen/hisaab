part of '../../../ledger/presentation/pages/friend_list_page.dart';

extension _SettingsPageTab on _FriendListPageState {
  Widget _buildSettingsBody() {
    final name = _profileName();
    final themeKey = _currentThemeKey();
    final upi = _profileUpi();
    final trackerSettings = ref.watch(trackerSettingsProvider);
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
                'trackkars',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: context.hisaabFontFamily,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: trackerSettings.confirmDelete,
                title: Text(
                  'Confirm before deleting tracker',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onChanged:
                    (value) => _saveTrackerSettings(
                      trackerSettings.copyWith(confirmDelete: value),
                    ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: trackerSettings.includeTrackkarsInTotal,
                title: Text(
                  'Include trackkar amounts in home total',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Unpaid trackkar amounts for the current month are added to the total_pending on the Home tab.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged:
                    (value) => _saveTrackerSettings(
                      trackerSettings.copyWith(includeTrackkarsInTotal: value),
                    ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.message_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  'Message templates',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => _editTrackerMessageTemplates(trackerSettings),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: trackerSettings.notificationsEnabled,
                title: Text(
                  'Due reminders',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Notify ${trackerSettings.reminderDaysBefore} day${trackerSettings.reminderDaysBefore == 1 ? '' : 's'} before due date.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (value) {
                  _setTrackerNotifications(trackerSettings, value);
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child:
                    trackerSettings.notificationsEnabled
                        ? Column(
                          key: const ValueKey('tracker_reminder_days'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Slider(
                              min: 1,
                              max: 7,
                              divisions: 6,
                              label: '${trackerSettings.reminderDaysBefore}',
                              value:
                                  trackerSettings.reminderDaysBefore.toDouble(),
                              onChanged: (value) {
                                _saveTrackerSettings(
                                  trackerSettings.copyWith(
                                    reminderDaysBefore: value.round(),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                        : const SizedBox.shrink(
                          key: ValueKey('tracker_reminder_days_empty'),
                        ),
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

  Future<void> _saveTrackerSettings(TrackerSettings settings) async {
    await ref.read(trackerSettingsProvider.notifier).save(settings);
  }

  Future<void> _editTrackerMessageTemplates(TrackerSettings settings) async {
    final result = await Navigator.of(context).push<MessageTemplateEditResult>(
      MaterialPageRoute(
        builder:
            (_) => MessageTemplateEditorPage(
              initialTemplate: settings.messageTemplate,
              initialAllPaidTemplate: settings.allPaidMessageTemplate,
            ),
      ),
    );

    if (result == null) return;
    await _saveTrackerSettings(
      settings.copyWith(
        messageTemplate: result.messageTemplate,
        allPaidMessageTemplate: result.allPaidMessageTemplate,
      ),
    );
    if (!mounted) return;
    GlassAlert.showSuccess(context, 'Message templates updated');
  }

  Future<void> _setTrackerNotifications(
    TrackerSettings settings,
    bool enabled,
  ) async {
    if (!enabled) {
      await _saveTrackerSettings(
        settings.copyWith(notificationsEnabled: false),
      );
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      GlassAlert.showError(
        context,
        'Notification permission was denied. Enable it from system settings to use due reminders.',
      );
      return;
    }

    await _saveTrackerSettings(settings.copyWith(notificationsEnabled: true));
    if (!mounted) return;
    GlassAlert.showSuccess(context, 'Due reminders turned on');
  }
}
