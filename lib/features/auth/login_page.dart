import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';
import 'state/auth_provider.dart';
import 'models/saved_account.dart';
import 'widgets/auth_shell.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _rememberAccount = true;
  bool _loadingAccounts = true;
  List<SavedAccount> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Login',
      subtitle: 'True Root',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_accounts.isNotEmpty) ...[
              Text(
                'Saved accounts',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._accounts.map(
                (account) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      account.email,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: account.role != null
                        ? Text(
                            account.role!,
                            style: const TextStyle(color: Colors.white70),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: () => _removeAccount(account.email),
                        ),
                        IconButton(
                          icon: const Icon(Icons.login, color: Colors.white),
                          onPressed: _isSubmitting
                              ? null
                              : () => _quickLogin(account),
                        ),
                      ],
                    ),
                    onTap: () {
                      _emailController.text = account.email;
                      _passwordController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_loadingAccounts)
              const SizedBox(height: 8),
            const Text('Email', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'username@email.com',
              ),
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
              decoration: const InputDecoration(hintText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            CheckboxListTile(
              value: _rememberAccount,
              onChanged: (value) =>
                  setState(() => _rememberAccount = value ?? true),
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.white,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white70),
              title: const Text(
                'Remember this account',
                style: TextStyle(color: Colors.white),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
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
                    : const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _SocialStub(icon: Icons.g_mobiledata),
                  _SocialStub(icon: Icons.code),
                  _SocialStub(icon: Icons.facebook),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(
                  'Need an account? Register',
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
      await controller.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        remember: _rememberAccount,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loadAccounts() async {
    final storage = ref.read(authStorageProvider);
    final accounts = await storage.loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _loadingAccounts = false;
    });
  }

  Future<void> _removeAccount(String email) async {
    final storage = ref.read(authStorageProvider);
    await storage.removeAccount(email);
    await _loadAccounts();
  }

  Future<void> _quickLogin(SavedAccount account) async {
    _emailController.text = account.email;
    _passwordController.clear();
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter your password to continue')),
    );
  }
}

class _SocialStub extends StatelessWidget {
  final IconData icon;

  const _SocialStub({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF0A355E)),
    );
  }
}
