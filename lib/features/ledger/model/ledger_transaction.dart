enum TransactionType {
  add('add'),
  subtract('subtract');

  const TransactionType(this.value);

  final String value;

  static TransactionType fromValue(Object? value) {
    return value == add.value ? add : subtract;
  }
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory LedgerTransaction.fromMap(Map<dynamic, dynamic> map) {
    return LedgerTransaction(
      type: TransactionType.fromValue(map['type']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
    );
  }

  final TransactionType type;
  final double amount;
  final String note;
  final String date;

  double get signedAmount => type == TransactionType.add ? amount : -amount;

  Map<String, Object> toMap() {
    return {'type': type.value, 'amount': amount, 'note': note, 'date': date};
  }
}
