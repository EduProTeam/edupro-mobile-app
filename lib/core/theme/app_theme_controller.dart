import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device preference that survives sign-out and application restarts.
class AppThemeController extends ChangeNotifier {
  AppThemeController({
    ThemeMode initialMode = ThemeMode.light,
    Future<bool> Function(bool)? saveDarkMode,
  }) : _isDark = initialMode == ThemeMode.dark,
       _saveDarkMode = saveDarkMode ?? _ignoreSave;

  static const preferenceKey = 'edupro.darkMode';
  final Future<bool> Function(bool) _saveDarkMode;
  bool _isDark;
  Future<void> _pendingSave = Future.value();

  bool get isDark => _isDark;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  static Future<bool> _ignoreSave(bool _) async => true;

  static Future<AppThemeController> load() async {
    SharedPreferences? preferences;
    var isDark = false;
    try {
      preferences = await SharedPreferences.getInstance();
      isDark = preferences.getBool(preferenceKey) ?? false;
    } catch (_) {
      // A preference read failure must not prevent the app from starting.
    }
    return AppThemeController(
      initialMode: isDark ? ThemeMode.dark : ThemeMode.light,
      saveDarkMode: (value) async {
        final store = preferences ?? await SharedPreferences.getInstance();
        return store.setBool(preferenceKey, value);
      },
    );
  }

  Future<bool> toggle() => setDarkMode(!_isDark);

  Future<bool> setDarkMode(bool value) {
    if (_isDark == value) return Future.value(true);
    _isDark = value;
    notifyListeners();
    // Preserve tap order even when the preference backend writes slowly.
    final save = _pendingSave.then((_) async {
      try {
        return await _saveDarkMode(value);
      } catch (_) {
        return false;
      }
    });
    _pendingSave = save.then<void>((_) {});
    return save;
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}
