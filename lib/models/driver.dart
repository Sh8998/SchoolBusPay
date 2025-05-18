class Driver {
  final int id;
  final String name;
  final String busNo;
  final String mobileNumber;
  final List<int> parentIds;

  Driver({
    required this.id,
    required this.name,
    required this.busNo,
    required this.mobileNumber,
    required this.parentIds,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'name': name,
      'busNo': busNo,
      'mobileNumber': mobileNumber,
      'parentIds': parentIds.isEmpty ? '' : parentIds.join(','),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    final parentIdsStr = map['parentIds'].toString();
    return Driver(
      id: map['id'] as int,
      name: map['name'] as String,
      busNo: map['busNo'] as String,
      mobileNumber: map['mobileNumber'] as String,
      parentIds: parentIdsStr.isEmpty ? [] : parentIdsStr.split(',').map((e) => int.parse(e)).toList(),
    );
  }
} 