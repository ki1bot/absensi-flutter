import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends Notifier<ThemeMode> {
  static const _storageKey = 'app_dark_mode';

  @override
  ThemeMode build() {
    _restore();

    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();

    final dark = preferences.getBool(_storageKey);

    if (dark == null) {
      state = ThemeMode.system;
      return;
    }

    state = dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_storageKey, dark);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
