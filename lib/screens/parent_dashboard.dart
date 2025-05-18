import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/parent.dart';
import '../models/payment.dart';
import '../providers/app_state.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAsync = ref.watch(firstParentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: parentAsync.when(
        data: (parent) {
          if (parent == null) {
            return const Center(
              child: Text('No parent records found. Please contact admin.'),
            );
          }

          final paymentsAsync = ref.watch(paymentsByParentProvider(parent.id));

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(
                      context,
                      'Name',
                      parent.name,
                      Icons.person,
                    ),
                    _buildInfoColumn(
                      context,
                      'Mobile',
                      parent.mobileNumber,
                      Icons.phone,
                    ),
                    paymentsAsync.when(
                      data: (payments) {
                        final currentMonthPayment = payments.where((p) {
                          final now = DateTime.now();
                          return p.month == now.month && p.year == now.year;
                        }).firstOrNull;

                        return _buildInfoColumn(
                          context,
                          'Current Month',
                          currentMonthPayment?.isPaid == true ? 'Paid' : 'Pending',
                          Icons.payment,
                          isSuccess: currentMonthPayment?.isPaid == true,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) => _buildInfoColumn(
                        context,
                        'Status',
                        'Error',
                        Icons.error,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: paymentsAsync.when(
                  data: (payments) {
                    if (payments.isEmpty) {
                      return const Center(
                        child: Text('No payment records found'),
                      );
                    }

                    // Sort payments by date (newest first)
                    final sortedPayments = List<Payment>.from(payments)
                      ..sort((a, b) {
                        final dateA = DateTime(a.year, a.month);
                        final dateB = DateTime(b.year, b.month);
                        return dateB.compareTo(dateA);
                      });

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Payment History',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ...sortedPayments.map((payment) => _buildPaymentHistoryItem(
                              context,
                              DateFormat('MMMM yyyy').format(DateTime(payment.year, payment.month)),
                              payment.isPaid ? 'Paid' : 'Pending',
                              '₹${payment.amount}',
                              payment.isPaid,
                              payment,
                            )),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isSuccess = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isSuccess
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryItem(
    BuildContext context,
    String month,
    String status,
    String amount,
    bool isPaid,
    Payment payment,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green : Colors.orange,
          child: Icon(
            isPaid ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(month),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status),
            Text(
              'Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.dueDate))}',
            ),
            if (payment.paidDate != null)
              Text(
                'Paid on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.paidDate!))}',
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
        trailing: Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        isThreeLine: true,
      ),
    );
  }
} 