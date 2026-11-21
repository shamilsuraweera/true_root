import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
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
    {'role': 'Admin', 'email': 'admin@trueroot.com', 'pass': 'admin123', 'color': Color(0xFF005C50)},
    {'role': 'Farmer', 'email': 'farmer@trueroot.com', 'pass': 'farmer123', 'color': Color(0xFF2E7D32)},
    {'role': 'Trader', 'email': 'trader@trueroot.com', 'pass': 'trader123', 'color': Color(0xFFEF6C00)},
    {'role': 'Exporter', 'email': 'exporter@trueroot.com', 'pass': 'exporter123', 'color': Color(0xFF007E6E)},
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
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Server Connection Settings',
        onPressed: _showServerSettingsDialog,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DemoAccounts(
              accounts: _demoAccounts,
              onPick: (demo) => setState(() {
                _emailController.text = demo['email'] as String;
                _passwordController.text = demo['pass'] as String;
              }),
            ),
            if (_accounts.isNotEmpty) ...[
              Text('Saved accounts', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Gap.sm),
              ..._accounts.map(
                (account) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => setState(() {
                      _emailController.text = account.email;
                      _passwordController.clear();
                    }),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(account.email.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(account.email, overflow: TextOverflow.ellipsis),
                      subtitle: account.role != null ? Text(account.role!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeAccount(account.email),
                          ),
                          IconButton(
                            tooltip: 'Sign in',
                            icon: const Icon(Icons.login_rounded),
                            onPressed: _isSubmitting ? null : () => _quickLogin(account),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.sm),
            ] else if (_loadingAccounts)
              const SizedBox(height: Gap.sm),
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
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
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
                  (value == null || value.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: Gap.xs),
            CheckboxListTile(
              value: _rememberAccount,
              onChanged: (value) => setState(() => _rememberAccount = value ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Remember this account'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: Gap.md),
            PrimaryButton(label: 'Sign in', loading: _isSubmitting, onPressed: _submit),
            const SizedBox(height: Gap.lg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text('Need an account? Register'),
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
              Icon(Icons.dns_outlined, color: AppColors.primary),
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
                                testColor = AppColors.primary;
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

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.accounts, required this.onPick});
  final List<Map<String, Object>> accounts;
  final ValueChanged<Map<String, Object>> onPick;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      margin: const EdgeInsets.only(bottom: Gap.lg),
      decoration: BoxDecoration(
        color: c.primaryContainer.withValues(alpha: 0.5),
        borderRadius: Radii.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Demo accounts - tap to fill',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final demo in accounts)
                ActionChip(
                  label: Text(demo['role'] as String),
                  avatar: CircleAvatar(
                    radius: 5,
                    backgroundColor: demo['color'] as Color,
                  ),
                  onPressed: () => onPick(demo),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
