import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parent.dart';
import '../../providers/app_state.dart';

class BusAssignmentScreen extends ConsumerStatefulWidget {
  const BusAssignmentScreen({super.key});

  @override
  ConsumerState<BusAssignmentScreen> createState() => _BusAssignmentScreenState();
}

class _BusAssignmentScreenState extends ConsumerState<BusAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);
    final parentsAsync = ref.watch(parentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Assignment'),
      ),
      body: driversAsync.when(
        data: (drivers) => parentsAsync.when(
          data: (parents) {
            if (drivers.isEmpty || parents.isEmpty) {
              return const Center(
                child: Text('No drivers or parents available'),
              );
            }

            return ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, driverIndex) {
                final driver = drivers[driverIndex];
                final driverParents = parents.where((p) => p.driverId == driver.id).toList();

                return ExpansionTile(
                  title: Text('${driver.name} - Bus ${driver.busNo}'),
                  subtitle: Text('${driverParents.length} parents assigned'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Assigned Parents:'),
                          ...driverParents.map((parent) => ListTile(
                                title: Text(parent.name),
                                subtitle: Text('Children: ${parent.noOfChildren}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editParentChildrenCount(parent),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _unassignParent(parent, driver.id),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(),
                          const Text('Unassigned Parents:'),
                          ...parents
                              .where((p) => p.driverId.isEmpty)
                              .map((parent) => ListTile(
                                    title: Text(parent.name),
                                    subtitle: Text(parent.mobileNumber),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () => _assignParent(parent, driver.id),
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        error: (Object error, StackTrace stackTrace) {
          Center(child: Text('Error: $error'));
          return null;
        },
        loading: () {
          const Center(child: CircularProgressIndicator());
          return null;
        },
      ),
    );
  }

  Future<void> _assignParent(Parent parent, String driverId) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.assignParentToDriver(parent.id, driverId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent assigned successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _unassignParent(Parent parent, String driverId) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.unassignParentFromDriver(parent.id, driverId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent unassigned successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editParentChildrenCount(Parent parent) async {
    final childrenController = TextEditingController(text: parent.noOfChildren.toString());
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Children Count for ${parent.name}'),
        content: TextField(
          controller: childrenController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Children',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCount = int.tryParse(childrenController.text) ?? parent.noOfChildren;
              try {
                final firebaseService = ref.read(firebaseServiceProvider);
                await firebaseService.updateParent(
                  parent.copyWith(noOfChildren: newCount),
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}