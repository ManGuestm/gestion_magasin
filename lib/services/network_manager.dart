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
        debugPrint('🔴 Premier démarrage - Configuration réseau requise');
        return false; // Forcer la configuration
      }

      final mode = config['mode'] as NetworkMode;
      debugPrint('\n${'='*60}');
      debugPrint('🚀 INITIALISATION RÉSEAU');
      debugPrint('Mode: ${mode.name.toUpperCase()}');
      debugPrint('='*60);

      // Track which resources were successfully initialized for proper cleanup
      bool dbInitialized = false;
      bool networkInitialized = false;

      // Réutiliser l'instance singleton DatabaseService pour éviter les fuites de ressources
      try {
        if (mode == NetworkMode.server) {
          debugPrint('\n🖥️  MODE SERVEUR');
          debugPrint('  → Initialisation de la base de données locale');
          await _db.initializeLocal();
          dbInitialized = true;
          debugPrint('  ✅ Base locale initialisée');

          debugPrint('  → Démarrage du serveur réseau...');
          final serverStarted = await NetworkConfigService.initializeNetwork();
          if (!serverStarted) {
            throw Exception('Impossible de démarrer le serveur');
          }
          networkInitialized = true;
          debugPrint('  ✅ Serveur démarré avec succès');
          
        } else {
          // Mode client: NE PAS initialiser ici, attendre le login
          debugPrint('\n🌐 MODE CLIENT (RÉSEAU LOCAL)');
          debugPrint('  ⏳ Initialisation différée - En attente de connexion utilisateur');
          debugPrint('  → La connexion sera établie lors du login');
        }
      } catch (e) {
        // Rollback: only clean up resources that were actually initialized
        if (networkInitialized) {
          await NetworkConfigService.stopNetwork();
        }
        if (dbInitialized) {
          await _db.reset();
        }

        debugPrint('\n  ❌ ERREUR: $e');
        debugPrint('  → Rollback en cours...');
        rethrow;
      }

      _isInitialized = true;
      debugPrint('\n✅ Initialisation réseau RÉUSSIE');
      debugPrint('='*60 + '\n');
      return true;
    } catch (e) {
      debugPrint('\n❌ ERREUR INITIALISATION: $e');
      debugPrint('='*60 + '\n');
      _isInitialized = false;
      return false;
    }
  }

  /// Get current network mode for diagnostics
  Future<String> getDiagnostics() async {
    final config = await NetworkConfigService.loadConfig();
    final mode = config['mode'] as NetworkMode;
    final serverIp = config['serverIp'] as String;
    final port = config['port'] as String;
    
    return '''
═══════════════════════════════════════════════════════════════
📊 DIAGNOSTIC RÉSEAU
═══════════════════════════════════════════════════════════════
🔍 Statut Initialisation: ${_isInitialized ? '✅ OUI' : '❌ NON'}
🌐 Mode Actuel: ${mode.name.toUpperCase()}
📡 Serveur: $serverIp:$port
👤 Utilisateur: ${config['username']}
═══════════════════════════════════════════════════════════════
''';
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
