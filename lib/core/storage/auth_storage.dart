import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/saved_account.dart';

class AuthStorage {
  static const _accountsKey = 'saved_accounts';
  static const _activeEmailKey = 'active_account_email';
  static const _tokenPrefix = 'auth_token_';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _tokenKey(String email) => '$_tokenPrefix$email';

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

  Future<void> upsertAccount(SavedAccount account, {String? accessToken}) async {
    final accounts = await loadAccounts();
    final updated = [
      for (final existing in accounts)
        if (existing.email != account.email) existing,
      account,
    ];
    await saveAccounts(updated);
    await setActiveEmail(account.email);
    if (accessToken != null && accessToken.isNotEmpty) {
      await _saveToken(account.email, accessToken);
    }
  }

  Future<void> removeAccount(String email) async {
    final accounts = await loadAccounts();
    final updated = accounts.where((item) => item.email != email).toList();
    await saveAccounts(updated);
    await _deleteToken(email);
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
    final account = accounts.where((item) => item.email == email).firstOrNull;
    if (account == null) {
      return null;
    }
    final token = await _loadToken(email);
    return account.copyWith(accessToken: token);
  }

  Future<void> _saveToken(String email, String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey(email), token);
      return;
    }
    await _secureStorage.write(key: _tokenKey(email), value: token);
  }

  Future<String?> _loadToken(String email) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey(email));
    }
    return _secureStorage.read(key: _tokenKey(email));
  }

  Future<void> _deleteToken(String email) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey(email));
      return;
    }
    await _secureStorage.delete(key: _tokenKey(email));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
