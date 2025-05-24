import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../admin_dashboard.dart';
import '../driver_dashboard.dart';
import '../parent_dashboard.dart';
import '../../widgets/error_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Check for admin login
      if (email == AuthService.adminEmail && password == AuthService.adminPassword) {
        _navigateToRoleDashboard(UserRole.admin);
        return;
      }

      final fb.User? firebaseUser = await authService.signInWithEmailAndPassword(email, password);

      if (firebaseUser != null) {
        final role = await authService.getUserRole(firebaseUser.uid);
        _navigateToRoleDashboard(role);
      }
    } on fb.FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: e.message ?? 'Login failed. Please check your credentials.',
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'An error occurred: ${e.toString()}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRoleDashboard(UserRole role) {
    Widget dashboard;
    switch (role) {
      case UserRole.admin:
        dashboard = const AdminDashboard();
        break;
      case UserRole.driver:
        dashboard = const DriverDashboard();
        break;
      case UserRole.parent:
      default:
        dashboard = const ParentDashboard();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => dashboard),
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
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus, size: 80),
                      const SizedBox(height: 20),
                      Text(
                        'School Bus App',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _login,
                                child: const Text('LOGIN'),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: const Text("Don't have an account? Register"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}