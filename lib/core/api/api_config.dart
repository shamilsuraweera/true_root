import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _storageKey = 'custom_base_url';

  static String _defaultUrl() {
    if (kIsWeb) return 'http://127.0.0.1:3000';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:3000';
    }
    // Android emulator default (can be updated to LAN IP for physical device)
    return 'http://10.0.2.2:3000';
  }

  static String _currentBaseUrl = _defaultUrl();

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _currentBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _currentBaseUrl);
    } catch (_) {}
  }

  static Future<bool> testConnection([String? testUrl]) async {
    try {
      final target = (testUrl ?? _currentBaseUrl).trim();
      final url = Uri.parse('$target/health');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String extractErrorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.map((e) => e.toString()).join(', ');
        }
        if (body['error'] is String && (body['error'] as String).isNotEmpty) {
          return body['error'] as String;
        }
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}
