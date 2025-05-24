import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentSchedulerService {
  final DatabaseHelper _database;
  Timer? _scheduledTask;

  PaymentSchedulerService(this._database);

  void startScheduler() {
    // Cancel any existing scheduled task
    _scheduledTask?.cancel();

    // Calculate time until next 1st of month at 00:00:00
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final timeUntilNextMonth = nextMonth.difference(now);

    // Schedule initial task
    _scheduledTask = Timer(timeUntilNextMonth, () {
      _createMonthlyPayments();
      
      // After initial execution, schedule recurring task for 1st of each month
      _scheduledTask = Timer.periodic(
        const Duration(days: 1),
        (timer) {
          final currentDate = DateTime.now();
          if (currentDate.day == 1) {
            _createMonthlyPayments();
          }
        },
      );
    });
  }

  void stopScheduler() {
    _scheduledTask?.cancel();
    _scheduledTask = null;
  }

  Future<void> _createMonthlyPayments() async {
    try {
      final parents = await _database.getParents();
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0);

      for (final parent in parents) {
        // Check if payment record already exists for this month
        final existingPayments = await _database.getPaymentsByParentId(parent.id as int);
        final hasPaymentForMonth = existingPayments.any(
          (payment) => payment.month == now.month && payment.year == now.year,
        );

        // If no payment record exists for this month, create one
        if (!hasPaymentForMonth) {
          final payment = Payment(
            id: 0,
            parentId: parent.id as int,
            month: now.month,
            year: now.year,
            amount: 0.0, // Default amount, to be set by driver
            isPaid: false,
            dueDate: lastDay.toIso8601String(),
            paidDate: null,
          );

          await _database.insertPayment(payment);
        }
      }
    } catch (e) {
      debugPrint('Error creating monthly payments: $e');
    }
  }
} 