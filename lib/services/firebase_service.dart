import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver.dart';
import '../models/parent.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Drivers Collection
  Stream<List<Driver>> getDrivers() {
    return _firestore.collection('drivers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Driver.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }

  Future<void> addDriver(Driver driver) async {
    await _firestore.collection('drivers').doc(driver.id).set(driver.toMap());
  }

  Future<void> updateDriver(Driver driver) async {
    await _firestore.collection('drivers').doc(driver.id).update(driver.toMap());
  }

  Future<void> deleteDriver(String driverId) async {
    await _firestore.collection('drivers').doc(driverId).delete();
  }

  // Parents Collection
  Stream<List<Parent>> getParents() {
    return _firestore.collection('parents').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Parent.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }

  Future<void> addParent(Parent parent) async {
    await _firestore.collection('parents').doc(parent.id).set(parent.toMap());
  }

  Future<void> updateParent(Parent parent) async {
    await _firestore.collection('parents').doc(parent.id).update(parent.toMap());
  }

  Future<void> deleteParent(String parentId) async {
    await _firestore.collection('parents').doc(parentId).delete();
  }

  // Assign/Unassign parents to drivers
  Future<void> assignParentToDriver(String parentId, String driverId) async {
    final batch = _firestore.batch();
    
    // Add parent to driver's parentIds
    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      'parentIds': FieldValue.arrayUnion([parentId])
    });

    // Set driverId for parent
    final parentRef = _firestore.collection('parents').doc(parentId);
    batch.update(parentRef, {
      'driverId': driverId
    });

    await batch.commit();
  }

  Future<void> unassignParentFromDriver(String parentId, String driverId) async {
    final batch = _firestore.batch();
    
    // Remove parent from driver's parentIds
    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      'parentIds': FieldValue.arrayRemove([parentId])
    });

    // Remove driverId from parent
    final parentRef = _firestore.collection('parents').doc(parentId);
    batch.update(parentRef, {
      'driverId': ''
    });

    await batch.commit();
  }

  // Get parents by driver
  Stream<List<Parent>> getParentsByDriver(String driverId) {
    return _firestore
        .collection('parents')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Parent.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }
}

final firebaseServiceProvider = Provider((ref) => FirebaseService());