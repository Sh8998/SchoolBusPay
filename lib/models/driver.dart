class Driver {
  final String id;
  final String name;
  final String busNo;
  final String mobileNumber;
  final List<String> parentIds; 

  Driver({
    required this.id,
    required this.name,
    required this.busNo,
    required this.mobileNumber,
    this.parentIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'busNo': busNo,
      'mobileNumber': mobileNumber,
      'parentIds': parentIds,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      busNo: map['busNo'] as String,
      mobileNumber: map['mobileNumber'] as String,
      parentIds: List<String>.from(map['parentIds'] ?? []),
    );
  }
}