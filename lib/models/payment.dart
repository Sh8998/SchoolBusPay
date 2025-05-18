class Payment {
  final int id;
  final int parentId;
  final int month;
  final int year;
  final double amount;
  final bool isPaid;
  final String dueDate;
  final String? paidDate;

  Payment({
    required this.id,
    required this.parentId,
    required this.month,
    required this.year,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
    this.paidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'parentId': parentId,
      'month': month,
      'year': year,
      'amount': amount,
      'isPaid': isPaid ? 1 : 0,
      'dueDate': dueDate,
      'paidDate': paidDate,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int,
      parentId: map['parentId'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      amount: (map['amount'] as num).toDouble(),
      isPaid: (map['isPaid'] as int) == 1,
      dueDate: map['dueDate'] as String,
      paidDate: map['paidDate'] as String?,
    );
  }
} 