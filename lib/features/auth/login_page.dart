import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../core/api/api_config.dart';
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
  bool _obscurePassword = true;
  bool _rememberAccount = true;
  bool _loadingAccounts = true;
  List<SavedAccount> _accounts = [];

  static const _demoAccounts = [
    {'role': 'Admin', 'email': 'admin@trueroot.com', 'pass': 'admin123', 'color': Color(0xFF003366)},
    {'role': 'Farmer', 'email': 'farmer@trueroot.com', 'pass': 'farmer123', 'color': Color(0xFF2E7D32)},
    {'role': 'Trader', 'email': 'trader@trueroot.com', 'pass': 'trader123', 'color': Color(0xFFEF6C00)},
    {'role': 'Exporter', 'email': 'exporter@trueroot.com', 'pass': 'exporter123', 'color': Color(0xFF6A1B9A)},
  ];

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
      trailing: IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
        tooltip: 'Server Connection Settings',
        onPressed: _showServerSettingsDialog,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo accounts quick select
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Demo Accounts (1-Tap Fill)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _demoAccounts.map((demo) {
                      return InkWell(
                        onTap: () {
                          _emailController.text = demo['email'] as String;
                          _passwordController.text = demo['pass'] as String;
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (demo['color'] as Color).withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            demo['role'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

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
                          onPressed: _isSubmitting ? null : () => _quickLogin(account),
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

            const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'username@email.com',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                fillColor: Colors.white.withValues(alpha: 0.15),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            const SizedBox(height: 14),
            const Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                fillColor: Colors.white.withValues(alpha: 0.15),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _rememberAccount,
              onChanged: (value) => setState(() => _rememberAccount = value ?? true),
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.white,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white70),
              title: const Text(
                'Remember this account',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A355E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(
                  'Need an account? Register',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  Future<void> _showServerSettingsDialog() async {
    final urlController = TextEditingController(text: ApiConfig.baseUrl);
    String testStatus = '';
    Color testColor = Colors.grey;
    bool testing = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: Color(0xFF1569C7)),
              SizedBox(width: 8),
              Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NestJS Backend API Base URL:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'http://127.0.0.1:3000',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quick Presets:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Localhost (3000)'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'http://127.0.0.1:3000';
                          testStatus = '';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Android (10.0.2.2)'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'http://10.0.2.2:3000';
                          testStatus = '';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: testing
                          ? null
                          : () async {
                              setDialogState(() {
                                testing = true;
                                testStatus = 'Testing connection...';
                                testColor = Colors.blue;
                              });
                              final ok = await ApiConfig.testConnection(urlController.text);
                              setDialogState(() {
                                testing = false;
                                if (ok) {
                                  testStatus = 'Connected successfully!';
                                  testColor = Colors.green;
                                } else {
                                  testStatus = 'Could not reach server';
                                  testColor = Colors.red;
                                }
                              });
                            },
                      icon: testing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check, size: 18),
                      label: const Text('Test Connection'),
                    ),
                    const SizedBox(width: 8),
                    if (testStatus.isNotEmpty)
                      Expanded(
                        child: Text(
                          testStatus,
                          style: TextStyle(fontSize: 12, color: testColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = urlController.text.trim();
                if (newUrl.isNotEmpty) {
                  await ApiConfig.setBaseUrl(newUrl);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server set to: ${ApiConfig.baseUrl}')),
                    );
                  }
                }
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
