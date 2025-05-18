import 'package:flutter/material.dart';
import 'admin/manage_drivers_screen.dart';
import 'admin/manage_parents_screen.dart';
import 'admin/manage_payment_records_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: GridView.count(
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
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageDriversScreen(),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            'Manage Parents',
            Icons.family_restroom,
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageParentsScreen(),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            'Payment Records',
            Icons.payment,
            Colors.orange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManagePaymentRecordsScreen(),
                ),
              );            },
          ),
          _buildDashboardCard(
            context,
            'Bus Assignment',
            Icons.directions_bus,
            Colors.purple,
            () {
              // TODO: Navigate to bus assignment screen
            },
          ),
        ],
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