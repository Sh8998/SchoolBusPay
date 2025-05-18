import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state.dart';
import '../../models/parent.dart';
import '../../models/driver.dart';
import '../../widgets/error_dialog.dart';

class AddParentScreen extends ConsumerStatefulWidget {
  final Driver driver;

  const AddParentScreen({super.key, required this.driver});

  @override
  ConsumerState<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends ConsumerState<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Parent'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                        prefixText: '+91 ',
                      ),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    ref.read(isLoadingProvider.notifier).state = true;

                    final database = ref.read(databaseProvider);
                    await database.insertParent(
                      Parent(
                        id: 0, // Auto-generated
                        name: _nameController.text,
                        mobileNumber: _mobileNumberController.text,
                        driverId: widget.driver.id,
                        paymentIds: [],
                      ),
                    );

                    // Invalidate the parents list to refresh it
                    ref.invalidate(parentsByDriverProvider(widget.driver.id));

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Parent added successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => ErrorDialog(
                          message: e.toString(),
                          onRetry: () {
                            // Retry logic if needed
                          },
                        ),
                      );
                    }
                  } finally {
                    ref.read(isLoadingProvider.notifier).state = false;
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add Parent'),
            ),
          ],
        ),
      ),
    );
  }
} 