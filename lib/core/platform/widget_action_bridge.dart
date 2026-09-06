import 'dart:async';

import 'package:flutter/services.dart';

class WidgetActionBridge {
  WidgetActionBridge._();

  static const MethodChannel _channel = MethodChannel('hisaab/widget');
  static final StreamController<String> _actions =
      StreamController<String>.broadcast();
  static bool _initialized = false;

  static Stream<String> get actions => _actions.stream;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onWidgetAction') return null;
      final action = call.arguments?.toString();
      if (action != null && action.isNotEmpty) {
        _actions.add(action);
      }
      return null;
    });
  }

  static Future<String?> getInitialAction() async {
    try {
      final value = await _channel.invokeMethod<String>('getInitialAction');
      if (value == null || value.isEmpty) return null;
      return value;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateWidgetBalance(double balance) async {
    try {
      await _channel.invokeMethod('updateWidgetBalance', {'balance': balance});
    } on MissingPluginException {
      // Widget platform channel not implemented on current platform
    } catch (_) {
      // Ignore other platform channel errors
    }
  }
}
