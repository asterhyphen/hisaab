import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/features/ledger/data/ledger_repository.dart';
import 'package:hisaab/features/ledger/model/ledger_transaction.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory directory;
  late Box<dynamic> friendsBox;
  late Box<dynamic> userMetaBox;
  late LedgerRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hisaab_test_');
    Hive.init(directory.path);
    friendsBox = await Hive.openBox('friends');
    userMetaBox = await Hive.openBox('user_meta');
    repository = LedgerRepository(
      friendsBox: friendsBox,
      userMetaBox: userMetaBox,
    );
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('returns sorted accounts and calculates the overall balance', () async {
    await repository.addTransaction(
      'Zara',
      const LedgerTransaction(
        type: TransactionType.add,
        amount: 100,
        date: '10-06-2026 10:00 AM',
      ),
    );
    await repository.addTransaction(
      'Aman',
      const LedgerTransaction(
        type: TransactionType.subtract,
        amount: 40,
        date: '10-06-2026 11:00 AM',
      ),
    );

    expect(repository.friendNames, ['Aman', 'Zara']);
    expect(repository.account('Zara').balance, 100);
    expect(repository.account('Aman').balance, -40);
    expect(repository.overallBalance, 60);
  });

  test('keeps the existing Hive map format', () async {
    const transaction = LedgerTransaction(
      type: TransactionType.add,
      amount: 25.5,
      note: 'Tea',
      date: '10-06-2026 12:00 PM',
    );

    await repository.addTransaction('Aman', transaction);

    expect(friendsBox.get('Aman'), [transaction.toMap()]);
  });
}
