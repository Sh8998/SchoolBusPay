import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/driver.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class ManageDriversScreen extends ConsumerStatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  ConsumerState<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends ConsumerState<ManageDriversScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _busNoController = TextEditingController();
  final _mobileNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _busNoController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  void _showDriverDialog({Driver? driverToEdit}) {
    final driver = driverToEdit;
    
    if (driver != null) {
      _nameController.text = driver.name;
      _busNoController.text = driver.busNo;
      _mobileNumberController.text = driver.mobileNumber;
    } else {
      _nameController.clear();
      _busNoController.clear();
      _mobileNumberController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver == null ? 'Add New Driver' : 'Edit Driver'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter driver name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _busNoController,
                  decoration: const InputDecoration(labelText: 'Bus Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bus number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _mobileNumberController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  ref.read(isLoadingProvider.notifier).state = true;
                  final firebaseService = ref.read(firebaseServiceProvider);

                  final newDriver = Driver(
                    id: driver?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text,
                    busNo: _busNoController.text,
                    mobileNumber: _mobileNumberController.text,
                    parentIds: driver?.parentIds ?? [],
                  );

                  if (driver == null) {
                    await firebaseService.addDriver(newDriver);
                  } else {
                    await firebaseService.updateDriver(newDriver);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          driver == null
                              ? 'Driver added successfully'
                              : 'Driver updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ref.read(errorMessageProvider.notifier).state = e.toString();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => ErrorDialog(
                        message: e.toString(),
                        onRetry: () {},
                      ),
                    );
                  }
                } finally {
                  ref.read(isLoadingProvider.notifier).state = false;
                }
              }
            },
            child: Text(driver == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDriver(Driver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete ${driver.name}? '
          'This will also remove the driver from all associated parents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        ref.read(isLoadingProvider.notifier).state = true;
        final firebaseService = ref.read(firebaseServiceProvider);
        
        // First unassign all parents
        final parents = await firebaseService.getParents().first;
        final batch = FirebaseFirestore.instance.batch();
        
        for (final parent in parents.where((p) => p.driverId == driver.id)) {
          batch.update(FirebaseFirestore.instance.collection('parents').doc(parent.id), {
            'driverId': ''
          });
        }
        
        await batch.commit();
        
        // Then delete the driver
        await firebaseService.deleteDriver(driver.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver deleted successfully')),
          );
        }
      } catch (e) {
        ref.read(errorMessageProvider.notifier).state = e.toString();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              message: e.toString(),
              onRetry: () {},
            ),
          );
        }
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
      ),
      body: Stack(
        children: [
          driversAsync.when(
            data: (drivers) => drivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.drive_eta, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No drivers found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showDriverDialog(),
                          child: const Text('Add Driver'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: drivers.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Hero(
                            tag: 'driver_${driver.id}',
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.drive_eta, color: Colors.white),
                            ),
                          ),
                          title: Text(driver.name),
                          subtitle: Text(
                              'Bus No: ${driver.busNo}\nMobile: ${driver.mobileNumber}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showDriverDialog(driverToEdit: driver);
                                  break;
                                case 'delete':
                                  _deleteDriver(driver);
                                  break;
                              }
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
            error: (error, stackTrace) => Center(
              child: ErrorDialog(
                message: error.toString(),
                onRetry: () => ref.invalidate(driversProvider),
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDriverDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}