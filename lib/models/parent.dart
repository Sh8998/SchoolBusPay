class Parent {
  final String id;
  final String name;
  final String mobileNumber;
  final String driverId;
  final int noOfChildren;
  final double pendingFees;
  final List<String> paymentIds;

  Parent({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.driverId = '',
    this.noOfChildren = 1,
    this.pendingFees = 0,
    this.paymentIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'driverId': driverId,
      'noOfChildren': noOfChildren,
      'pendingFees': pendingFees,
      'paymentIds': paymentIds,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'] as String,
      name: map['name'] as String,
      mobileNumber: map['mobileNumber'] as String,
      driverId: map['driverId'] as String? ?? '',
      noOfChildren: map['noOfChildren'] as int? ?? 1,
      pendingFees: (map['pendingFees'] as num?)?.toDouble() ?? 0,
      paymentIds: List<String>.from(map['paymentIds'] ?? []),
    );
  }

  Parent copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    String? driverId,
    int? noOfChildren,
    double? pendingFees,
    List<String>? paymentIds,
  }) {
    return Parent(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      driverId: driverId ?? this.driverId,
      noOfChildren: noOfChildren ?? this.noOfChildren,
      pendingFees: pendingFees ?? this.pendingFees,
      paymentIds: paymentIds ?? this.paymentIds,
    );
  }
}