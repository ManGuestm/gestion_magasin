import 'package:shared_preferences/shared_preferences.dart';

import 'network_client.dart';
import 'network_server.dart';

enum NetworkMode { server, client }

class NetworkConfigService {
  static const String _modeKey = 'network_mode';
  static const String _serverIpKey = 'server_ip';
  static const String _portKey = 'server_port';
  static const String _usernameKey = 'network_username';
  static const String _passwordKey = 'network_password';

  static Future<void> saveConfig({
    required NetworkMode mode,
    String? serverIp,
    String? port,
    String? username,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    if (serverIp != null) await prefs.setString(_serverIpKey, serverIp);
    if (port != null) await prefs.setString(_portKey, port);
    if (username != null) await prefs.setString(_usernameKey, username);
    if (password != null) await prefs.setString(_passwordKey, password);
  }

  static Future<Map<String, dynamic>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mode': NetworkMode.values.firstWhere(
        (e) => e.name == prefs.getString(_modeKey),
        orElse: () => NetworkMode.server,
      ),
      'serverIp': prefs.getString(_serverIpKey) ?? '',
      'port': prefs.getString(_portKey) ?? '8080',
      'username': prefs.getString(_usernameKey) ?? 'admin',
      'password': prefs.getString(_passwordKey) ?? 'admin123',
    };
  }

  static Future<bool> initializeNetwork() async {
    final config = await loadConfig();
    final mode = config['mode'] as NetworkMode;
    
    if (mode == NetworkMode.server) {
      final port = int.tryParse(config['port']) ?? 8080;
      return await NetworkServer.instance.start(port: port);
    } else {
      final serverIp = config['serverIp'] as String;
      final port = int.tryParse(config['port']) ?? 8080;
      
      if (serverIp.isEmpty) {
        throw Exception('Adresse IP du serveur non configurée');
      }
      
      return await NetworkClient.instance.connect(serverIp, port);
    }
  }

  static Future<void> stopNetwork() async {
    await NetworkServer.instance.stop();
    await NetworkClient.instance.disconnect();
  }
}