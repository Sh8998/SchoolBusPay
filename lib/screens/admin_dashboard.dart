import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import 'admin/bus_assignment_screen.dart';
import 'admin/manage_drivers_screen.dart';
import 'admin/manage_parents_screen.dart';
import 'admin/manage_payment_records_screen.dart';
import 'admin/reports_screen.dart';


class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);
    final parentsAsync = ref.watch(parentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: driversAsync.when(
              data: (drivers) => parentsAsync.when(
                data: (parents) {
                  // Calculate statistics
                  final totalDrivers = drivers.length;
                  final totalParents = parents.length;
                  final totalRevenue = parents.fold(0.0, (sum, parent) => sum + parent.pendingFees);
                  final paidRevenue = parents.fold(0.0, (sum, parent) {
                    // This would need to be calculated from payments in a real app
                    return sum + (parent.pendingFees * 0.7); // Placeholder - 70% paid
                  });

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatCard(context, 'Drivers', totalDrivers, Icons.drive_eta, Colors.blue),
                        _buildStatCard(context, 'Parents', totalParents, Icons.family_restroom, Colors.green),
                        _buildStatCard(context, 'Revenue', NumberFormat.currency(symbol: '₹').format(totalRevenue), 
                          Icons.attach_money, Colors.orange),
                        _buildStatCard(context, 'Paid', NumberFormat.currency(symbol: '₹').format(paidRevenue), 
                          Icons.check_circle, Colors.teal),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ),

          // Main Grid View
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildDashboardCard(
                  context,
                  'Manage Drivers',
                  Icons.drive_eta,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ManageDriversScreen(),
                  )),
                ),
                _buildDashboardCard(
                  context,
                  'Manage Parents',
                  Icons.family_restroom,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ManageParentsScreen(),
                  )),
                ),
                _buildDashboardCard(
                  context,
                  'Payment Records',
                  Icons.payment,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ManagePaymentRecordsScreen(),
                  )),
                ),
                _buildDashboardCard(
                  context,
                  'Bus Assignment',
                  Icons.directions_bus,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const BusAssignmentScreen(),
                  )),
                ),
                _buildDashboardCard(
                  context,
                  'Reports',
                  Icons.analytics,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, dynamic value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Hero(
      tag: title,
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}