import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../providers/vente_providers.dart';
import '../../utils/focus_node_manager.dart';
import '../common/enhanced_autocomplete.dart';

/// Widget pour la sélection et saisie du client
class ClientSelectorWidget extends ConsumerWidget {
  final String? selectedClient;
  final ValueChanged<CltData?> onClientSelected;
  final ValueChanged<double> onSoldeLoaded;
  final FocusNodeManager focusNodeManager;
  final TextEditingController clientController;
  final bool Function(CltData) filterClients;

  const ClientSelectorWidget({
    super.key,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onSoldeLoaded,
    required this.focusNodeManager,
    required this.clientController,
    required this.filterClients,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Erreur: $err'),
      data: (allClients) {
        final filteredClients = allClients.where(filterClients).toList();

        return EnhancedAutocomplete<CltData>(
          options: filteredClients,
          displayStringForOption: (client) => client.rsoc,
          onSelected: (client) {
            onClientSelected(client);
            _loadClientBalance(ref, client.rsoc);
          },
          controller: clientController,
          focusNode: focusNodeManager.client,
          hintText: 'Sélectionnez un client',
          decoration: InputDecoration(
            hintText: 'Sélectionnez un client',
            labelText: 'Client',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  void _loadClientBalance(WidgetRef ref, String clientName) async {
    final balance = await ref.read(clientBalanceProvider(clientName).future);
    onSoldeLoaded(balance);
  }
}
