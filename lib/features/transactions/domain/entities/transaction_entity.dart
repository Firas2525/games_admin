class TransactionEntity {
  final String id;
  final String userName;
  final String userEmail;
  final String? adminName;
  final String type; // 'deposit', 'deduction', 'purchase'
  final double amount; // ما دفعه المستخدم
  final double costPrice; // سعر التكلفة الأصلي
  final double profit; // الربح
  final String productName;
  final String targetId;
  final String orderId;
  final double previousBalance;
  final double newBalance;
  final String currency;
  final String note;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.userName,
    required this.userEmail,
    this.adminName,
    required this.type,
    required this.amount,
    this.costPrice = 0.0,
    this.profit = 0.0,
    this.productName = '',
    this.targetId = '',
    this.orderId = '',
    required this.previousBalance,
    required this.newBalance,
    this.currency = 'USD',
    required this.note,
    required this.createdAt,
  });

  bool get isDeposit => type == 'deposit';
  bool get isDeduction => type == 'deduction';
  bool get isPurchase => type == 'purchase';
  bool get isRefund => type == 'refund';
  bool get isSyp => currency.toUpperCase() == 'SYP';
  String get currencySymbol => isSyp ? 'ل.س' : '\$';
}
