import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/driver.dart';
import '../../models/parent.dart';
import '../../models/payment.dart';
import '../../widgets/error_dialog.dart';

class PaymentRecordsScreen extends ConsumerStatefulWidget {
  final Driver driver;

  const PaymentRecordsScreen({super.key, required this.driver});

  @override
  ConsumerState<PaymentRecordsScreen> createState() => _PaymentRecordsScreenState();
}

class _PaymentRecordsScreenState extends ConsumerState<PaymentRecordsScreen> {
  String _parentNameQuery = '';
  String _mobileNumberQuery = '';
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

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
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
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsByDriverProvider(widget.driver.id));

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
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by mobile number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _mobileNumberQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: parentsAsync.when(
              data: (parents) {
                if (parents.isEmpty) {
                  return const Center(
                    child: Text('No parents assigned to your bus'),
                  );
                }

                // Filter parents by name and mobile number
                final filteredParents = parents.where((parent) {
                  final nameMatches = _parentNameQuery.isEmpty ||
                      parent.name
                          .toLowerCase()
                          .contains(_parentNameQuery.toLowerCase());
                  final mobileMatches = _mobileNumberQuery.isEmpty ||
                      parent.mobileNumber.contains(_mobileNumberQuery);
                  return nameMatches && mobileMatches;
                }).toList();

                if (filteredParents.isEmpty) {
                  return const Center(
                    child: Text('No parents match the search criteria'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredParents.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final parent = filteredParents[index];
                    return _buildParentPaymentCard(context, ref, parent);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentPaymentCard(
    BuildContext context,
    WidgetRef ref,
    Parent parent,
  ) {
    final paymentsAsync = ref.watch(paymentsByParentProvider(parent.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(parent.name),
            subtitle: Text('Mobile: ${parent.mobileNumber}'),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No payment records found'),
                );
              }

              final filteredPayments = _filterPayments(payments);
              
              if (filteredPayments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No payments match the current filters'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPayments.length,
                itemBuilder: (context, index) {
                  final payment = filteredPayments[index];
                  return ListTile(
                    title: Text(
                      '${DateFormat('MMMM yyyy').format(DateTime(payment.year, payment.month))}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: ₹${payment.amount}'),
                        Text(
                          'Due: ${DateFormat.yMMM().format(DateTime.parse(payment.dueDate))}',
                        ),
                        if (payment.paidDate != null)
                          Text(
                            'Paid on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.paidDate!))}',
                            style: const TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        payment.isPaid
                            ? const Chip(
                                label: Text('Paid'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : const Chip(
                                label: Text('Unpaid'),
                                backgroundColor: Colors.red,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditPaymentDialog(context, ref, payment);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Error: ${error.toString()}'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Payment payment,
  ) {
    final amountController = TextEditingController(
      text: payment.amount.toString(),
    );
    DateTime dueDate = DateTime.parse(payment.dueDate);
    bool isPaid = payment.isPaid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Payment'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(
                  DateFormat('dd MMM yyyy').format(dueDate),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final newDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(dueDate.year, dueDate.month),
                      lastDate: DateTime(dueDate.year, dueDate.month + 1, 0),
                    );
                    if (newDate != null) {
                      setState(() => dueDate = newDate);
                    }
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Payment Status'),
                subtitle: Text(isPaid ? 'Paid' : 'Unpaid'),
                value: isPaid,
                onChanged: (value) {
                  setState(() => isPaid = value);
                },
              ),
              if (payment.paidDate != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Paid on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.paidDate!))}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newAmount = double.parse(amountController.text);
                final updatedPayment = Payment(
                  id: payment.id,
                  parentId: payment.parentId,
                  month: payment.month,
                  year: payment.year,
                  amount: newAmount,
                  isPaid: isPaid,
                  dueDate: dueDate.toIso8601String(),
                  paidDate: isPaid 
                    ? (payment.paidDate ?? DateTime.now().toIso8601String())
                    : null,
                );

                final database = ref.read(databaseProvider);
                await database.updatePayment(updatedPayment);

                // Refresh the payments list
                ref.invalidate(paymentsByParentProvider(payment.parentId));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment updated successfully'),
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
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
} 