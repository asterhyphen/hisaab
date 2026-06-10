import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../model/app_profile.dart';

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>((
  ref,
) {
  return AppPreferencesRepository(Hive.box(HiveBoxes.appMeta));
});

final themeKeyProvider = StreamProvider<String>((ref) async* {
  final repository = ref.watch(appPreferencesRepositoryProvider);
  yield repository.themeKey;
  yield* repository.watchTheme();
});

class AppPreferencesRepository {
  AppPreferencesRepository(this.box);

  final Box<dynamic> box;

  String get themeKey {
    final value = box.get('theme');
    return value is String ? value : 'terminal';
  }

  AppProfile get profile {
    return AppProfile(
      name: (box.get('profileName') as String?)?.trim() ?? '',
      avatarPath: (box.get('profileAvatar') as String?) ?? '',
      themeKey: themeKey,
    );
  }

  Stream<String> watchTheme() {
    return box.watch(key: 'theme').map((_) => themeKey);
  }
}
