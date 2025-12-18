import 'dart:io';

import 'package:flutter/material.dart';

import 'network_client.dart';
import 'network_config_service.dart';

class NetworkDiagnosticService {
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Vérifier la configuration
      final config = await NetworkConfigService.loadConfig();
      results['config'] = config;
      results['configValid'] = config['serverIp'].toString().isNotEmpty;
      
      if (config['mode'] == NetworkMode.client) {
        final serverIp = config['serverIp'] as String;
        final port = int.tryParse(config['port']) ?? 8080;
        
        // 2. Test ping réseau
        results['pingTest'] = await _testPing(serverIp);
        
        // 3. Test connexion HTTP
        results['httpTest'] = await _testHttp(serverIp, port);
        
        // 4. Test connexion complète
        results['connectionTest'] = await NetworkClient.instance.testConnection(serverIp, port);
        
        // 5. État actuel de la connexion
        results['currentlyConnected'] = NetworkClient.instance.isConnected;
      }
      
      results['success'] = true;
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  static Future<bool> _testPing(String host) async {
    try {
      final result = await Process.run('ping', ['-n', '1', host]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Erreur ping: $e');
      return false;
    }
  }
  
  static Future<bool> _testHttp(String host, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.get(host, port, '/api/health');
      final response = await request.close();
      
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur HTTP: $e');
      return false;
    }
  }
  
  static String formatDiagnosticReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNOSTIC RÉSEAU ===\n');
    
    if (results['success'] == true) {
      final config = results['config'] as Map<String, dynamic>;
      buffer.writeln('Configuration:');
      buffer.writeln('  Mode: ${config['mode']}');
      buffer.writeln('  Serveur: ${config['serverIp']}:${config['port']}');
      buffer.writeln('  Config valide: ${results['configValid']}\n');
      
      if (config['mode'].toString().contains('client')) {
        buffer.writeln('Tests de connectivité:');
        buffer.writeln('  Ping: ${results['pingTest'] ? "✓" : "✗"}');
        buffer.writeln('  HTTP: ${results['httpTest'] ? "✓" : "✗"}');
        buffer.writeln('  Connexion: ${results['connectionTest'] ? "✓" : "✗"}');
        buffer.writeln('  Actuellement connecté: ${results['currentlyConnected'] ? "✓" : "✗"}');
      }
    } else {
      buffer.writeln('Erreur: ${results['error']}');
    }
    
    return buffer.toString();
  }
}