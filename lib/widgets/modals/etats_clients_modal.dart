import 'package:flutter/material.dart';

import '../../services/modal_loader.dart';
import '../common/base_modal.dart';

class EtatsClientsModal extends StatelessWidget {
  const EtatsClientsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'États Clients',
      width: 600,
      height: 400,
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Sélectionnez un état client :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuCard(
                    context,
                    'Fiche Clients',
                    'Liste détaillée de tous les clients',
                    Icons.people,
                    Colors.blue,
                    () => _openModal(context, 'fiche_clients'),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    context,
                    'Balance de Compte Clients',
                    'Soldes et mouvements des comptes clients',
                    Icons.account_balance,
                    Colors.green,
                    () => _openModal(context, 'balance_comptes_clients'),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    context,
                    'Fiche d\'Énumération Clients',
                    'Énumération simplifiée des clients',
                    Icons.list_alt,
                    Colors.orange,
                    () => _openModal(context, 'fiche_enumeration_clients'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openModal(BuildContext context, String modalName) async {
    Navigator.of(context).pop();
    final modal = await ModalLoader.loadModal(modalName);
    if (modal != null && context.mounted) {
      showDialog(context: context, builder: (_) => modal);
    }
  }
}
