import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/parent.dart';
import '../providers/app_state.dart';

class PaymentService {
  final DatabaseHelper _database;

  PaymentService(this._database);

  Future<void> createMonthlyPayments() async {
    try {
      // Get all parents
      final List<Parent> parents = await _database.getParents();
      
      // Get current month and year
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      // Calculate last day of the month for due date
      final lastDay = DateTime(currentYear, currentMonth + 1, 0);
      
      // Create payment records for each parent
      for (final parent in parents) {
        // Check if payment record already exists for this month
        final existingPayments = await _database.getPaymentsByParentId(parent.id);
        final hasPaymentForMonth = existingPayments.any(
          (payment) => payment.month == currentMonth && payment.year == currentYear,
        );
        
        // If no payment record exists for this month, create one
        if (!hasPaymentForMonth) {
          final payment = Payment(
            id: 0, // Auto-generated
            parentId: parent.id,
            month: currentMonth,
            year: currentYear,
            amount: 1000.0, // Default amount of 1000
            isPaid: false,
            dueDate: lastDay.toIso8601String(),
            paidDate: null, // Initially null until payment is made
          );
          
          await _database.insertPayment(payment);
        }
      }
    } catch (e) {
      throw Exception('Failed to create monthly payments: $e');
    }
  }

  Future<void> updatePaymentStatus(Payment payment, bool isPaid) async {
    try {
      final updatedPayment = Payment(
        id: payment.id,
        parentId: payment.parentId,
        month: payment.month,
        year: payment.year,
        amount: payment.amount,
        isPaid: isPaid,
        dueDate: payment.dueDate,
        paidDate: isPaid ? DateTime.now().toIso8601String() : null,
      );
      
      await _database.updatePayment(updatedPayment);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }
}

final paymentServiceProvider = Provider((ref) {
  final database = ref.read(databaseProvider);
  return PaymentService(database);
}); 