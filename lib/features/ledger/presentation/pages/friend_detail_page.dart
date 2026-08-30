import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/hisaab_typography.dart';
import '../../../../core/widgets/glass_alert.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../settings/data/app_preferences_repository.dart';
import '../../data/ledger_repository.dart';
import '../../../../core/platform/widget_action_bridge.dart';

class FriendDetailPage extends ConsumerStatefulWidget {
  final String name;
  const FriendDetailPage({required this.name, super.key});

  @override
  ConsumerState<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends ConsumerState<FriendDetailPage>
    with TickerProviderStateMixin {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  LedgerRepository get _ledgerRepository => ref.read(ledgerRepositoryProvider);
  AppPreferencesRepository get _preferencesRepository =>
      ref.read(appPreferencesRepositoryProvider);
  get box => _ledgerRepository.friendsBox;
  get metaBox => _ledgerRepository.userMetaBox;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _deleteTransactionDialogOpen = false;
  late String _currentName;

  Future<void> _updateWidgetBalance() async {
    final total = _ledgerRepository.overallBalance;
    await WidgetActionBridge.updateWidgetBalance(total);
  }

  Future<void> _markPaidAll(double total) async {
    if (total == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Clear balance?'),
            content: Text(
              'This will mark the full amount as settled and bring the balance to ₹0.00.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Paid all'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final txns = List.from(box.get(_currentName) as List);

      txns.add({
        'type': total > 0 ? 'subtract' : 'add',
        'amount': total.abs(),
        'note': 'Paid all / Settled',
        'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
      });

      box.put(_currentName, txns);
      await _updateWidgetBalance();
      setState(() {});
      GlassAlert.showSuccess(context, 'Balance cleared');
    } catch (e) {
      GlassAlert.showError(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _editTransaction(int index) async {
    final txns = box.get(_currentName) as List;
    final tx = txns[index];

    final amountCtrl = TextEditingController(text: tx['amount'].toString());
    final noteCtrl = TextEditingController(text: tx['note'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit transaction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newAmt = double.tryParse(amountCtrl.text) ?? 0;
                  if (newAmt <= 0) return;
                  tx['amount'] = newAmt;
                  tx['note'] = noteCtrl.text.trim();
                  tx['date'] = DateFormat(
                    'dd-MM-yyyy hh:mm a',
                  ).format(DateTime.now());
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true) {
      txns[index] = tx;
      await box.put(_currentName, txns);
      await _updateWidgetBalance();
      setState(() {});
      GlassAlert.showSuccess(context, 'Transaction updated');
    }
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _deleteTransaction(int index) async {
    final txns = box.get(_currentName) as List;
    if (index < 0 || index >= txns.length) return;

    final tx = txns[index];

    final shouldAffectBalance = await showDialog<bool?>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              'Should this deletion affect the balance? If YES, the balance will be recalculated without this transaction. If NO, only the record is removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Remove record only'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Affect balance'),
              ),
            ],
          ),
    );

    if (shouldAffectBalance != null) {
      try {
        txns.removeAt(index);

        if (shouldAffectBalance) {
          await box.put(_currentName, txns);
        } else {
          txns.add({
            'type': tx['type'] == 'add' ? 'subtract' : 'add',
            'amount': tx['amount'],
            'note': '[Reversed] ${tx['note']}',
            'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
          });
          await box.put(_currentName, txns);
        }

        await _updateWidgetBalance();
        setState(() {});
        GlassAlert.showSuccess(context, 'Transaction deleted');
      } catch (e) {
        GlassAlert.showError(context, 'Error deleting: ${e.toString()}');
      }
    }
  }

  Future<bool> _confirmDeleteTransactionDismiss(int index) async {
    if (_deleteTransactionDialogOpen) return false;

    _deleteTransactionDialogOpen = true;
    try {
      await _deleteTransaction(index);
    } finally {
      _deleteTransactionDialogOpen = false;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
    _slideController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    try {
      final file = await _exportCsvFile();
      if (file != null) {
        // copy path to clipboard for convenience and show share action
        await Clipboard.setData(ClipboardData(text: file.path));
        GlassAlert.showInfo(
          context,
          'Exported to ${file.path} (path copied)',
          actionLabel: 'Share',
          onAction: _shareCsv,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      GlassAlert.showError(context, 'Export failed: $e');
    }
  }

  Future<File?> _exportCsvFile() async {
    final txns = box.get(_currentName) as List;
    if (txns.isEmpty) return null;

    final header = 'type,amount,note,date\n';
    final csvLines = txns
        .map((t) {
          final type = (t['type'] ?? '').toString();
          final amount = (t['amount'] ?? '').toString();
          final note = (t['note'] ?? '').toString().replaceAll('"', '""');
          final date = (t['date'] ?? '').toString();
          return '"$type","$amount","$note","$date"';
        })
        .join('\n');

    final csv = header + csvLines;
    final dir = await _getDownloadsDirectory();
    final fname =
        '${_currentName}_transactions_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fname');
    await file.writeAsString(csv);
    return file;
  }

  Future<Directory> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) return dirs.first;
      }
      try {
        final d = await getDownloadsDirectory();
        if (d != null) return d;
      } catch (_) {}
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return await getApplicationDocumentsDirectory();
    }
  }

  String _normalizeDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    // Try ISO parse
    try {
      final dt = DateTime.tryParse(s);
      if (dt != null) return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    } catch (_) {}
    // If numeric (seconds or milliseconds)
    try {
      final n = int.parse(s);
      final dt =
          n.toString().length <= 10
              ? DateTime.fromMillisecondsSinceEpoch(n * 1000)
              : DateTime.fromMillisecondsSinceEpoch(n);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    } catch (_) {}
    // Try to remove long epoch-like numbers and common seconds
    final cleaned = s.replaceAll(RegExp(r'\b\d{10,}\b'), '').trim();
    // If contains seconds like HH:MM:SS, remove seconds
    final t = cleaned.replaceAllMapped(
      RegExp(r'(\d{1,2}:\d{2}):\d{2}'),
      (m) => '${m[1]}',
    );
    return t;
  }

  Future<void> _setUserUpi() async {
    final controller = TextEditingController(
      text: metaBox.get('${_currentName}_upi') as String? ?? '',
    );
    final ok = await showDialog<bool?>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Set $_currentName UPI id'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'friend@upi'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await metaBox.put('${_currentName}_upi', controller.text.trim());
      GlassAlert.showSuccess(context, 'Saved $_currentName UPI');
    }
  }

  String _buildUpiUri(
    String pa,
    double amount, {
    required String pn,
    String tn = 'Payment',
  }) {
    final tr = DateTime.now().millisecondsSinceEpoch.toString();

    return 'upi://pay'
        '?pa=${Uri.encodeComponent(pa)}'
        '&pn=${Uri.encodeComponent(pn)}'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(tn)}'
        '&tr=$tr'
        '&mode=02';
  }

  Future<void> _showRequestPayment(double amount) async {
    final appBox = _preferencesRepository.box;
    final upi = (appBox.get('upi') as String?)?.trim();
    if (upi == null || upi.isEmpty) {
      GlassAlert.showInfo(
        context,
        'Please set your UPI ID in Settings to generate a QR.',
      );
      return;
    }
    final uri = _buildUpiUri(upi, amount, pn: 'Hisaab', tn: 'Payment');

    final repaintKey = GlobalKey();

    /// Renders the repaint boundary to a PNG byte list.
    Future<Uint8List?> _captureQr() async {
      final boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    }

    final save = await showDialog<bool?>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Share UPI QR'),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(dialogContext, null),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // QR + center overlay
                  Builder(
                    builder: (context) {
                      try {
                        final qrCode = QrCode(
                          20,
                          QrErrorCorrectLevel
                              .H, // H = 30% recovery for logo overlay
                        );
                        qrCode.addData(uri);

                        final avatarPath =
                            (appBox.get('profileAvatar') as String?) ?? '';
                        final hasCustomAvatar =
                            avatarPath.isNotEmpty &&
                            File(
                              avatarPath.replaceFirst('file://', ''),
                            ).existsSync();

                        Widget centerWidget;
                        if (hasCustomAvatar) {
                          centerWidget = CircleAvatar(
                            radius: 24,
                            backgroundImage: FileImage(
                              File(avatarPath.replaceFirst('file://', '')),
                            ),
                            backgroundColor: Colors.white,
                          );
                        } else {
                          // App icon fallback
                          centerWidget = CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icon.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Icon(
                                      Icons.payments_outlined,
                                      size: 28,
                                      color: Colors.black87,
                                    ),
                              ),
                            ),
                          );
                        }

                        return RepaintBoundary(
                          key: repaintKey,
                          child: Container(
                            color: Colors.black,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size.square(200),
                                  painter: QrPainter.withQr(
                                    qr: qrCode,
                                    gapless: true,
                                    color: Colors.white,
                                    emptyColor: Colors.black,
                                  ),
                                ),
                                // White ring behind the icon for contrast
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                centerWidget,
                              ],
                            ),
                          ),
                        );
                      } catch (e) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'QR data too long to encode. Please shorten the UPI details.',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SelectableText(uri, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: uri));
                  if (dialogContext.mounted) {
                    GlassAlert.showInfo(
                      dialogContext,
                      'UPI URI copied to clipboard',
                    );
                    Navigator.pop(dialogContext, null);
                  }
                },
                child: const Text('Copy URI'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final bytes = await _captureQr();
                    if (bytes == null) return;
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/upi_request.png');
                    await file.writeAsBytes(bytes);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text:
                          '₹${amount.toStringAsFixed(2)} pending\nScan to pay via UPI',
                    );
                  } catch (e) {
                    if (dialogContext.mounted) {
                      GlassAlert.showError(dialogContext, 'Share failed');
                    }
                  }
                },
                child: const Text('Share'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save QR'),
              ),
            ],
          ),
    );

    if (save == true) {
      try {
        final bytes = await _captureQr();
        if (bytes != null) {
          final dir = await _getDownloadsDirectory();
          final fname = 'upi_qr_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File('${dir.path}/$fname');
          await file.writeAsBytes(bytes);
          await Clipboard.setData(ClipboardData(text: uri));
          GlassAlert.showSuccess(
            context,
            'QR saved to ${file.path} (UPI URI copied)',
          );
        }
      } catch (e) {
        GlassAlert.showError(context, 'Save failed: $e');
      }
    }
  }

  Future<void> _payNow(double amount) async {
    final friendUpi = (metaBox.get('${_currentName}_upi') as String?)?.trim();
    if (friendUpi == null || friendUpi.isEmpty) {
      final setNow = await showDialog<bool?>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Set $_currentName UPI id'),
              content: Text('You need $_currentName UPI id to pay them.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Set now'),
                ),
              ],
            ),
      );
      if (setNow == true) await _setUserUpi();
      return;
    }
    final uri = _buildUpiUri(
      friendUpi,
      amount,
      pn: _currentName,
      tn: 'Settlement',
    );
    try {
      final launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        GlassAlert.showInfo(context, 'Could not open UPI app. URI copied.');
        await Clipboard.setData(ClipboardData(text: uri));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: uri));
      GlassAlert.showInfo(context, 'Failed to open UPI app, URI copied');
    }
  }

  Future<String?> _pickCropAndSaveImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();

    final cropped = await showDialog<Uint8List?>(
      context: context,
      builder: (_) {
        final controller = CropController();
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final dir = await _getDownloadsDirectory();
    final fname = 'user_icon_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fname');
    await file.writeAsBytes(cropped);
    return file.path;
  }

  Future<void> _shareCsv() async {
    try {
      final file = await _exportCsvFile();
      if (file == null) {
        GlassAlert.showInfo(context, 'No transactions to share');
        return;
      }
      // Copy path to clipboard as a lightweight share fallback.
      await Clipboard.setData(ClipboardData(text: file.path));
      GlassAlert.showInfo(context, 'Exported file path copied to clipboard');
    } catch (e) {
      GlassAlert.showError(context, 'Share failed: $e');
    }
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
        // skip comma
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

  Future<void> _importCsv() async {
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
        GlassAlert.showInfo(context, 'CSV is empty');
        return;
      }
      // Expect header with type,amount,note,date
      final header = lines.first.toLowerCase();
      if (!header.contains('type') ||
          !header.contains('amount') ||
          !header.contains('date')) {
        GlassAlert.showError(
          context,
          'CSV header missing required columns (type, amount, date)',
        );
        return;
      }
      final list = List.from(box.get(_currentName) as List? ?? []);
      for (var i = 1; i < lines.length; i++) {
        final row = lines[i];
        final cols = _splitCsvLine(row);
        if (cols.length < 4) {
          GlassAlert.showError(context, 'Invalid CSV format on line ${i + 1}');
          return;
        }
        final typeRaw = cols[0].toLowerCase();
        final type = (typeRaw == 'add' || typeRaw == '+') ? 'add' : 'subtract';
        final amount =
            double.tryParse(cols[1]) ??
            double.tryParse(cols[1].replaceAll('"', ''));
        if (amount == null) {
          GlassAlert.showError(context, 'Invalid amount on line ${i + 1}');
          return;
        }
        final note = cols[2];
        final date = _normalizeDate(cols[3]);
        final txn = {
          'type': type,
          'amount': amount,
          'note': note,
          'date': date,
        };
        list.add(txn);
      }
      await box.put(_currentName, list);
      await _updateWidgetBalance();
      setState(() {});
      GlassAlert.showSuccess(
        context,
        'Imported ${lines.length - 1} transactions',
      );
    } catch (e) {
      GlassAlert.showError(context, 'Import failed: $e');
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _currentName);
    String selectedIcon = metaBox.get(_currentName) as String? ?? 'terminal';

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'edit_profile()',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: context.hisaabFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameCtrl,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: context.hisaabFontFamily,
                          ),
                          decoration: InputDecoration(
                            labelText: 'User Name',
                            labelStyle: TextStyle(
                              fontFamily: context.hisaabFontFamily,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'choose_icon()',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: context.hisaabFontFamily,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _iconTile(
                              'terminal',
                              Icons.terminal,
                              selectedIcon,
                              (id) {
                                selectedIcon = id;
                                setDialogState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            _iconTile('code', Icons.code, selectedIcon, (id) {
                              selectedIcon = id;
                              setDialogState(() {});
                            }),
                            const SizedBox(width: 8),
                            _iconTile('robot', Icons.smart_toy, selectedIcon, (
                              id,
                            ) {
                              selectedIcon = id;
                              setDialogState(() {});
                            }),
                            const SizedBox(width: 8),
                            _iconTile('user', Icons.person, selectedIcon, (id) {
                              selectedIcon = id;
                              setDialogState(() {});
                            }),
                            const SizedBox(width: 8),
                            _iconTile(
                              'smile',
                              Icons.emoji_emotions,
                              selectedIcon,
                              (id) {
                                selectedIcon = id;
                                setDialogState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final saved = await _pickCropAndSaveImage();
                                if (saved != null) {
                                  selectedIcon = saved;
                                  setDialogState(() {});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      selectedIcon.startsWith('/') ||
                                              selectedIcon.startsWith('file://')
                                          ? Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor
                                          : Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                  border: Border.all(
                                    color:
                                        selectedIcon.startsWith('/') ||
                                                selectedIcon.startsWith(
                                                  'file://',
                                                )
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                    width:
                                        selectedIcon.startsWith('/') ||
                                                selectedIcon.startsWith(
                                                  'file://',
                                                )
                                            ? 2
                                            : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final newName = nameCtrl.text.trim();
                                if (newName.isEmpty) {
                                  GlassAlert.showError(
                                    context,
                                    'Name cannot be empty',
                                  );
                                  return;
                                }

                                final oldName = _currentName;
                                if (newName != oldName) {
                                  if (box.containsKey(newName)) {
                                    GlassAlert.showError(
                                      context,
                                      'A user named "$newName" already exists',
                                    );
                                    return;
                                  }

                                  // Rename logic!
                                  try {
                                    final txs = box.get(oldName);
                                    await box.put(newName, txs);
                                    await box.delete(oldName);

                                    // Move avatar icon metadata
                                    final icon = metaBox.get(oldName);
                                    if (icon != null) {
                                      await metaBox.put(newName, icon);
                                      await metaBox.delete(oldName);
                                    }

                                    // Move UPI metadata
                                    final upi = metaBox.get('${oldName}_upi');
                                    if (upi != null) {
                                      await metaBox.put('${newName}_upi', upi);
                                      await metaBox.delete('${oldName}_upi');
                                    }

                                    _currentName = newName;
                                  } catch (e) {
                                    GlassAlert.showError(
                                      context,
                                      'Error renaming user: $e',
                                    );
                                    return;
                                  }
                                }

                                // Save the icon
                                try {
                                  await metaBox.put(_currentName, selectedIcon);
                                } catch (_) {}

                                setState(() {});
                                Navigator.pop(context);
                                GlassAlert.showSuccess(
                                  context,
                                  'Profile updated',
                                );
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _iconTile(
    String id,
    IconData icon,
    String current,
    void Function(String) onSelect,
  ) {
    final isSelected = id == current;
    return GestureDetector(
      onTap: () => onSelect(id),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 20,
        ),
      ),
    );
  }

  void addTransaction(String type) async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final transaction = {
      'type': type,
      'amount': amount,
      'note': noteController.text.trim(),
      'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
    };

    final list = box.get(_currentName) as List;
    list.add(transaction);
    await box.put(_currentName, list);
    await _updateWidgetBalance();
    amountController.clear();
    noteController.clear();
    Navigator.pop(context);
    setState(() {});
  }

  double getTotal(List txns) {
    return txns.fold(
      0.0,
      (sum, item) =>
          item['type'] == 'add' ? sum + item['amount'] : sum - item['amount'],
    );
  }

  Future<void> _deleteUserAction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Delete user?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              'Delete $_currentName and all transactions?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      box.delete(_currentName);
      try {
        metaBox.delete(_currentName);
      } catch (_) {}
      try {
        metaBox.delete('${_currentName}_upi');
      } catch (_) {}
      await _updateWidgetBalance();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions =
        (box.get(_currentName) as List? ?? []).reversed.toList();
    final total = getTotal(transactions);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          '> $_currentName',
          style: TextStyle(
            fontFamily: context.hisaabFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditProfileDialog();
                  break;
                case 'export':
                  _exportCsv();
                  break;
                case 'import':
                  _importCsv();
                  break;
                case 'delete':
                  _deleteUserAction();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Edit Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Export CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Import CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete User',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Total Balance
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: context.hisaabFontFamily,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: context.hisaabFontFamily,
                        color:
                            total >= 0
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (total >= 0)
                              ElevatedButton.icon(
                                onPressed: () => _showRequestPayment(total),
                                icon: const Icon(Icons.qr_code),
                                label: Text(
                                  'Request ₹${total.toStringAsFixed(2)}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.tertiary,
                                  foregroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => _payNow(total.abs()),
                                icon: const Icon(Icons.payment),
                                label: Text(
                                  'Pay ₹${total.abs().toStringAsFixed(2)}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  foregroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                              ),
                            if (total != 0) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _markPaidAll(total),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                child: const Text('Paid all'),
                              ),
                            ],
                            if (total < 0) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  await _setUserUpi();
                                },
                                child: Text('Set $_currentName UPI'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              color: Theme.of(context).colorScheme.outline,
              height: 0,
            ),
          ),
          // Transactions List
          if (transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'transactions_empty()',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontFamily: context.hisaabFontFamily,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = transactions[index];
                  final sourceIndex = transactions.length - 1 - index;
                  final isAdd = tx['type'] == 'add';
                  final dateStr = _normalizeDate(tx['date']);

                  return AnimatedSlide(
                    offset: Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Dismissible(
                      key: ValueKey(
                        'tx_${tx['type']}_${tx['amount']}_${tx['date']}_$sourceIndex',
                      ),
                      direction: DismissDirection.endToStart,
                      dismissThresholds: const {
                        DismissDirection.endToStart: 0.75,
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss:
                          (_) => _confirmDeleteTransactionDismiss(sourceIndex),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _editTransaction(sourceIndex),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isAdd
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.tertiary.withOpacity(0.2)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isAdd ? Icons.add : Icons.remove,
                                color:
                                    isAdd
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '${isAdd ? "+" : "-"} ₹${tx['amount']}',
                              style: TextStyle(
                                fontFamily: context.hisaabFontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontFamily: context.hisaabFontFamily,
                                  ),
                                ),
                                if (tx['note'] != null &&
                                    tx['note']
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tx['note'].toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                      fontFamily: context.hisaabFontFamily,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: transactions.length),
              ),
            ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            label: Text(
              'add',
              style: TextStyle(
                fontFamily: context.hisaabFontFamily,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.add),
            onPressed: () => showTxnDialog('add'),
            heroTag: "addBtn",
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            label: Text(
              'remove',
              style: TextStyle(
                fontFamily: context.hisaabFontFamily,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.remove),
            onPressed: () => showTxnDialog('subtract'),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
            heroTag: "subtractBtn",
          ),
        ],
      ),
    );
  }

  void showTxnDialog(String type) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type == 'add' ? r'$ add_amount()' : r'$ remove_amount()',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: context.hisaabFontFamily,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: context.hisaabFontFamily,
                    ),
                    decoration: InputDecoration(
                      labelText: 'amount',
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: context.hisaabFontFamily,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: context.hisaabFontFamily,
                    ),
                    decoration: InputDecoration(
                      labelText: 'note (optional)',
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: context.hisaabFontFamily,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(
                          'cancel',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontFamily: context.hisaabFontFamily,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              type == 'add'
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'save',
                          style: TextStyle(
                            fontFamily: context.hisaabFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => addTransaction(type),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
