import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../services/network_client.dart';

/// Widget wrapper pour activer la synchronisation temps réel
/// Enveloppe les écrans qui doivent se rafraîchir automatiquement
class RealtimeSyncWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDataChanged;

  const RealtimeSyncWrapper({super.key, required this.child, this.onDataChanged});

  @override
  State<RealtimeSyncWrapper> createState() => _RealtimeSyncWrapperState();
}

class _RealtimeSyncWrapperState extends State<RealtimeSyncWrapper> {
  final DatabaseService _db = DatabaseService();
  final NetworkClient _client = NetworkClient.instance;

  @override
  void initState() {
    super.initState();
    if (_db.isNetworkMode) {
      _client.addChangeListener(_onServerChange);
      debugPrint('🎧 Écoute temps réel activée');
    }
  }

  @override
  void dispose() {
    if (_db.isNetworkMode) {
      _client.removeChangeListener(_onServerChange);
      debugPrint('🔇 Écoute temps réel désactivée');
    }
    super.dispose();
  }

  void _onServerChange(Map<String, dynamic> change) {
    if (!mounted) return;

    debugPrint('📥 Changement reçu: ${change['type']}');

    // Invalider le cache
    _db.invalidateCache('all_');

    // Notifier le parent
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
