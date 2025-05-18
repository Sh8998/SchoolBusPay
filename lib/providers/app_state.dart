import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../models/parent.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import '../services/payment_scheduler_service.dart';

final databaseProvider = Provider((ref) => DatabaseHelper());

final driversProvider = FutureProvider<List<Driver>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getDrivers();
});

final parentsProvider = FutureProvider<List<Parent>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getParents();
});

final selectedDriverProvider = StateProvider<Driver?>((ref) => null);
final selectedParentProvider = StateProvider<Parent?>((ref) => null);

final parentsByDriverProvider = FutureProvider.family<List<Parent>, int>((ref, driverId) async {
  final database = ref.watch(databaseProvider);
  return database.getParentsByDriverId(driverId);
});

final paymentsByParentProvider = FutureProvider.family<List<Payment>, int>((ref, parentId) async {
  final database = ref.watch(databaseProvider);
  return database.getPaymentsByParentId(parentId);
});

// Error handling state
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

final firstDriverProvider = FutureProvider<Driver?>((ref) async {
  final database = ref.watch(databaseProvider);
  final drivers = await database.getDrivers();
  return drivers.isNotEmpty ? drivers.first : null;
});

final firstParentProvider = FutureProvider<Parent?>((ref) async {
  final database = ref.watch(databaseProvider);
  final parents = await database.getParents();
  return parents.isNotEmpty ? parents.first : null;
});

final paymentSchedulerServiceProvider = Provider((ref) {
  final database = ref.read(databaseProvider);
  final scheduler = PaymentSchedulerService(database);
  
  // Start the scheduler when the provider is created
  scheduler.startScheduler();
  
  // Stop the scheduler when the provider is disposed
  ref.onDispose(() {
    scheduler.stopScheduler();
  });
  
  return scheduler;
}); 