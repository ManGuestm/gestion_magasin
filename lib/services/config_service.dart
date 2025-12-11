import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  SharedPreferences? _prefs;

  // Configuration par défaut
  static const Map<String, dynamic> _defaultConfig = {
    'auto_backup_enabled': true,
    'auto_backup_interval_hours': 6,
    'stock_alert_enabled': true,
    'stock_alert_threshold': 10,
    'currency_symbol': 'Ar',
    'date_format': 'dd/MM/yyyy',
    'decimal_places': 2,
    'page_size': 25,
    'session_timeout_minutes': 30,
    'theme_mode': 'system',
    'language': 'fr',
  };

  /// Initialise le service de configuration
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialiser les valeurs par défaut si elles n'existent pas
    for (final entry in _defaultConfig.entries) {
      if (!_prefs!.containsKey(entry.key)) {
        await _setValue(entry.key, entry.value);
      }
    }
  }

  /// Obtient une valeur de configuration
  T get<T>(String key, {T? defaultValue}) {
    if (_prefs == null) return defaultValue ?? _defaultConfig[key] as T;

    if (T == String) {
      return _prefs!.getString(key) as T? ?? defaultValue ?? _defaultConfig[key] as T;
    } else if (T == int) {
      return _prefs!.getInt(key) as T? ?? defaultValue ?? _defaultConfig[key] as T;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T? ?? defaultValue ?? _defaultConfig[key] as T;
    } else if (T == bool) {
      return _prefs!.getBool(key) as T? ?? defaultValue ?? _defaultConfig[key] as T;
    } else {
      return defaultValue ?? _defaultConfig[key] as T;
    }
  }

  /// Définit une valeur de configuration
  Future<void> set<T>(String key, T value) async {
    await _setValue(key, value);
    notifyListeners();
  }

  Future<void> _setValue<T>(String key, T value) async {
    if (_prefs == null) return;

    if (T == String) {
      await _prefs!.setString(key, value as String);
    } else if (T == int) {
      await _prefs!.setInt(key, value as int);
    } else if (T == double) {
      await _prefs!.setDouble(key, value as double);
    } else if (T == bool) {
      await _prefs!.setBool(key, value as bool);
    }
  }

  /// Remet à zéro toute la configuration
  Future<void> resetToDefaults() async {
    if (_prefs == null) return;

    await _prefs!.clear();
    for (final entry in _defaultConfig.entries) {
      await _setValue(entry.key, entry.value);
    }
    notifyListeners();
  }

  /// Exporte la configuration
  Map<String, dynamic> exportConfig() {
    if (_prefs == null) return {};

    final config = <String, dynamic>{};
    for (final key in _defaultConfig.keys) {
      config[key] = get(key);
    }
    return config;
  }

  /// Importe une configuration
  Future<void> importConfig(Map<String, dynamic> config) async {
    for (final entry in config.entries) {
      if (_defaultConfig.containsKey(entry.key)) {
        await _setValue(entry.key, entry.value);
      }
    }
    notifyListeners();
  }

  // Getters pour les configurations courantes
  bool get autoBackupEnabled => get<bool>('auto_backup_enabled');
  int get autoBackupIntervalHours => get<int>('auto_backup_interval_hours');
  bool get stockAlertEnabled => get<bool>('stock_alert_enabled');
  int get stockAlertThreshold => get<int>('stock_alert_threshold');
  String get currencySymbol => get<String>('currency_symbol');
  String get dateFormat => get<String>('date_format');
  int get decimalPlaces => get<int>('decimal_places');
  int get pageSize => get<int>('page_size');
  int get sessionTimeoutMinutes => get<int>('session_timeout_minutes');
  String get themeMode => get<String>('theme_mode');
  String get language => get<String>('language');
}
