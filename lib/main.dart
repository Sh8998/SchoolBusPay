import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'screens/admin_dashboard.dart';
import 'screens/driver_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'utils/page_transitions.dart';
import 'services/payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop platforms only
  if (!kIsWeb) {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI for desktop only
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  // Create the ProviderContainer to access providers
  final container = ProviderContainer();

  // Check and create monthly payments if needed
  try {
    final paymentService = container.read(paymentServiceProvider);
    await paymentService.createMonthlyPayments();
  } catch (e) {
    debugPrint('Error creating monthly payments: $e');
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Bus Payment Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _navigateToRole(BuildContext context, Widget page) {
    Navigator.push(
      context,
      SlidePageRoute(
        child: page,
        direction: SlideDirection.up,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Icon(
                      Icons.directions_bus,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'School Bus Payment Tracker',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Select your role',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _buildRoleButton(
                    context,
                    'Admin',
                    Icons.admin_panel_settings,
                        () => _navigateToRole(context, const AdminDashboard()),
                  ),
                  const SizedBox(height: 10),
                  _buildRoleButton(
                    context,
                    'Driver',
                    Icons.drive_eta,
                        () => _navigateToRole(context, const DriverDashboard()),
                  ),
                  const SizedBox(height: 10),
                  _buildRoleButton(
                    context,
                    'Parent',
                    Icons.family_restroom,
                        () => _navigateToRole(context, const ParentDashboard()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context,
      String role,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(role),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
