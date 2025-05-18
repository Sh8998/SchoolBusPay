import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state.dart';
import '../../models/parent.dart';
import '../../models/driver.dart';
import '../../screens/parent_dashboard.dart';

class DriverParentsList extends ConsumerStatefulWidget {
  final Driver driver;

  const DriverParentsList({super.key, required this.driver});

  @override
  ConsumerState<DriverParentsList> createState() => _DriverParentsListState();
}

class _DriverParentsListState extends ConsumerState<DriverParentsList> {
  String _searchQuery = '';

  List<Parent> _filterParents(List<Parent> parents) {
    if (_searchQuery.isEmpty) return parents;
    
    return parents.where((parent) =>
      parent.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      parent.mobileNumber.contains(_searchQuery)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsByDriverProvider(widget.driver.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parents List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or mobile',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: parentsAsync.when(
              data: (parents) {
                final filteredParents = _filterParents(parents);
                
                if (filteredParents.isEmpty) {
                  return const Center(
                    child: Text('No parents found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredParents.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final parent = filteredParents[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(parent.name),
                        subtitle: Text('Mobile: ${parent.mobileNumber}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.payment),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentDashboard(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 