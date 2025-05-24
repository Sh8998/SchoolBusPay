import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    final parentAsync = ref.watch(parentProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
      ),
      body: parentAsync.when(
        data: (parent) {
          if (parent == null) {
            return const Center(
              child: Text('No parent records found. Please contact admin.'),
            );
          }

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
                    _buildInfoColumn(
                      context,
                      'Children',
                      parent.noOfChildren.toString(),
                      Icons.child_care,
                    ),
                    _buildInfoColumn(
                      context,
                      'Pending',
                      '₹${parent.pendingFees}',
                      Icons.payment,
                      isSuccess: parent.pendingFees == 0,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus, size: 100, color: Colors.blue),
                      const SizedBox(height: 20),
                      Text(
                        'Bus No: ${parent.driverId.isEmpty ? 'Not assigned' : 'Assigned'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (parent.pendingFees > 0)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ElevatedButton(
                            onPressed: () {
                              // Implement payment functionality
                            },
                            child: const Text('Make Payment'),
                          ),
                        ),
                    ],
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
}