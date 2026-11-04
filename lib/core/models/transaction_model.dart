class TransactionModel {
  final String? id; // UUID gerado pelo Supabase
  final double amount;
  final String method;
  final double fee;
  final DateTime date;

  /// 'pending' quando a cobrança é criada; 'paid' somente quando o
  /// provedor de pagamento confirma (via webhook no servidor).
  final String status;

  TransactionModel({
    this.id,
    required this.amount,
    required this.method,
    required this.fee,
    required this.date,
    this.status = 'pending',
  });

  bool get isPaid => status == 'paid';

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'method': method,
      'fee': fee,
      // id, user_id, status e created_at são definidos pelo banco.
    };
  }

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toString(),
      amount: _toDouble(map['amount']),
      method: (map['method'] ?? '').toString(),
      fee: _toDouble(map['fee']),
      date: DateTime.parse(map['created_at'].toString()).toLocal(),
      status: (map['status'] ?? 'pending').toString(),
    );
  }
}
