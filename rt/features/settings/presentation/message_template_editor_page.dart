import 'package:flutter/material.dart';

import '../domain/app_settings.dart';

class MessageTemplateEditResult {
  final String messageTemplate;
  final String allPaidMessageTemplate;

  const MessageTemplateEditResult({
    required this.messageTemplate,
    required this.allPaidMessageTemplate,
  });
}

class MessageTemplateEditorPage extends StatefulWidget {
  final String initialTemplate;
  final String initialAllPaidTemplate;

  const MessageTemplateEditorPage({
    super.key,
    required this.initialTemplate,
    required this.initialAllPaidTemplate,
  });

  @override
  State<MessageTemplateEditorPage> createState() =>
      _MessageTemplateEditorPageState();
}

class _MessageTemplateEditorPageState extends State<MessageTemplateEditorPage> {
  late final TextEditingController _controller;
  late final TextEditingController _allPaidController;
  late final String _initialTemplate;
  late final String _initialAllPaidTemplate;

  static const _placeholders = [
    ('{title}', 'Tracker title'),
    ('{status}', 'Payment status'),
    ('{dueDate}', 'Due date in day/month/year'),
    ('{daysRemaining}', 'Days left until due date'),
    ('{total}', 'Total amount'),
    ('{perHead}', 'Amount per user'),
    ('{paidCount}', 'Number of paid users'),
    ('{paidAmount}', 'Collected amount'),
    ('{paidUsers}', 'Paid user list, one per line'),
    ('{pendingCount}', 'Number of pending users'),
    ('{pendingAmount}', 'Pending amount'),
    ('{pendingUsers}', 'Pending user list, one per line'),
  ];

  static const _formattingRules = [
    ('`*text*`', 'Bold text in WhatsApp-style markdown'),
    ('`_text_`', 'Italic text'),
    ('```\ntext\n```', 'Code block on multiple lines'),
    ('`\\n`', 'Use a new line by pressing enter in the editor'),
  ];

  @override
  void initState() {
    super.initState();
    _initialTemplate = widget.initialTemplate;
    _initialAllPaidTemplate = widget.initialAllPaidTemplate;
    _controller = TextEditingController(text: widget.initialTemplate);
    _allPaidController = TextEditingController(
      text: widget.initialAllPaidTemplate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _allPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_hasUnsavedChanges) return;
        final shouldDiscard = await _confirmDiscardChanges();
        if (shouldDiscard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasUnsavedChanges) {
                Navigator.pop(context);
                return;
              }

              final shouldDiscard = await _confirmDiscardChanges();
              if (shouldDiscard == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text('Edit Message Template'),
          actions: [
            TextButton(
              onPressed: () {
                _controller.text = AppSettings.defaultMessageTemplate;
                _allPaidController.text =
                    AppSettings.defaultAllPaidMessageTemplate;
                setState(() {});
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF10192B), Color(0xFF090F1B)]
                  : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(
                  title: 'Pending Template',
                  child: TextField(
                    controller: _controller,
                    minLines: 10,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Share message when payments are pending',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'All Paid Template',
                  child: TextField(
                    controller: _allPaidController,
                    minLines: 8,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Share message when everyone has paid',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Placeholders',
                  child: Column(
                    children: _placeholders
                        .map((item) => _HelpRow(left: item.$1, right: item.$2))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Formatting Rules',
                  child: Column(
                    children: _formattingRules
                        .map((item) => _HelpRow(left: item.$1, right: item.$2))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Tips',
                  child: Text(
                    'You can mix placeholders with formatting. Example: `*_{title}_*` makes the tracker title bold and italic. Keep placeholders exactly as shown, including the curly braces.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pop(
              context,
              MessageTemplateEditResult(
                messageTemplate: _controller.text,
                allPaidMessageTemplate: _allPaidController.text,
              ),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Template'),
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges =>
      _controller.text != _initialTemplate ||
      _allPaidController.text != _initialAllPaidTemplate;

  Future<bool?> _confirmDiscardChanges() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'Are you sure you want to go back? Your edits will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.065)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFD9E6EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String left;
  final String right;

  const _HelpRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              left,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
