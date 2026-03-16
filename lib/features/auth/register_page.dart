import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';
import 'state/auth_provider.dart';
import 'widgets/auth_shell.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'farmer';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Register',
      subtitle: 'True Root',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full name', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your full name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            const Text('Email', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'username@email.com'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Password', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'At least 6 characters'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Min 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Role', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _role,
              dropdownColor: const Color(0xFF2A76C5),
              decoration: const InputDecoration(),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                DropdownMenuItem(value: 'trader', child: Text('Trader')),
                DropdownMenuItem(value: 'exporter', child: Text('Exporter')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A355E),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(authControllerProvider);
      await controller.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
      );
      final auth = ref.read(authProvider);
      if (!mounted) return;
      if (kIsWeb) {
        if (auth.role != UserRole.admin) {
          ref.read(authProvider.notifier).logout();
          await ref.read(authStorageProvider).clearActiveEmail();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web portal is admin-only. Use an admin account.'),
            ),
          );
          return;
        }
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
