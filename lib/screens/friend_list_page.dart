import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'friend_detail_page.dart';
import '../widget_action_bridge.dart';

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage>
    with TickerProviderStateMixin {
  final box = Hive.box('friendsBox');
  final metaBox = Hive.box('userMetaBox');
  final appMetaBox = Hive.box('appMetaBox');
  final nameController = TextEditingController();
  final searchController = TextEditingController();
  List<String> displayedKeys = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _selectedIcon = 'terminal';
  StreamSubscription<String>? _widgetActionSubscription;
  int _currentTab = 0;
  static const List<String> _themeKeys = ['terminal', 'dark', 'light'];

  @override
  void initState() {
    super.initState();
    displayedKeys =
        box.keys.cast<String>().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    searchController.addListener(_filterFriends);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _setupWidgetActionFlow();
    _maybeRunFirstInstallSetup();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _widgetActionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupWidgetActionFlow() async {
    _widgetActionSubscription = WidgetActionBridge.actions.listen((action) {
      _consumeWidgetAction(action);
    });
    final initialAction = await WidgetActionBridge.getInitialAction();
    if (initialAction != null) {
      _consumeWidgetAction(initialAction);
    }
  }

  void _consumeWidgetAction(String action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (action != 'add' && action != 'subtract') return;
      _showPersonSelector(action);
    });
  }

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
    if (mounted) setState(() {});
  }

  Future<void> _setProfileName(String name) async {
    await appMetaBox.put('profileName', name.trim());
    if (mounted) setState(() {});
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

  Future<void> _showPersonSelector(String type) async {
    final people =
        box.keys.cast<String>().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users found. Add a user first.')),
      );
      return;
    }

    final person = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            title: Text(
              type == 'add' ? 'Select person for + entry' : 'Select person for - entry',
              style: const TextStyle(color: Color(0xFFE6EDF3)),
            ),
            content: SizedBox(
              width: 360,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: people.length,
                itemBuilder:
                    (context, index) => ListTile(
                      title: Text(
                        people[index],
                        style: const TextStyle(color: Color(0xFFE6EDF3)),
                      ),
                      onTap: () => Navigator.pop(context, people[index]),
                    ),
              ),
            ),
          ),
    );

    if (person == null) return;
    _showQuickTransactionDialog(type: type, person: person);
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
    if (mounted) setState(() {});
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

  Future<void> _showQuickTransactionDialog({
    required String type,
    required String person,
  }) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF161B22),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${type == 'add' ? '+' : '-'} transaction for $person',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D084),
                      fontFamily: 'Courier New',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: const InputDecoration(labelText: 'amount'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: const InputDecoration(labelText: 'note (optional)'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              type == 'add' ? const Color(0xFF3FB950) : const Color(0xFFF85149),
                          foregroundColor: const Color(0xFF0D1117),
                        ),
                        onPressed: () {
                          final amount =
                              double.tryParse(amountController.text.trim()) ?? 0;
                          if (amount <= 0) return;
                          final list = List.from(box.get(person) as List? ?? []);
                          list.add({
                            'type': type,
                            'amount': amount,
                            'note': noteController.text.trim(),
                            'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                          });
                          box.put(person, list);
                          Navigator.pop(context);
                          setState(() {
                            displayedKeys =
                                box.keys.cast<String>().toList()
                                  ..sort(
                                    (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                                  );
                          });
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Saved ${type == 'add' ? '+' : '-'} ₹${amount.toStringAsFixed(2)} for $person',
                              ),
                            ),
                          );
                        },
                        child: const Text('save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    amountController.dispose();
    noteController.dispose();
  }

  void _filterFriends() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedKeys =
          box.keys
              .cast<String>()
              .where((key) => key.toLowerCase().contains(query))
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  void addFriend(String name) {
    if (name.isEmpty) return;

    String formattedName = name
        .trim()
        .split(RegExp(r'\s+'))
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');

    if (formattedName.isEmpty || box.containsKey(formattedName)) return;

    box.put(formattedName, []);
    // save selected icon in metadata box
    try {
      metaBox.put(formattedName, _selectedIcon);
    } catch (_) {}
    nameController.clear();
    _selectedIcon = 'terminal';
    Navigator.pop(context);
    setState(() {
      displayedKeys =
          box.keys.cast<String>().toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  Future<bool?> deleteFriend(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF3D4C3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirm Deletion',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "$name" and all their transactions? This action is non-reversible.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      box.delete(name);
      try {
        metaBox.delete(name);
      } catch (_) {}

      setState(() {
        displayedKeys =
            box.keys.cast<String>().toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }

    return result;
  }

  double calculateTotal(List transactions) {
    return transactions.fold(0.0, (sum, item) {
      return item['type'] == 'add'
          ? sum + item['amount']
          : sum - item['amount'];
    });
  }

  double getOverallTotal() {
    double total = 0.0;
    for (var key in box.keys) {
      final transactions = box.get(key) as List;
      total += calculateTotal(transactions);
    }
    return total;
  }

  Widget _iconChoice(
    String id,
    IconData icon,
    void Function(void Function()) setDialogState,
  ) {
    final isSelected = _selectedIcon == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _selectedIcon = id);
          setDialogState(() {});
        },
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF0D1117) : Color(0xFF161B22),
            border: Border.all(
              color: isSelected ? Color(0xFF00D084) : Color(0xFF30363D),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF58A6FF), size: 20),
        ),
      ),
    );
  }

  List<String> _splitCsvLine(String line) {
    List<String> res = [];
    int i = 0;
    while (i < line.length) {
      if (line[i] == '"') {
        i++;
        final sb = StringBuffer();
        while (i < line.length) {
          if (line[i] == '"' && i + 1 < line.length && line[i + 1] == '"') {
            sb.write('"');
            i += 2;
            continue;
          }
          if (line[i] == '"') {
            i++;
            break;
          }
          sb.write(line[i]);
          i++;
        }
        if (i < line.length && line[i] == ',') i++;
        res.add(sb.toString());
      } else {
        final start = i;
        while (i < line.length && line[i] != ',') i++;
        res.add(line.substring(start, i).trim());
        if (i < line.length && line[i] == ',') i++;
      }
    }
    return res;
  }

  String _normalizeDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    try {
      final dt = DateTime.tryParse(s);
      if (dt != null) return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    } catch (_) {}
    try {
      final n = int.parse(s);
      final dt =
          n.toString().length <= 10
              ? DateTime.fromMillisecondsSinceEpoch(n * 1000)
              : DateTime.fromMillisecondsSinceEpoch(n);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    } catch (_) {}
    final cleaned = s.replaceAll(RegExp(r'\b\d{10,}\b'), '').trim();
    final t = cleaned.replaceAllMapped(
      RegExp(r'(\d{1,2}:\d{2}):\d{2}'),
      (m) => '${m[1]}',
    );
    return t;
  }

  Future<void> _exportAllCsv() async {
    try {
      final keys = box.keys.cast<String>().toList();
      final rows = <String>[];
      rows.add('user,type,amount,note,date');
      for (var user in keys) {
        final txns = box.get(user) as List;
        for (var t in txns) {
          final type = (t['type'] ?? '').toString().replaceAll('"', '""');
          final amount = (t['amount'] ?? '').toString();
          final note = (t['note'] ?? '').toString().replaceAll('"', '""');
          final date = (t['date'] ?? '').toString();
          rows.add('"$user","$type","$amount","$note","$date"');
        }
      }
      final csv = rows.join('\n');
      final dir = await _getDownloadsDirectory();
      final fname =
          'all_transactions_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fname');
      await file.writeAsString(csv);
      await Clipboard.setData(ClipboardData(text: file.path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported all transactions to ${file.path} (path copied)',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) return dirs.first;
      }
      // macOS, Linux, Windows have getDownloadsDirectory
      try {
        final d = await getDownloadsDirectory();
        if (d != null) return d;
      } catch (_) {}
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<String?> _pickCropAndSaveImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();

    // Show crop dialog and get cropped bytes
    final cropped = await showDialog<Uint8List?>(
      context: context,
      builder: (_) {
        final controller = CropController();
        return Dialog(
          backgroundColor: Color(0xFF0D1117),
          child: Container(
            width: 320,
            height: 480,
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Crop(
                    image: bytes,
                    controller: controller,
                    onCropped: (croppedBytes) {
                      Navigator.of(context).pop(croppedBytes);
                    },
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.crop(),
                      child: Text('crop & save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (cropped == null) return null;

    // Save cropped to downloads
    final dir = await _getDownloadsDirectory();
    final fname = 'user_icon_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fname');
    await file.writeAsBytes(cropped);
    return file.path;
  }

  Future<void> _importAllCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final file = File(path);
      final content = await file.readAsString();
      final lines =
          content
              .split(RegExp(r'\r?\n'))
              .where((l) => l.trim().isNotEmpty)
              .toList();
      if (lines.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV is empty')));
        return;
      }
      final header = lines.first.toLowerCase();
      if (!header.contains('user') ||
          !header.contains('type') ||
          !header.contains('amount') ||
          !header.contains('date')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV header missing required columns (user,type,amount,date)',
            ),
          ),
        );
        return;
      }
      int imported = 0;
      for (var i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.length < 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid CSV format on line ${i + 1}')),
          );
          return;
        }
        final user = cols[0];
        final typeRaw = cols[1].toLowerCase();
        final type = (typeRaw == 'add' || typeRaw == '+') ? 'add' : 'subtract';
        final amount =
            double.tryParse(cols[2]) ??
            double.tryParse(cols[2].replaceAll('"', ''));
        if (amount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid amount on line ${i + 1}')),
          );
          return;
        }
        final note = cols[3];
        final date = _normalizeDate(cols[4]);
        final txn = {
          'type': type,
          'amount': amount,
          'note': note,
          'date': date,
        };
        final list = List.from(box.get(user) as List? ?? []);
        list.add(txn);
        box.put(user, list);
        // ensure metadata exists
        try {
          if (metaBox.get(user) == null) metaBox.put(user, 'terminal');
        } catch (_) {}
        imported++;
      }
      setState(() {
        displayedKeys =
            box.keys.cast<String>().toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported transactions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse(
      'https://github.com/asterhyphen/hisaab',
    ); // replace
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch GitHub')));
    }
  }

  Widget _buildHomeBody() {
    return Column(
      children: [
        // Search Bar with terminal style
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontFamily: 'Courier New',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFF0D1117),
              labelText: 'Search user',
              labelStyle: TextStyle(
                color: Color(0xFF8B949E),
                fontFamily: 'Courier New',
              ),
              prefixIcon: Icon(Icons.search, color: Color(0xFF58A6FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF00D084), width: 2),
              ),
            ),
          ),
        ),
        // Total pending with animation
        FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF30363D), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'total_pending: ₹${getOverallTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Courier New',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF58A6FF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        // Friend List
        Expanded(
          child:
              displayedKeys.isEmpty
                  ? Center(
                    child: Text(
                      r'$ user_not_found()' '\n\ntype "+ icon" to create_user()',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6E7681),
                        fontSize: 14,
                        fontFamily: 'Courier New',
                        height: 1.6,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.only(bottom: 100),
                    physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: displayedKeys.length,
                    itemBuilder: (_, index) {
                      final key = displayedKeys.elementAt(index);
                      final transactions = box.get(key) as List;
                      final total = calculateTotal(transactions);
                      bool pressed = false;

                      return StatefulBuilder(
                        builder: (context, setInnerState) {
                          return AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_fadeAnimation.value * 10, 0),
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 70,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                Dismissible(
                                  key: ValueKey(key),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => deleteFriend(key),
                                  background: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 70,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTapDown:
                                        (_) => setInnerState(
                                          () => pressed = true,
                                        ),
                                    onTapUp:
                                        (_) => setInnerState(
                                          () => pressed = false,
                                        ),
                                    onTapCancel:
                                        () => setInnerState(
                                          () => pressed = false,
                                        ),
                                    onTap:
                                        () => Navigator.of(context)
                                            .push(
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (_, animation, __) =>
                                                        FriendDetailPage(
                                                          name: key,
                                                        ),
                                                transitionsBuilder: (
                                                  _,
                                                  animation,
                                                  __,
                                                  child,
                                                ) {
                                                  final tween = Tween(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).chain(
                                                    CurveTween(
                                                      curve:
                                                          Curves.easeInOutCubic,
                                                    ),
                                                  );
                                                  return SlideTransition(
                                                    position: animation.drive(
                                                      tween,
                                                    ),
                                                    child: child,
                                                  );
                                                },
                                                transitionDuration:
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                              ),
                                            )
                                            .then(
                                              (_) => setState(() {
                                                displayedKeys =
                                                    box.keys.cast<String>()
                                                        .toList();
                                              }),
                                            ),
                                    child: AnimatedScale(
                                      scale: pressed ? 0.97 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 70,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF161B22),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                pressed
                                                    ? const Color(0xFF00D084)
                                                    : const Color(0xFF30363D),
                                            width: pressed ? 2 : 1,
                                          ),
                                          boxShadow:
                                              pressed
                                                  ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF00D084,
                                                      ).withOpacity(0.3),
                                                      blurRadius: 8,
                                                    ),
                                                  ]
                                                  : [],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: const Color(
                                                    0xFF0D1117,
                                                  ),
                                                  child: Builder(
                                                    builder: (c) {
                                                      final iconKey =
                                                          metaBox.get(key)
                                                              as String? ??
                                                          'terminal';

                                                      try {
                                                        if (iconKey.startsWith(
                                                              '/',
                                                            ) ||
                                                            iconKey.startsWith(
                                                              'file://',
                                                            )) {
                                                          final path = iconKey
                                                              .replaceFirst(
                                                                'file://',
                                                                '',
                                                              );
                                                          final f = File(path);
                                                          if (f.existsSync()) {
                                                            return ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              child: Image.file(
                                                                f,
                                                                width: 36,
                                                                height: 36,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (_) {}

                                                      switch (iconKey) {
                                                        case 'code':
                                                          return const Icon(
                                                            Icons.code,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'robot':
                                                          return const Icon(
                                                            Icons.smart_toy,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'user':
                                                          return const Icon(
                                                            Icons.person,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'smile':
                                                          return const Icon(
                                                            Icons
                                                                .emoji_emotions,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        default:
                                                          return const Icon(
                                                            Icons.terminal,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      key,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFFE6EDF3,
                                                        ),
                                                        fontFamily:
                                                            'Courier New',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'balance: ₹${total.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontFamily:
                                                            'Courier New',
                                                        color:
                                                            total >= 0
                                                                ? const Color(
                                                                  0xFF3FB950,
                                                                )
                                                                : const Color(
                                                                  0xFFF85149,
                                                                ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF6E7681),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
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
      ],
    );
  }

  Widget _buildAddUserFab() {
    return FloatingActionButton(
      backgroundColor: Color(0xFF00D084),
      foregroundColor: Color(0xFF0D1117),
      child: Icon(Icons.add, size: 28),
      elevation: 2,
      onPressed:
          () => showDialog(
            context: context,
            builder:
                (_) => StatefulBuilder(
                  builder:
                      (context, setDialogState) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Color(0xFF161B22),
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF30363D),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r'$ add_user()',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00D084),
                                  fontFamily: 'Courier New',
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _iconChoice(
                                    'terminal',
                                    Icons.terminal,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice('code', Icons.code, setDialogState),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'robot',
                                    Icons.smart_toy,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice('user', Icons.person, setDialogState),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'smile',
                                    Icons.emoji_emotions,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final saved =
                                            await _pickCropAndSaveImage();
                                        if (saved != null) {
                                          setState(() => _selectedIcon = saved);
                                          setDialogState(() {});
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              (_selectedIcon.startsWith('/') ||
                                                      _selectedIcon.startsWith(
                                                        'file://',
                                                      ))
                                                  ? Color(0xFF0D1117)
                                                  : Color(0xFF161B22),
                                          border: Border.all(
                                            color:
                                                (_selectedIcon.startsWith('/') ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? Color(0xFF00D084)
                                                    : Color(0xFF30363D),
                                            width:
                                                (_selectedIcon.startsWith('/') ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? 2
                                                    : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color: Color(0xFF58A6FF),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: nameController,
                                style: TextStyle(
                                  color: Color(0xFFE6EDF3),
                                  fontFamily: 'Courier New',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'name_',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6E7681),
                                    fontFamily: 'Courier New',
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF0D1117),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF30363D),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF30363D),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF00D084),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                autofocus: true,
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: Text(
                                      'cancel',
                                      style: TextStyle(
                                        color: Color(0xFF8B949E),
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF00D084),
                                      foregroundColor: Color(0xFF0D1117),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'create',
                                      style: TextStyle(
                                        fontFamily: 'Courier New',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed:
                                        () =>
                                            addFriend(nameController.text.trim()),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_currentTab) {
      1 => '> statistics',
      2 => '> settings',
      _ => '> hisaab',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFF00D084),
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF00D084),
          ),
        ),
        centerTitle: false,
      ),
      body: switch (_currentTab) {
        1 => _buildStatisticsBody(),
        2 => _buildSettingsBody(),
        _ => _buildHomeBody(),
      },
      floatingActionButton: _currentTab == 0 ? _buildAddUserFab() : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF00D084),
        unselectedItemColor: const Color(0xFF8B949E),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
