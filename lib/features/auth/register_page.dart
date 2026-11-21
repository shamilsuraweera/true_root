import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
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
  bool _obscurePassword = true;
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
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: Gap.lg),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'username@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Email is required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: Gap.lg),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) =>
                  (value == null || value.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: Gap.lg),
            DropdownButtonFormField<String>(
              initialValue: _role,
              isExpanded: true,
              borderRadius: Radii.mdAll,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'farmer', child: Text('Farmer (Origin)')),
                DropdownMenuItem(value: 'trader', child: Text('Trader (Intermediary)')),
                DropdownMenuItem(value: 'exporter', child: Text('Exporter (Distribution)')),
                DropdownMenuItem(value: 'admin', child: Text('Admin (System)')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            const SizedBox(height: Gap.xl),
            PrimaryButton(label: 'Create account', loading: _isSubmitting, onPressed: _submit),
            const SizedBox(height: Gap.lg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Sign In'),
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

      if (auth.role == UserRole.admin && kIsWeb) {
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
