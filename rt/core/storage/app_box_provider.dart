import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final appBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box('app');
});
