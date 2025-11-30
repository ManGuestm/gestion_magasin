import 'package:flutter/material.dart';

import '../common/base_modal.dart';
import 'balance_comptes_fournisseurs_modal.dart';
import 'fiche_fournisseurs_modal.dart';
import 'statistiques_fournisseurs_modal.dart';

class EtatsFournisseursModal extends StatefulWidget {
  const EtatsFournisseursModal({super.key});

  @override
  State<EtatsFournisseursModal> createState() => _EtatsFournisseursModalState();
}

class _EtatsFournisseursModalState extends State<EtatsFournisseursModal> {
  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'États Fournisseurs',
      width: 600,
      height: 400,
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sélectionnez le type d\'état fournisseur :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Fiche Fournisseurs
            _buildMenuCard(
              title: 'Fiche Fournisseurs',
              description: 'Consulter les informations détaillées des fournisseurs',
              icon: Icons.business,
              color: Colors.blue,
              onTap: () => _showModal(const FicheFournisseursModal()),
            ),

            const SizedBox(height: 16),

            // Balance des Comptes Fournisseurs
            _buildMenuCard(
              title: 'Balance des Comptes Fournisseurs',
              description: 'Consulter les soldes et mouvements des comptes fournisseurs',
              icon: Icons.account_balance,
              color: Colors.green,
              onTap: () => _showModal(const BalanceComptesFournisseursModal()),
            ),

            const SizedBox(height: 16),

            // Statistiques Fournisseurs
            _buildMenuCard(
              title: 'Statistiques Fournisseurs',
              description: 'Analyser les performances et statistiques des fournisseurs',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () => _showModal(const StatistiquesFournisseursModal()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
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
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModal(Widget modal) {
    Navigator.of(context).pop(); // Fermer le modal actuel
    showDialog(
      context: context,
      builder: (context) => modal,
    );
  }
}
