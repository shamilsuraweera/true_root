import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/saved_account.dart';

class AuthStorage {
  static const _accountsKey = 'saved_accounts';
  static const _activeEmailKey = 'active_account_email';

  Future<List<SavedAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SavedAccount.fromJson(item as Map<String, dynamic>))
        .where((account) => account.email.isNotEmpty)
        .toList();
  }

  Future<void> saveAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(accounts.map((item) => item.toJson()).toList());
    await prefs.setString(_accountsKey, raw);
  }

  Future<void> upsertAccount(SavedAccount account) async {
    final accounts = await loadAccounts();
    final updated = [
      for (final existing in accounts)
        if (existing.email != account.email) existing,
      account,
    ];
    await saveAccounts(updated);
    await setActiveEmail(account.email);
  }

  Future<void> removeAccount(String email) async {
    final accounts = await loadAccounts();
    final updated = accounts.where((item) => item.email != email).toList();
    await saveAccounts(updated);
    final active = await getActiveEmail();
    if (active == email) {
      await clearActiveEmail();
    }
  }

  Future<String?> getActiveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeEmailKey);
  }

  Future<void> setActiveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeEmailKey, email);
  }

  Future<void> clearActiveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeEmailKey);
  }

  Future<SavedAccount?> loadActiveAccount() async {
    final email = await getActiveEmail();
    if (email == null || email.isEmpty) {
      return null;
    }
    final accounts = await loadAccounts();
    return accounts.where((item) => item.email == email).firstOrNull;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
