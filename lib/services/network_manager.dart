import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_service.dart';
import 'network_config_service.dart';

class NetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance => _instance ??= NetworkManager._();
  NetworkManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Reuse the singleton DatabaseService instance to avoid resource leaks on retries
  late final DatabaseService _db = DatabaseService();

  Future<bool> initialize() async {
    try {
      // Vérifier si c'est le premier démarrage
      final config = await NetworkConfigService.loadConfig();
      final isFirstRun = await _isFirstRun();

      if (isFirstRun) {
        debugPrint('Premier démarrage - Configuration réseau requise');
        return false; // Forcer la configuration
      }

      final mode = config['mode'] as NetworkMode;
      debugPrint('Initialisation réseau en mode: ${mode.name}');

      // Réutiliser l'instance singleton DatabaseService pour éviter les fuites de ressources
      try {
        if (mode == NetworkMode.server) {
          _db.setNetworkMode(false);
          await _db.initialize();
          final serverStarted = await NetworkConfigService.initializeNetwork();
          if (!serverStarted) {
            throw Exception('Impossible de démarrer le serveur');
          }
        } else {
          _db.setNetworkMode(true);
          final connected = await NetworkConfigService.initializeNetwork();
          if (!connected) {
            throw Exception('Impossible de se connecter au serveur ${config['serverIp']}:${config['port']}');
          }
          await _db.initialize();
        }
      } catch (e) {
        // Rollback: disable network mode and disconnect
        _db.setNetworkMode(false);
        await NetworkConfigService.stopNetwork();

        // Reset DatabaseService to avoid partial state for retry attempts
        await _db.reset();
        debugPrint('Rollback réseau suite à erreur: $e');
        rethrow;
      }

      _isInitialized = true;
      debugPrint('Initialisation réseau réussie');
      return true;
    } catch (e) {
      debugPrint('Erreur initialisation réseau: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> shutdown() async {
    await NetworkConfigService.stopNetwork();
    _isInitialized = false;
  }

  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('network_mode');
  }
}
