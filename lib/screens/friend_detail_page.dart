import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendDetailPage extends StatefulWidget {
  final String name;
  FriendDetailPage({required this.name});

  @override
  _FriendDetailPageState createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage>
    with TickerProviderStateMixin {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final box = Hive.box('friendsBox');
  final metaBox = Hive.box('userMetaBox');
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path} (path copied)'),
            action: SnackBarAction(label: 'Share', onPressed: _shareCsv),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<File?> _exportCsvFile() async {
    final txns = box.get(widget.name) as List;
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
        '${widget.name}_transactions_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
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

  Future<void> _setAppUpi() async {
    final appBox = Hive.box('appMetaBox');
    final controller = TextEditingController(
      text: appBox.get('upi') as String? ?? '',
    );
    final ok = await showDialog<bool?>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Set your UPI id'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'example@upi'),
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
      appBox.put('upi', controller.text.trim());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved your UPI')));
    }
  }

  Future<void> _setUserUpi() async {
    final controller = TextEditingController(
      text: metaBox.get('${widget.name}_upi') as String? ?? '',
    );
    final ok = await showDialog<bool?>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Set ${widget.name} UPI id'),
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
      metaBox.put('${widget.name}_upi', controller.text.trim());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved ${widget.name} UPI')));
    }
  }

  String _buildUpiUri(String pa, double amount, {String? pn, String? tn}) {
    final encodedTn = tn == null ? '' : Uri.encodeComponent(tn);
    final namePart = pn == null ? '' : '&pn=${Uri.encodeComponent(pn)}';
    final tnPart = tn == null ? '' : '&tn=$encodedTn';
    return 'upi://pay?pa=${Uri.encodeComponent(pa)}$namePart&am=${amount.toStringAsFixed(2)}&cu=INR$tnPart';
  }

  Future<void> _showRequestPayment(double amount) async {
    final appBox = Hive.box('appMetaBox');
    final upi = (appBox.get('upi') as String?)?.trim();
    if (upi == null || upi.isEmpty) {
      final setNow = await showDialog<bool?>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Set your UPI id'),
              content: Text(
                'You need to set your UPI id to share QR for payment.',
              ),
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
      if (setNow == true) await _setAppUpi();
      return;
    }
    final uri = _buildUpiUri(upi, amount, pn: 'Hisaab', tn: 'Payment');
    final qrData = uri;
    final save = await showDialog<bool?>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Share UPI QR'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      try {
                        final qrCode = QrCode(
                          20, // higher version for longer UPI strings
                          QrErrorCorrectLevel.M,
                        );
                        qrCode.addData(qrData);
                        return CustomPaint(
                          size: const Size.square(200),
                          painter: QrPainter.withQr(
                            qr: qrCode,
                            gapless: true,
                            color: Colors.white,
                            emptyColor: Colors.black,
                          ),
                        );
                      } catch (e) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'QR data too long to encode. Please shorten the UPI details.',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 8),
                  SelectableText(qrData, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save QR'),
              ),
            ],
          ),
    );
    if (save == true) {
      try {
        try {
          final qrCode = QrCode(
            20, // higher version for longer UPI strings
            QrErrorCorrectLevel.M,
          );
          qrCode.addData(qrData);
          final painter = QrPainter.withQr(
            qr: qrCode,
            gapless: true,
            color: Colors.white,
            emptyColor: Colors.black,
          );
          final pic = await painter.toImageData(
            1024,
            format: ui.ImageByteFormat.png,
          );
          if (pic != null) {
            final bytes = pic.buffer.asUint8List();
            final dir = await _getDownloadsDirectory();
            final fname = 'upi_qr_${DateTime.now().millisecondsSinceEpoch}.png';
            final file = File('${dir.path}/$fname');
            await file.writeAsBytes(bytes);
            await Clipboard.setData(ClipboardData(text: uri));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('QR saved to ${file.path} (UPI URI copied)'),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'QR data too long to encode. Please shorten the UPI details.',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } else {
      await Clipboard.setData(ClipboardData(text: uri));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('UPI URI copied to clipboard')));
    }
  }

  Future<void> _payNow(double amount) async {
    final friendUpi = (metaBox.get('${widget.name}_upi') as String?)?.trim();
    if (friendUpi == null || friendUpi.isEmpty) {
      final setNow = await showDialog<bool?>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Set ${widget.name} UPI id'),
              content: Text('You need ${widget.name} UPI id to pay them.'),
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
      pn: widget.name,
      tn: 'Settlement',
    );
    try {
      final launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open UPI app. URI copied.')),
        );
        await Clipboard.setData(ClipboardData(text: uri));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: uri));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open UPI app, URI copied')),
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No transactions to share')));
        return;
      }
      // Copy path to clipboard as a lightweight share fallback.
      await Clipboard.setData(ClipboardData(text: file.path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported file path copied to clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV is empty')));
        return;
      }
      // Expect header with type,amount,note,date
      final header = lines.first.toLowerCase();
      if (!header.contains('type') ||
          !header.contains('amount') ||
          !header.contains('date')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV header missing required columns (type, amount, date)',
            ),
          ),
        );
        return;
      }
      final list = List.from(box.get(widget.name) as List);
      for (var i = 1; i < lines.length; i++) {
        final row = lines[i];
        final cols = _splitCsvLine(row);
        if (cols.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid CSV format on line ${i + 1}')),
          );
          return;
        }
        final typeRaw = cols[0].toLowerCase();
        final type = (typeRaw == 'add' || typeRaw == '+') ? 'add' : 'subtract';
        final amount =
            double.tryParse(cols[1]) ??
            double.tryParse(cols[1].replaceAll('"', ''));
        if (amount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid amount on line ${i + 1}')),
          );
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
      box.put(widget.name, list);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${lines.length - 1} transactions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _pickIcon() async {
    String current = metaBox.get(widget.name) as String? ?? 'terminal';
    await showDialog(
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
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'choose_icon()',
                          style: TextStyle(
                            color: Color(0xFF00D084),
                            fontFamily: 'Courier New',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _iconTile('terminal', Icons.terminal, current, (
                              id,
                            ) {
                              current = id;
                              setDialogState(() {});
                            }),
                            SizedBox(width: 8),
                            _iconTile('code', Icons.code, current, (id) {
                              current = id;
                              setDialogState(() {});
                            }),
                            SizedBox(width: 8),
                            _iconTile('robot', Icons.smart_toy, current, (id) {
                              current = id;
                              setDialogState(() {});
                            }),
                            SizedBox(width: 8),
                            _iconTile('user', Icons.person, current, (id) {
                              current = id;
                              setDialogState(() {});
                            }),
                            SizedBox(width: 8),
                            _iconTile('smile', Icons.emoji_emotions, current, (
                              id,
                            ) {
                              current = id;
                              setDialogState(() {});
                            }),
                            SizedBox(width: 8),
                            // custom image picker
                            GestureDetector(
                              onTap: () async {
                                final saved = await _pickCropAndSaveImage();
                                if (saved != null) {
                                  current = saved;
                                  setDialogState(() {});
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      current.startsWith('/') ||
                                              current.startsWith('file://')
                                          ? Color(0xFF0D1117)
                                          : Color(0xFF161B22),
                                  border: Border.all(
                                    color:
                                        current.startsWith('/') ||
                                                current.startsWith('file://')
                                            ? Color(0xFF00D084)
                                            : Color(0xFF30363D),
                                    width:
                                        current.startsWith('/') ||
                                                current.startsWith('file://')
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
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('cancel'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                try {
                                  metaBox.put(widget.name, current);
                                } catch (_) {}
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: Text('save'),
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
          color: isSelected ? Color(0xFF0D1117) : Color(0xFF161B22),
          border: Border.all(
            color: isSelected ? Color(0xFF00D084) : Color(0xFF30363D),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xFF58A6FF), size: 20),
      ),
    );
  }

  void addTransaction(String type) {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final transaction = {
      'type': type,
      'amount': amount,
      'note': noteController.text.trim(),
      'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
    };

    final list = box.get(widget.name) as List;
    list.add(transaction);
    box.put(widget.name, list);
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

  @override
  Widget build(BuildContext context) {
    final transactions = (box.get(widget.name) as List).reversed.toList();
    final total = getTotal(transactions);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFF00D084),
        elevation: 0,
        title: Text(
          '> ${widget.name}',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Color(0xFF00D084),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share CSV',
            icon: Icon(Icons.share),
            onPressed: _shareCsv,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: Icon(Icons.download_rounded),
            onPressed: _exportCsv,
          ),
          IconButton(
            tooltip: 'Import CSV',
            icon: Icon(Icons.upload_file),
            onPressed: _importCsv,
          ),
          IconButton(
            tooltip: 'Edit icon',
            icon: Icon(Icons.edit),
            onPressed: _pickIcon,
          ),
          IconButton(
            tooltip: 'Delete user',
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: Color(0xFF161B22),
                      title: Text(
                        'Delete user?',
                        style: TextStyle(color: Color(0xFFE6EDF3)),
                      ),
                      content: Text(
                        'Delete ${widget.name} and all transactions?',
                        style: TextStyle(color: Color(0xFF8B949E)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                box.delete(widget.name);
                try {
                  metaBox.delete(widget.name);
                } catch (_) {}
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Balance
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF30363D), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'total_balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B949E),
                      fontFamily: 'Courier New',
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
                      color: total >= 0 ? Color(0xFF3FB950) : Color(0xFFF85149),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (total >= 0)
                        ElevatedButton.icon(
                          onPressed: () => _showRequestPayment(total),
                          icon: Icon(Icons.qr_code),
                          label: Text('Request ₹${total.toStringAsFixed(2)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3FB950),
                            foregroundColor: Color(0xFF0D1117),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _payNow(total.abs()),
                          icon: Icon(Icons.payment),
                          label: Text('Pay ₹${total.abs().toStringAsFixed(2)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF85149),
                            foregroundColor: Color(0xFF0D1117),
                          ),
                        ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          // allow setting app or user upi
                          if (total >= 0) {
                            await _setAppUpi();
                          } else {
                            await _setUserUpi();
                          }
                        },
                        child: Text(
                          total >= 0 ? 'Set my UPI' : 'Set ${widget.name} UPI',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(color: Color(0xFF30363D), height: 0),
          // Transactions List
          Expanded(
            child:
                transactions.isEmpty
                    ? Center(
                      child: Text(
                        'transactions_empty()',
                        style: TextStyle(
                          color: Color(0xFF6E7681),
                          fontSize: 14,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    )
                    : ListView.builder(
                      physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: transactions.length,
                      itemBuilder: (_, index) {
                        final tx = transactions[index];
                        final isAdd = tx['type'] == 'add';
                        final dateStr = _normalizeDate(tx['date']);

                        return AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 200),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF30363D),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950).withOpacity(0.2)
                                          : Color(0xFFF85149).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isAdd ? Icons.add : Icons.remove,
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950)
                                          : Color(0xFFF85149),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${isAdd ? "+" : "-"} ₹${tx['amount']}',
                                style: TextStyle(
                                  fontFamily: 'Courier New',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE6EDF3),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  if (tx['note'].isNotEmpty)
                                    Text(
                                      tx['note'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B949E),
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                  SizedBox(
                                    height: tx['note'].isNotEmpty ? 4 : 0,
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6E7681),
                                      fontFamily: 'Courier New',
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950).withOpacity(0.15)
                                          : Color(0xFFF85149).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAdd ? 'add' : 'remove',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isAdd
                                            ? Color(0xFF3FB950)
                                            : Color(0xFFF85149),
                                    fontFamily: 'Courier New',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.add),
            onPressed: () => showTxnDialog('add'),
            heroTag: "addBtn",
            backgroundColor: Color(0xFF3FB950),
            foregroundColor: Color(0xFF0D1117),
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            label: Text(
              'remove',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.remove),
            onPressed: () => showTxnDialog('subtract'),
            backgroundColor: Color(0xFFF85149),
            foregroundColor: Color(0xFF0D1117),
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
            backgroundColor: Color(0xFF161B22),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF30363D), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type == 'add' ? r'$ add_amount()' : r'$ remove_amount()',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D084),
                      fontFamily: 'Courier New',
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
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: InputDecoration(
                      labelText: 'amount',
                      labelStyle: TextStyle(
                        color: Color(0xFF8B949E),
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
                  SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: InputDecoration(
                      labelText: 'note (optional)',
                      labelStyle: TextStyle(
                        color: Color(0xFF8B949E),
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
                  ),
                  SizedBox(height: 20),
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
                          backgroundColor:
                              type == 'add'
                                  ? Color(0xFF3FB950)
                                  : Color(0xFFF85149),
                          foregroundColor: Color(0xFF0D1117),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'save',
                          style: TextStyle(
                            fontFamily: 'Courier New',
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
