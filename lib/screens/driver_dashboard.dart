import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../models/driver.dart';
import 'driver/driver_parents_list.dart';
import 'driver/add_parent_screen.dart';
import 'driver/payment_records_screen.dart';

class DriverDashboard extends ConsumerWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(firstDriverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: driverAsync.when(
        data: (driver) {
          if (driver == null) {
            return const Center(
              child: Text('No driver records found. Please contact admin.'),
            );
          }

          return Column(
            children: [
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection(
                      context,
                      'Parents List',
                      Icons.group,
                      'View and manage parents assigned to your bus',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverParentsList(driver: driver),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Payment Records',
                      Icons.payment,
                      'View and update payment records',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentRecordsScreen(driver: driver),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Add New Parent',
                      Icons.person_add,
                      'Register a new parent to your bus',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddParentScreen(driver: driver),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 