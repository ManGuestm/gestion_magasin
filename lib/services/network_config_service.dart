import 'package:shared_preferences/shared_preferences.dart';

enum NetworkMode { server, client }

class NetworkConfigService {
  static const String _modeKey = 'network_mode';
  static const String _serverIpKey = 'server_ip';
  static const String _portKey = 'server_port';

  static Future<void> saveConfig({
    required NetworkMode mode,
    String? serverIp,
    String? port,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    if (serverIp != null) await prefs.setString(_serverIpKey, serverIp);
    if (port != null) await prefs.setString(_portKey, port);
  }

  static Future<Map<String, dynamic>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mode': NetworkMode.values.firstWhere(
        (e) => e.name == prefs.getString(_modeKey),
        orElse: () => NetworkMode.server,
      ),
      'serverIp': prefs.getString(_serverIpKey) ?? '',
      'port': prefs.getString(_portKey) ?? '3306',
    };
  }
}