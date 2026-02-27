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
part 'profile_settings.dart';
part 'danger_zone.dart';
part 'home_page.dart';
part 'stats_page.dart';
part 'settings_page.dart';

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
  String _statsFilter = 'monthly';
  DateTimeRange? _customStatsRange;
  final List<String> _themeKeys = const ['terminal', 'dark', 'light'];

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

  void _refreshView() {
    if (!mounted) return;
    setState(() {});
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


  @override
  Widget build(BuildContext context) {
    final title = switch (_currentTab) {
      1 => '> statistics',
      2 => '> settings',
      _ => '> hisaab',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).appBarTheme.foregroundColor,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
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
