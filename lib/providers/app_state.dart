import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../models/parent.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final driversProvider = StreamProvider<List<Driver>>((ref) {
  return ref.watch(firebaseServiceProvider).getDrivers();
});

final parentsProvider = StreamProvider<List<Parent>>((ref) {
  return ref.watch(firebaseServiceProvider).getParents();
});

final parentsByDriverProvider = StreamProvider.family<List<Parent>, String>((ref, driverId) {
  return ref.watch(firebaseServiceProvider).getParentsByDriver(driverId);
});

final driverProvider = FutureProvider.family<Driver?, String>((ref, driverId) async {
  final drivers = await ref.watch(driversProvider.future);
  return drivers.firstWhere((d) => d.id == driverId);
});

final parentProvider = FutureProvider.family<Parent?, String>((ref, parentId) async {
  final parents = await ref.watch(parentsProvider.future);
  return parents.firstWhere((p) => p.id == parentId);
});

// Error handling state
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);