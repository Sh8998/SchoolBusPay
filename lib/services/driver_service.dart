import 'package:cloud_firestore/cloud_firestore.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getDrivers() {
    return _firestore.collection('drivers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getParentsByDriver(String driverId) async {
    final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
    final parentIds = driverDoc['parents'] as List<dynamic>;

    final parentDocs = await Future.wait(parentIds.map((id) {
      return _firestore.collection('parents').doc(id).get();
    }));

    return parentDocs.map((doc) => {'id': doc.id, ...?doc.data()}).toList();
  }
}
