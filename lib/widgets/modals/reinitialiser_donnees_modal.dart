import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class ReinitialiserDonneesModal extends StatefulWidget {
  const ReinitialiserDonneesModal({super.key});

  @override
  State<ReinitialiserDonneesModal> createState() => _ReinitialiserDonneesModalState();
}

class _ReinitialiserDonneesModalState extends State<ReinitialiserDonneesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();

  String _selectedOption = ''; // 'tout' ou 'intelligent'

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        child: Container(
          width: 500,
          // height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'RÉINITIALISER LES DONNÉES',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // Warning message
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ATTENTION : Cette opération est irréversible !\nToutes les données sélectionnées seront définitivement supprimées.',
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choisissez une option de réinitialisation :',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Option 1: Réinitialisation complète
                      InkWell(
                        onTap: () => setState(() => _selectedOption = 'tout'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedOption == 'tout' ? Colors.red.shade100 : Colors.white,
                            border: Border.all(
                              color: _selectedOption == 'tout' ? Colors.red : Colors.grey.shade300,
                              width: _selectedOption == 'tout' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedOption == 'tout'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _selectedOption == 'tout' ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Réinitialisation COMPLÈTE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Supprime TOUTES les données de l\'application :\n'
                                      '• Articles, Clients, Fournisseurs, Dépôts\n'
                                      '• Achats, Ventes, Stocks\n'
                                      '• Trésorerie, Comptes, Mouvements\n'
                                      '• Production, Transferts, etc.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Option 2: Réinitialisation intelligente
                      InkWell(
                        onTap: () => setState(() => _selectedOption = 'intelligent'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedOption == 'intelligent' ? Colors.orange.shade100 : Colors.white,
                            border: Border.all(
                              color: _selectedOption == 'intelligent' ? Colors.orange : Colors.grey.shade300,
                              width: _selectedOption == 'intelligent' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedOption == 'intelligent'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _selectedOption == 'intelligent' ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.refresh, color: Colors.orange, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Réinitialisation INTELLIGENTE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nouvel exercice - Remet à zéro uniquement :\n'
                                      '✓ Conserve : Articles, Clients, Fournisseurs, Dépôts, CMUP\n'
                                      '✓ Conserve : Achats, Ventes, Trésorerie, Soldes\n'
                                      '✗ Remet à 0 : Stocks uniquement (prêt pour inventaire)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Info supplémentaire
                      if (_selectedOption.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedOption == 'tout'
                                      ? 'Base de données complètement vide après réinitialisation'
                                      : 'Démarrer un nouvel exercice : faire l\'inventaire puis commencer',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectedOption.isNotEmpty ? _confirmerReinitialisation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Exécuter la Réinitialisation'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmerReinitialisation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmation'),
          ],
        ),
        content: const Text(
          'Êtes-vous absolument certain de vouloir procéder à cette réinitialisation ?\n\nCette opération est IRRÉVERSIBLE et affectera définitivement les données sélectionnées !',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exécuter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _executerReinitialisation();
    }
  }

  Future<void> _executerReinitialisation() async {
    try {
      final db = _databaseService.database;

      await db.transaction(() async {
        if (_selectedOption == 'tout') {
          await _reinitialiserToutesLesDonnees(db);
        } else if (_selectedOption == 'intelligent') {
          await _reinitialiserIntelligent(db);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réinitialisation exécutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText('Erreur: $e'), duration: const Duration(seconds: 15)),
        );
      }
    }
  }

  Future<void> _reinitialiserToutesLesDonnees(dynamic db) async {
    const tables = [
      'achats',
      'detachats',
      'retachats',
      'retdetachats',
      'ventes',
      'detventes',
      'retventes',
      'retdeventes',
      'stocks',
      'prod',
      'detprod',
      'transf',
      'dettransf',
      'comptefrns',
      'compteclt',
      'comptecom',
      'caisse',
      'banque',
      'chequier',
      'effets',
      'autrescompte',
      'blclt',
      'emblclt',
      'fstocks',
      'tribanque',
      'tricaisse',
      'sintrant',
      'sproduit',
      'pv',
      'articles',
      'clt',
      'frns',
      'com',
      'depart',
      'clti',
      'emb',
      'bq',
      'ca',
      'mp',
      'tblunit',
    ];

    for (final table in tables) {
      await db.customStatement('DELETE FROM $table');
    }
  }

  Future<void> _reinitialiserIntelligent(dynamic db) async {
    // Remise à zéro UNIQUEMENT des stocks dans articles (préserver CMUP)
    await db.customStatement('UPDATE articles SET stocksu1 = 0, stocksu2 = 0, stocksu3 = 0');

    // Réinitialiser les stocks par dépôt à 0
    await db.customStatement('UPDATE depart SET stocksu1 = 0, stocksu2 = 0, stocksu3 = 0');

    // Supprimer uniquement les mouvements de stock
    await db.customStatement('DELETE FROM stocks');
    await db.customStatement('DELETE FROM fstocks');
  }
}
