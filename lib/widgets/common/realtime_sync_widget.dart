import 'package:flutter/material.dart';

import '../../services/realtime_sync_service.dart';

/// Widget qui écoute les changements du serveur et rafraîchit automatiquement
class RealtimeSyncWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDataChanged;

  const RealtimeSyncWidget({
    super.key,
    required this.child,
    this.onDataChanged,
  });

  @override
  State<RealtimeSyncWidget> createState() => _RealtimeSyncWidgetState();
}

class _RealtimeSyncWidgetState extends State<RealtimeSyncWidget> {
  final RealtimeSyncService _syncService = RealtimeSyncService();

  @override
  void initState() {
    super.initState();
    _syncService.startListening();
    if (widget.onDataChanged != null) {
      _syncService.addRefreshCallback(widget.onDataChanged!);
    }
  }

  @override
  void dispose() {
    if (widget.onDataChanged != null) {
      _syncService.removeRefreshCallback(widget.onDataChanged!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
