import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../models/parent.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class ManagePaymentRecordsScreen extends ConsumerStatefulWidget {
  const ManagePaymentRecordsScreen({super.key});

  @override
  ConsumerState<ManagePaymentRecordsScreen> createState() => _ManagePaymentRecordsScreenState();
}

class _ManagePaymentRecordsScreenState extends ConsumerState<ManagePaymentRecordsScreen> {
  String _searchQuery = '';
  String _parentNameQuery = '';
  bool _showOnlyPending = false;
  bool _showOnlyCurrentMonth = true;
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearController.text = now.year.toString();
    _monthController.text = now.month.toString();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    bool tempShowOnlyPending = _showOnlyPending;
    bool tempShowOnlyCurrentMonth = _showOnlyCurrentMonth;
    final tempMonthController = TextEditingController(text: _monthController.text);
    final tempYearController = TextEditingController(text: _yearController.text);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Payments'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempMonthController,
                decoration: const InputDecoration(
                  labelText: 'Month (1-12)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: tempYearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show Only Pending'),
                value: tempShowOnlyPending,
                onChanged: (value) {
                  setState(() {
                    tempShowOnlyPending = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Current Month Only'),
                value: tempShowOnlyCurrentMonth,
                onChanged: (value) {
                  setState(() {
                    tempShowOnlyCurrentMonth = value;
                    if (value) {
                      final now = DateTime.now();
                      tempMonthController.text = now.month.toString();
                      tempYearController.text = now.year.toString();
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _showOnlyPending = tempShowOnlyPending;
                  _showOnlyCurrentMonth = tempShowOnlyCurrentMonth;
                  _monthController.text = tempMonthController.text;
                  _yearController.text = tempYearController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsPaid(Payment payment, Parent parent) async {
    try {
      final updatedPayment = Payment(
        id: payment.id,
        parentId: payment.parentId,
        month: payment.month,
        year: payment.year,
        amount: payment.amount,
        isPaid: true,
        dueDate: payment.dueDate,
        paidDate: DateTime.now().toIso8601String(),
      );

      final database = ref.read(databaseProvider);
      await database.updatePayment(updatedPayment);

      // Refresh the payments list
      ref.invalidate(paymentsByParentProvider(payment.parentId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment marked as paid for ${parent.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: e.toString(),
            onRetry: () {},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(parentsProvider).whenData((parents) async {
      final database = ref.read(databaseProvider);
      final allPayments = <Payment>[];
      
      for (final parent in parents) {
        final payments = await database.getPaymentsByParentId(parent.id);
        allPayments.addAll(payments);
      }

      // Filter payments based on search query and other filters
      return allPayments.where((payment) {
        final parent = parents.firstWhere((p) => p.id == payment.parentId);
        
        // Filter by mobile number
        if (_searchQuery.isNotEmpty) {
          if (!parent.mobileNumber.contains(_searchQuery)) {
            return false;
          }
        }

        // Filter by parent name
        if (_parentNameQuery.isNotEmpty) {
          if (!parent.name.toLowerCase().contains(_parentNameQuery.toLowerCase())) {
            return false;
          }
        }
        
        // Apply month filter if set
        if (_monthController.text.isNotEmpty) {
          final month = int.tryParse(_monthController.text);
          if (month != null && payment.month != month) {
            return false;
          }
        }

        // Apply year filter if set
        if (_yearController.text.isNotEmpty) {
          final year = int.tryParse(_yearController.text);
          if (year != null && payment.year != year) {
            return false;
          }
        }

        // Apply pending payments filter
        if (_showOnlyPending && payment.isPaid) {
          return false;
        }

        // Apply current month filter
        if (_showOnlyCurrentMonth) {
          final now = DateTime.now();
          if (payment.month != now.month || payment.year != now.year) {
            return false;
          }
        }

        return true;
      }).toList();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by mobile number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by parent name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _parentNameQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: paymentsAsync.when(
              data: (futurePayments) => FutureBuilder(
                future: futurePayments,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final payments = snapshot.data!;
                    if (payments.isEmpty) {
                      return const Center(
                        child: Text('No payments found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return FutureBuilder(
                          future: ref
                              .read(databaseProvider)
                              .getParents()
                              .then((parents) => parents.firstWhere(
                                  (p) => p.id == payment.parentId)),
                          builder: (context, parentSnapshot) {
                            if (!parentSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final parent = parentSnapshot.data!;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: payment.isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    payment.isPaid
                                        ? Icons.check
                                        : Icons.pending,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(parent.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Mobile: ${parent.mobileNumber}'),
                                    Text(
                                      'Month: ${DateFormat('MMMM yyyy').format(DateTime(payment.year, payment.month))}',
                                    ),
                                    Text('Amount: ₹${payment.amount}'),
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
                                trailing: payment.isPaid
                                    ? const Chip(
                                        label: Text('PAID'),
                                        backgroundColor: Colors.green,
                                        labelStyle: TextStyle(color: Colors.white),
                                      )
                                    : TextButton.icon(
                                        onPressed: () => _markAsPaid(payment, parent),
                                        icon: const Icon(Icons.pending_actions),
                                        label: const Text('UNPAID'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                        ),
                                      ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              error: (error, stackTrace) => Center(
                child: ErrorDialog(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(parentsProvider),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 