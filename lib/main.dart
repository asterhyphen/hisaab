import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/platform/widget_action_bridge.dart';
import 'core/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(HiveBoxes.friends),
    Hive.openBox(HiveBoxes.userMeta),
    Hive.openBox(HiveBoxes.appMeta),
    Hive.openBox(HiveBoxes.trackers),
  ]);
  await WidgetActionBridge.initialize();

  runApp(const ProviderScope(child: HisaabApp()));
}
