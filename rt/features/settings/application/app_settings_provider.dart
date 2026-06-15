import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/storage/app_box_provider.dart';
import '../domain/app_settings.dart';

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  late final Box<dynamic> _box;

  @override
  AppSettings build() {
    _box = ref.watch(appBoxProvider);
    return AppSettings.fromMap(_box.get('settings'));
  }

  Future<void> save(AppSettings value) async {
    state = value;
    await _box.put('settings', value.toMap());
    await NotificationService.instance.syncForAllTrackers(_box);
  }
}
