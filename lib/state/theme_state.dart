import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/theme_storage.dart';

final themeStorageProvider = Provider<ThemeStorage>((ref) {
  return ThemeStorage();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this.storage) : super(ThemeMode.light) {
    _load();
  }

  final ThemeStorage storage;

  Future<void> _load() async {
    final saved = await storage.loadThemeMode();
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await storage.saveThemeMode(next == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.read(themeStorageProvider);
  return ThemeNotifier(storage);
});
