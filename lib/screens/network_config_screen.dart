import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/network_config_service.dart';
import '../services/network_diagnostic_service.dart';

class NetworkConfigScreen extends StatefulWidget {
  const NetworkConfigScreen({super.key});

  @override
  State<NetworkConfigScreen> createState() => _NetworkConfigScreenState();
}

class _NetworkConfigScreenState extends State<NetworkConfigScreen> {
  NetworkMode _selectedMode = NetworkMode.server;
  final _formKey = GlobalKey<FormState>();
  final _serverIpController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final config = await NetworkConfigService.loadConfig();
    setState(() {
      _selectedMode = config['mode'];
      _serverIpController.text = config['serverIp'];
      _portController.text = config['port'];
      _usernameController.text = config['username'];
      _passwordController.text = config['password'];
    });
  }

  /// Validate server IP address format
  String? _validateServerIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse IP du serveur est requise';
    }

    // Simple IP address format validation
    final ipPattern = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipPattern.hasMatch(value)) {
      return 'Format d\'adresse IP invalide (ex: 192.168.1.100)';
    }

    return null;
  }

  /// Validate port number
  String? _validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le port est requis';
    }

    final port = int.tryParse(value);
    if (port == null) {
      return 'Le port doit être un nombre';
    }

    if (port < 1 || port > 65535) {
      return 'Le port doit être entre 1 et 65535';
    }

    return null;
  }

  /// Validate username
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }

    if (value.isEmpty) {
      return 'Le nom d\'utilisateur doit contenir au moins 1 caractère';
    }

    return null;
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.isEmpty) {
      return 'Le mot de passe doit contenir au moins 1 caractère';
    }

    return null;
  }

  Future<void> _testConnection() async {
    if (_selectedMode != NetworkMode.client) return;

    final serverIp = _serverIpController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    if (serverIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir l\'adresse IP du serveur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTestingConnection = true);

    try {
      // Test de connexion HTTP simple
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.get(serverIp, port, '/api/health');
      final response = await request.close();
      client.close();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion réussie au serveur !'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Serveur non accessible (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  Future<void> _showDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Diagnostic en cours...')],
        ),
      ),
    );

    final results = await NetworkDiagnosticService.runDiagnostic();
    final report = NetworkDiagnosticService.formatDiagnosticReport(results);

    if (mounted) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rapport de diagnostic'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
        ),
      );
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      // Validate client configuration if in client mode
      if (_selectedMode == NetworkMode.client) {
        if (!_formKey.currentState!.validate()) {
          debugPrint('❌ Validation du formulaire échouée');
          return;
        }
      }

      await NetworkConfigService.saveConfig(
        mode: _selectedMode,
        serverIp: _selectedMode == NetworkMode.client ? _serverIpController.text : null,
        port: _selectedMode == NetworkMode.client ? _portController.text : null,
        username: _selectedMode == NetworkMode.client ? _usernameController.text : null,
        password: _selectedMode == NetworkMode.client ? _passwordController.text : null,
      );

      // Vérifier si c'est le premier démarrage
      final prefs = await SharedPreferences.getInstance();
      final wasFirstRun = !prefs.containsKey('app_configured');

      if (wasFirstRun) {
        // Marquer l'application comme configurée
        await prefs.setBool('app_configured', true);
      }

      if (mounted) {
        if (wasFirstRun) {
          // Rediriger vers SplashScreen pour initialiser avec la nouvelle config
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Configuration sauvegardée. Redémarrez l\'application pour appliquer les changements.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration réseau'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode de fonctionnement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 20),

                  // Mode Serveur
                  GestureDetector(
                    onTap: () => setState(() => _selectedMode = NetworkMode.server),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedMode == NetworkMode.server
                              ? Colors.indigo[600]!
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedMode == NetworkMode.server
                                    ? Colors.indigo[600]!
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: _selectedMode == NetworkMode.server
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.indigo[600],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Serveur', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  'Cet ordinateur hébergera la base de données',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mode Client
                  GestureDetector(
                    onTap: () => setState(() => _selectedMode = NetworkMode.client),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedMode == NetworkMode.client
                              ? Colors.indigo[600]!
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedMode == NetworkMode.client
                                    ? Colors.indigo[600]!
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: _selectedMode == NetworkMode.client
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.indigo[600],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  'Cet ordinateur se connectera au serveur',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Configuration Client
                  if (_selectedMode == NetworkMode.client) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Configuration du serveur',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _serverIpController,
                            decoration: InputDecoration(
                              labelText: 'Adresse IP du serveur',
                              hintText: '192.168.1.100',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.computer),
                            ),
                            validator: _validateServerIp,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _portController,
                            decoration: InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.settings_ethernet),
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validatePort,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: _validatePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.wifi_find),
                          label: Text(_isTestingConnection ? 'Test en cours...' : 'Tester'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _showDiagnostic,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Diagnostic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Boutons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveConfiguration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Sauvegarder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
