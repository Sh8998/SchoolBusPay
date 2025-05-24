import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null && picked != _dateRange) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);
    final parentsAsync = ref.watch(parentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: driversAsync.when(
        data: (drivers) => parentsAsync.when(
          data: (parents) {
            // Calculate report data
            final totalRevenue = parents.fold(0.0, (sum, parent) => sum + parent.pendingFees);
            final paidRevenue = totalRevenue * 0.7; // Placeholder
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Select Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => _selectDateRange(context),
                            child: Text(
                              '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Revenue Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildReportItem('Total Revenue', NumberFormat.currency(symbol: '₹').format(totalRevenue)),
                          _buildReportItem('Paid Revenue', NumberFormat.currency(symbol: '₹').format(paidRevenue)),
                          _buildReportItem('Pending Revenue', NumberFormat.currency(symbol: '₹').format(totalRevenue - paidRevenue)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Driver Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...drivers.map((driver) {
                            final driverParents = parents.where((p) => p.driverId == driver.id).toList();
                            final driverRevenue = driverParents.fold(0.0, (sum, parent) => sum + parent.pendingFees);
                            final driverPaid = driverRevenue * 0.7; // Placeholder
                            
                            return _buildReportItem(
                              '${driver.name} (Bus ${driver.busNo})',
                              '${driverParents.length} parents | Paid: ${NumberFormat.currency(symbol: '₹').format(driverPaid)}',
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _generatePdfReport(),
                    child: const Text('Generate PDF Report'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildReportItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    // Implement PDF generation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF report generated successfully')),
    );
  }
}