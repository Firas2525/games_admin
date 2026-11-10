import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userName,
    required super.userEmail,
    super.adminName,
    required super.type,
    required super.amount,
    super.costPrice,
    super.profit,
    super.productName,
    super.targetId,
    super.orderId,
    required super.previousBalance,
    required super.newBalance,
    super.currency,
    required super.note,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String uName = 'مستخدم غير معروف';
    String uEmail = '';

    if (json['userId'] is Map) {
      final u = json['userId'] as Map<String, dynamic>;
      uName = u['name'] as String? ?? 'مستخدم';
      uEmail = u['email'] as String? ?? '';
    }

    String? aName;
    if (json['adminId'] is Map) {
      final a = json['adminId'] as Map<String, dynamic>;
      aName = a['name'] as String?;
    }

    final amountVal = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final costVal = (json['costPrice'] as num?)?.toDouble() ?? 0.0;
    double profitVal = (json['profit'] as num?)?.toDouble() ?? 0.0;
    if (profitVal == 0.0 && json['type'] == 'purchase' && costVal > 0.0 && amountVal > costVal) {
      profitVal = amountVal - costVal;
    }

    return TransactionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userName: uName,
      userEmail: uEmail,
      adminName: aName,
      type: json['type'] as String? ?? 'deposit',
      amount: amountVal,
      costPrice: costVal,
      profit: profitVal,
      productName: json['productName'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      previousBalance: (json['previousBalance'] as num?)?.toDouble() ?? 0.0,
      newBalance: (json['newBalance'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String? ??
              (json['userId'] is Map ? (json['userId']['currency'] as String?) : null) ??
              'USD')
          .toUpperCase(),
      note: json['note'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
