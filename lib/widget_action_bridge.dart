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
    final value = await _channel.invokeMethod<String>('getInitialAction');
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
