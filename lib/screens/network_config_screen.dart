import 'package:flutter/material.dart';

import '../services/network_config_service.dart';

class NetworkConfigScreen extends StatefulWidget {
  const NetworkConfigScreen({super.key});

  @override
  State<NetworkConfigScreen> createState() => _NetworkConfigScreenState();
}

class _NetworkConfigScreenState extends State<NetworkConfigScreen> {
  NetworkMode _selectedMode = NetworkMode.server;
  final _serverIpController = TextEditingController();
  final _portController = TextEditingController(text: '3306');

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final config = await NetworkConfigService.loadConfig();
    setState(() {
      _selectedMode = config['mode'];
      _serverIpController.text = config['serverIp'];
      _portController.text = config['port'];
    });
  }

  Future<void> _saveConfiguration() async {
    try {
      await NetworkConfigService.saveConfig(
        mode: _selectedMode,
        serverIp: _selectedMode == NetworkMode.client ? _serverIpController.text : null,
        port: _selectedMode == NetworkMode.client ? _portController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée. Redémarrez l\'application pour appliquer les changements.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode de fonctionnement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),

                // Mode Serveur
                GestureDetector(
                  onTap: () => setState(() => _selectedMode = NetworkMode.server),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedMode == NetworkMode.server ? Colors.indigo[600]! : Colors.grey[300]!,
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
                              Text('Cet ordinateur hébergera la base de données',
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        color: _selectedMode == NetworkMode.client ? Colors.indigo[600]! : Colors.grey[300]!,
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
                              Text('Cet ordinateur se connectera au serveur',
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serverIpController,
                    decoration: InputDecoration(
                      labelText: 'Adresse IP du serveur',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.computer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 32),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
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
    );
  }
}
