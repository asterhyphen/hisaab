import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../model/friend_account.dart';
import '../model/ledger_transaction.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(
    friendsBox: Hive.box(HiveBoxes.friends),
    userMetaBox: Hive.box(HiveBoxes.userMeta),
  );
});

class LedgerRepository {
  LedgerRepository({required this.friendsBox, required this.userMetaBox});

  final Box<dynamic> friendsBox;
  final Box<dynamic> userMetaBox;

  List<String> get friendNames {
    return friendsBox.keys.cast<String>().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  FriendAccount account(String name) {
    final rawTransactions = List<dynamic>.from(
      friendsBox.get(name) as List? ?? const [],
    );
    return FriendAccount(
      name: name,
      transactions: rawTransactions
          .whereType<Map<dynamic, dynamic>>()
          .map(LedgerTransaction.fromMap)
          .toList(growable: false),
    );
  }

  double get overallBalance {
    return friendNames.fold(0, (total, name) => total + account(name).balance);
  }

  Future<void> addTransaction(
    String name,
    LedgerTransaction transaction,
  ) async {
    final transactions = List<dynamic>.from(
      friendsBox.get(name) as List? ?? const [],
    )..add(transaction.toMap());
    await friendsBox.put(name, transactions);
  }
}
