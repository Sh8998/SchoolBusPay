import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../driver_dashboard.dart';
import '../parent_dashboard.dart';
import '../../widgets/error_dialog.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.parent;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(message: 'Passwords do not match'),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);

      final fb.User? user = await authService.registerUser(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );

      if (user != null) {
        _navigateToRoleDashboard(_selectedRole);
      }
    } on fb.FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: e.message ?? 'Registration failed',
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'Registration error: ${e.toString()}',
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Your Role:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<UserRole>(
                title: const Text('Parent'),
                value: UserRole.parent,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              RadioListTile<UserRole>(
                title: const Text('Driver'),
                value: UserRole.driver,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('REGISTER'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}