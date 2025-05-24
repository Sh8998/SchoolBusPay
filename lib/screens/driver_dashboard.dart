import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/driver.dart';
import '../../models/parent.dart';
import '../../providers/app_state.dart';
import '../services/auth_service.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    final driverAsync = ref.watch(driverProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showRemindersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: driverAsync.when(
        data: (driver) {
          if (driver == null) return _buildNoDriverUI(context, ref);
          
          return Column(
            children: [
              // Driver Info Card
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.drive_eta, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${driver.name}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Bus No: ${driver.busNo}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Mobile: ${driver.mobileNumber}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab Bar
              DefaultTabController(
                length: 2,
                child: Expanded(
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.payment), text: 'Payments'),
                          Tab(icon: Icon(Icons.people), text: 'Parents'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPaymentsTab(context, ref, driver),
                            _buildParentsTab(context, ref, driver),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context, WidgetRef ref, Driver driver) {
    final parentsAsync = ref.watch(parentsByDriverProvider(driver.id));
    
    return parentsAsync.when(
      data: (parents) {
        if (parents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No parents assigned to your bus'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index];
            return _buildParentPaymentCard(context, ref, parent);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildParentPaymentCard(BuildContext context, WidgetRef ref, Parent parent) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pending Fees: ₹${parent.pendingFees}'),
                    Text('Children: ${parent.noOfChildren}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: parent.pendingFees == 0 ? 1.0 : 0.0,
                  backgroundColor: Colors.grey[200],
                  color: parent.pendingFees == 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${parent.pendingFees == 0 ? 'Paid' : 'Pending'}',
                      style: TextStyle(
                        color: parent.pendingFees == 0 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (parent.pendingFees > 0)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Send Reminder'),
                        onPressed: () => _sendReminder(parent),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _updatePaymentStatus(parent),
                  child: const Text('Update Payment Status'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentsTab(BuildContext context, WidgetRef ref, Driver driver) {
    final parentsAsync = ref.watch(parentsByDriverProvider(driver.id));
    
    return parentsAsync.when(
      data: (parents) {
        if (parents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No parents assigned to your bus'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(parent.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.mobileNumber),
                    Text('Children: ${parent.noOfChildren}'),
                    Text('Pending Fees: ₹${parent.pendingFees}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () => _callParent(parent.mobileNumber),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _updatePaymentStatus(Parent parent) async {
    final amountController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Payment for ${parent.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Pending: ₹${parent.pendingFees}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final paidAmount = double.tryParse(amountController.text) ?? 0;
              if (paidAmount > 0) {
                try {
                  final firebaseService = ref.read(firebaseServiceProvider);
                  final newPending = parent.pendingFees - paidAmount;
                  await firebaseService.updateParent(
                    parent.copyWith(pendingFees: newPending < 0 ? 0 : newPending),
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(Parent parent) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder sent to ${parent.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _callParent(String mobileNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $mobileNumber'),
      ),
    );
  }

  Future<void> _showRemindersDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminders'),
        content: const Text('Send payment reminders to all parents with pending fees?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminders sent to all parents with pending fees'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send All'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriverUI(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No driver records found',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please contact admin to set up your account',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(driverProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}