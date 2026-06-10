import 'ledger_transaction.dart';

class FriendAccount {
  const FriendAccount({required this.name, required this.transactions});

  final String name;
  final List<LedgerTransaction> transactions;

  double get balance {
    return transactions.fold(0, (total, item) => total + item.signedAmount);
  }
}
