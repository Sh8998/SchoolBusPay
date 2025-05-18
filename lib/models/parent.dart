class Parent {
  final int id;
  final String name;
  final String mobileNumber;
  final int driverId;
  final List<int> paymentIds;

  Parent({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.driverId,
    required this.paymentIds,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'driverId': driverId,
      'paymentIds': paymentIds.isEmpty ? '' : paymentIds.join(','),
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    final paymentIdsStr = map['paymentIds']?.toString() ?? '';
    return Parent(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String? ?? '',
      driverId: map['driverId'] as int? ?? 0,
      paymentIds: paymentIdsStr.isEmpty ? [] : paymentIdsStr.split(',').map((e) => int.parse(e)).toList(),
    );
  }
} 