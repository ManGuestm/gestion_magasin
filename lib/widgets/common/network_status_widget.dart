import 'package:flutter/material.dart';

import '../../services/network_client.dart';
import '../../services/network_config_service.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  NetworkMode? _mode;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // Vérifier le statut périodiquement
    _startStatusCheck();
  }

  void _startStatusCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkConnection();
        _startStatusCheck();
      }
    });
  }

  Future<void> _loadStatus() async {
    final config = await NetworkConfigService.loadConfig();
    setState(() {
      _mode = config['mode'] as NetworkMode;
    });
    _checkConnection();
  }

  void _checkConnection() {
    if (_mode == NetworkMode.client) {
      setState(() {
        _isConnected = NetworkClient.instance.isConnected;
      });
    } else {
      setState(() {
        _isConnected = true; // Serveur toujours "connecté"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_mode == NetworkMode.server) {
      return Colors.blue[600]!;
    }
    return _isConnected ? Colors.green[600]! : Colors.red[600]!;
  }

  IconData _getStatusIcon() {
    if (_mode == NetworkMode.server) {
      return Icons.dns;
    }
    return _isConnected ? Icons.wifi : Icons.wifi_off;
  }

  String _getStatusText() {
    if (_mode == NetworkMode.server) {
      return 'Serveur';
    }
    return _isConnected ? 'Connecté' : 'Déconnecté';
  }
}