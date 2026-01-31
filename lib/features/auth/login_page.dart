import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import 'state/auth_provider.dart';
import 'models/saved_account.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_accounts.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saved accounts',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                ..._accounts.map(
                  (account) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(account.email),
                      subtitle: account.role != null ? Text(account.role!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeAccount(account.email),
                          ),
                          IconButton(
                            icon: const Icon(Icons.login),
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
                const SizedBox(height: 12),
              ] else if (_loadingAccounts) ...[
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _rememberAccount,
                onChanged: (value) => setState(() => _rememberAccount = value ?? true),
                contentPadding: EdgeInsets.zero,
                title: const Text('Remember this account'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text('Create account'),
              ),
            ],
          ),
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
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
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
