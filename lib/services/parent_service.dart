import 'package:cloud_firestore/cloud_firestore.dart';

class ParentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getParents() {
    return _firestore.collection('parents').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> assignParentToDriver(String parentId, String driverId) async {
    // Update the parent's driverId
    await _firestore.collection('parents').doc(parentId).update({
      'driverId': driverId,
    });

    // Add the parent to the driver's list
    await _firestore.collection('drivers').doc(driverId).update({
      'parents': FieldValue.arrayUnion([parentId]),
    });
  }

  Future<void> removeParentFromDriver(String parentId, String driverId) async {
    // Remove the parent from the driver's list
    await _firestore.collection('drivers').doc(driverId).update({
      'parents': FieldValue.arrayRemove([parentId]),
    });

    // Remove the driverId from the parent
    await _firestore.collection('parents').doc(parentId).update({
      'driverId': null,
    });
  }
}
