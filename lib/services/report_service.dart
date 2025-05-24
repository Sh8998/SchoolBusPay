import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>> getReports() {
    return _firestore.collection('parents').snapshots().map((snapshot) {
      int totalPending = 0;
      int totalPaid = 0;
      int totalChildren = 0;

      // for (var doc in snapshot.docs) {
      //   totalPending += doc['feeStatus']['pending'];
      //   totalPaid += doc['feeStatus']['paid'];
      //   totalChildren += doc['children'];
      // }

      return {
        'totalPending': totalPending,
        'totalPaid': totalPaid,
        'totalChildren': totalChildren,
      };
    });
  }
}
