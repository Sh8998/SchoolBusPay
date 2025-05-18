import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parent.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';
import '../../screens/parent_dashboard.dart';

class ManageParentsScreen extends ConsumerStatefulWidget {
  const ManageParentsScreen({super.key});

  @override
  ConsumerState<ManageParentsScreen> createState() => _ManageParentsScreenState();
}

class _ManageParentsScreenState extends ConsumerState<ManageParentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _deleteParent(Parent parent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parent'),
        content: Text(
          'Are you sure you want to delete ${parent.name}? '
          'This will also remove all associated payment records.',
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
        final database = ref.read(databaseProvider);
        await database.deleteParent(parent.id);
        ref.invalidate(parentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parent deleted successfully')),
          );
        }
      } catch (e) {
        ref.read(errorMessageProvider.notifier).state = e.toString();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              message: e.toString(),
              onRetry: () {
                // Retry logic
              },
            ),
          );
        }
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  void _showAddParentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Parent'),
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
                      return 'Please enter parent name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                FutureBuilder(
                  future: ref.read(databaseProvider).getDrivers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final drivers = snapshot.data!;
                      return DropdownButtonFormField(
                        decoration: const InputDecoration(labelText: 'Select Driver'),
                        items: drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.id,
                            child: Text('${driver.name} (Bus: ${driver.busNo})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          ref.read(selectedDriverProvider.notifier).state =
                              drivers.firstWhere((d) => d.id == value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a driver';
                          }
                          return null;
                        },
                      );
                    }
                    return const CircularProgressIndicator();
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
                  final selectedDriver = ref.read(selectedDriverProvider);
                  if (selectedDriver == null) {
                    throw Exception('Please select a driver');
                  }

                  final database = ref.read(databaseProvider);
                  await database.insertParent(
                    Parent(
                      id: 0, // Auto-generated
                      name: _nameController.text,
                      mobileNumber: _mobileNumberController.text,
                      driverId: selectedDriver.id,
                      paymentIds: [],
                    ),
                  );
                  ref.invalidate(parentsProvider);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parent added successfully')),
                    );
                  }
                } catch (e) {
                  ref.read(errorMessageProvider.notifier).state = e.toString();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => ErrorDialog(
                        message: e.toString(),
                        onRetry: () {
                          // Retry logic
                        },
                      ),
                    );
                  }
                } finally {
                  ref.read(isLoadingProvider.notifier).state = false;
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parents'),
      ),
      body: Stack(
        children: [
          parentsAsync.when(
            data: (parents) => parents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.family_restroom,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No parents found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showAddParentDialog,
                          child: const Text('Add Parent'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: parents.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final parent = parents[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Hero(
                            tag: 'parent_${parent.id}',
                            child: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              child: const Icon(Icons.person,
                                  color: Colors.white),
                            ),
                          ),
                          title: Text(parent.name),
                          subtitle: FutureBuilder(
                            future: ref
                                .read(databaseProvider)
                                .getDrivers()
                                .then((drivers) => drivers.firstWhere(
                                    (d) => d.id == parent.driverId)),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final driver = snapshot.data!;
                                return Text(
                                    'Mobile: ${parent.mobileNumber}\nDriver: ${driver.name}\nBus: ${driver.busNo}');
                              }
                              return const Text('Loading driver info...');
                            },
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view_payments',
                                child: Text('View Payments'),
                              ),
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
                                case 'delete':
                                  _deleteParent(parent);
                                  break;
                                case 'view_payments':
                                  ref.read(selectedParentProvider.notifier).state = parent;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ParentDashboard(isAdmin: true),
                                    ),
                                  );
                                  break;
                                case 'edit':
                                  // TODO: Implement edit
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
                onRetry: () => ref.invalidate(parentsProvider),
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
        onPressed: _showAddParentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 