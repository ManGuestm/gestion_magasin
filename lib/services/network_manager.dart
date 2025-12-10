import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'network_config_service.dart';

class NetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance => _instance ??= NetworkManager._();
  NetworkManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      // Charger la configuration réseau
      final config = await NetworkConfigService.loadConfig();
      final mode = config['mode'] as NetworkMode;

      // Initialiser le réseau selon le mode
      if (mode == NetworkMode.server) {
        // Mode serveur : initialiser la base locale puis démarrer le serveur
        await DatabaseService().initialize();
        await NetworkConfigService.initializeNetwork();
      } else {
        // Mode client : se connecter au serveur
        DatabaseService().setNetworkMode(true);
        await NetworkConfigService.initializeNetwork();
        await DatabaseService().initialize();
      }

      _isInitialized = true;
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
}