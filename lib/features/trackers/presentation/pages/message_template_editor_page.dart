import 'package:flutter/material.dart';

import '../../../../core/theme/hisaab_typography.dart';

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
  late final TextEditingController _templateCtrl;
  late final TextEditingController _allPaidCtrl;

  @override
  void initState() {
    super.initState();
    _templateCtrl = TextEditingController(text: widget.initialTemplate);
    _allPaidCtrl = TextEditingController(text: widget.initialAllPaidTemplate);
  }

  @override
  void dispose() {
    _templateCtrl.dispose();
    _allPaidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontFamily = context.hisaabFontFamily;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Message Templates',
          style: TextStyle(fontFamily: fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                MessageTemplateEditResult(
                  messageTemplate: _templateCtrl.text,
                  allPaidMessageTemplate: _allPaidCtrl.text,
                ),
              );
            },
            child: Text('Save', style: TextStyle(fontFamily: fontFamily)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            context,
            title: 'Pending Template',
            subtitle: 'Used when at least one person hasn\'t paid yet.',
            child: TextField(
              controller: _templateCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Enter message template...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'All Paid Template',
            subtitle: 'Used when everyone has paid.',
            child: TextField(
              controller: _allPaidCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Enter all-paid template...',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _section(
            context,
            title: 'Available Variables',
            subtitle: 'Copy and paste these into your templates.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const [
                        '{title}',
                        '{status}',
                        '{dueDate}',
                        '{daysRemaining}',
                        '{total}',
                        '{perHead}',
                        '{paidCount}',
                        '{paidAmount}',
                        '{paidUsers}',
                        '{pendingCount}',
                        '{pendingAmount}',
                        '{pendingUsers}',
                      ]
                      .map(
                        (v) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : const Color(0xFFF0F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : const Color(0xFFD9E6EF),
                            ),
                          ),
                          child: Text(
                            v,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final fontFamily = context.hisaabFontFamily;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
