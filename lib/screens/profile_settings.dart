part of 'friend_list_page.dart';

extension _FriendListPageProfileTheme on _FriendListPageState {
  String _themeLabel(String key) {
    switch (key) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'Terminal (Default)';
    }
  }

  String _currentThemeKey() {
    final key = appMetaBox.get('theme') as String?;
    return _themeKeys.contains(key) ? key! : 'terminal';
  }

  String _profileName() {
    final value = appMetaBox.get('profileName') as String?;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    return 'Set your name';
  }

  String _profileAvatarPath() {
    return (appMetaBox.get('profileAvatar') as String?) ?? '';
  }

  Future<void> _setTheme(String key) async {
    await appMetaBox.put('theme', key);
    _refreshView();
  }

  Future<void> _setProfileName(String name) async {
    await appMetaBox.put('profileName', name.trim());
    _refreshView();
  }

  Future<void> _maybeRunFirstInstallSetup() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (appMetaBox.get('firstSetupDone') == true) return;

      final nameController = TextEditingController(
        text: (appMetaBox.get('profileName') as String?) ?? '',
      );
      String selectedTheme = _currentThemeKey();
      String? errorText;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => StatefulBuilder(
              builder:
                  (dialogContext, setDialogState) => AlertDialog(
                    backgroundColor: const Color(0xFF161B22),
                    title: const Text(
                      'Welcome to Hisaab',
                      style: TextStyle(color: Color(0xFFE6EDF3)),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set your name and preferred theme.',
                            style: TextStyle(color: Color(0xFF8B949E)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Your name',
                              errorText: errorText,
                            ),
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Theme',
                            style: TextStyle(color: Color(0xFF8B949E)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                _themeKeys
                                    .map(
                                      (key) => ChoiceChip(
                                        label: Text(_themeLabel(key)),
                                        selected: selectedTheme == key,
                                        onSelected:
                                            (_) => setDialogState(
                                              () => selectedTheme = key,
                                            ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            setDialogState(
                              () => errorText = 'Name is required',
                            );
                            return;
                          }
                          await _setProfileName(name);
                          await _setTheme(selectedTheme);
                          await appMetaBox.put('firstSetupDone', true);
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Save & Continue'),
                      ),
                    ],
                  ),
            ),
      );

      nameController.dispose();
    });
  }

  Future<void> _editProfileName() async {
    final controller = TextEditingController(
      text: (appMetaBox.get('profileName') as String?) ?? '',
    );
    String? errorText;
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF161B22),
                  title: const Text(
                    'Update name',
                    style: TextStyle(color: Color(0xFFE6EDF3)),
                  ),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      errorText: errorText,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) {
                          setDialogState(
                            () => errorText = 'Name cannot be empty',
                          );
                          return;
                        }
                        Navigator.pop(dialogContext, true);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );

    if (saved == true) {
      await _setProfileName(controller.text.trim());
    }
    controller.dispose();
  }

  Future<void> _editThemePreference() async {
    String selectedTheme = _currentThemeKey();
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF161B22),
                  title: const Text(
                    'Select theme',
                    style: TextStyle(color: Color(0xFFE6EDF3)),
                  ),
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _themeKeys
                            .map(
                              (key) => ChoiceChip(
                                label: Text(_themeLabel(key)),
                                selected: selectedTheme == key,
                                onSelected:
                                    (_) => setDialogState(
                                      () => selectedTheme = key,
                                    ),
                              ),
                            )
                            .toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
    if (saved == true) {
      await _setTheme(selectedTheme);
    }
  }

  Future<void> _changeAppProfilePicture() async {
    final path = await _pickCropAndSaveImage();
    if (path == null || path.isEmpty) return;
    await appMetaBox.put('profileAvatar', path);
    _refreshView();
  }

  Widget _appProfileAvatar({double radius = 28}) {
    final path = _profileAvatarPath();
    try {
      if (path.isNotEmpty) {
        final filePath = path.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
            backgroundColor: const Color(0xFF0D1117),
          );
        }
      }
    } catch (_) {}
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0D1117),
      child: Icon(
        Icons.person,
        size: radius,
        color: const Color(0xFF58A6FF),
      ),
    );
  }
}
