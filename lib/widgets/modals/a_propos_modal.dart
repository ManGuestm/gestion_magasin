import 'package:flutter/material.dart';

class AProposModal extends StatelessWidget {
  const AProposModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.info_outline, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'À propos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logo
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  height: 70,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[600]!, Colors.grey[500]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // App name and version
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion de Magasin Grossiste',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Solution ERP Commerciale Professionnelle',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Version 1.0.1+2',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logiciel complet de gestion commerciale destiné aux grossistes et entreprises de distribution. Interface moderne et intuitive pour une gestion optimale de votre activité commerciale.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 540,
                        child: GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.2,
                          children: [
                            _buildModuleCard(
                              'Modules Commerces',
                              Colors.green,
                              Icons.shopping_cart,
                              [
                                'Achats et gestion fournisseurs',
                                'Ventes multi-dépôts avec facturation',
                                'Retours marchandises (achats/ventes)',
                                'Historique complet des opérations',
                              ],
                            ),
                            _buildModuleCard(
                              'Modules Gestion',
                              Colors.orange,
                              Icons.settings,
                              [
                                'Transferts inter-dépôts',
                                'Productions et transformations',
                                'Gestion emballages consignés',
                                'Régularisations comptes tiers',
                                'Relance clients automatisée',
                                'Échéanciers fournisseurs',
                                'Variations et niveaux stocks',
                                'Amortissements immobilisations',
                              ],
                            ),
                            _buildModuleCard(
                              'Modules Trésorerie',
                              Colors.blue,
                              Icons.account_balance,
                              [
                                'Encaissements et décaissements',
                                'Gestion chèques et effets',
                                'Opérations bancaires',
                                'Virements internes',
                                'Moyens de paiement multiples',
                              ],
                            ),
                            _buildModuleCard(
                              'Modules États & Rapports',
                              Colors.purple,
                              Icons.analytics,
                              [
                                'Journaux caisse et banques',
                                'États clients, fournisseurs, articles',
                                'Statistiques ventes et achats',
                                'Calculs marges détaillées',
                                'Bilan et compte de résultat',
                                'Tableau de bord temps réel',
                              ],
                            ),
                            _buildModuleCard(
                              'Fonctionnalités Avancées',
                              Colors.red,
                              Icons.star,
                              [
                                'Système multi-utilisateurs avec rôles',
                                'Gestion multi-dépôts centralisée',
                                'Calcul CMUP automatique',
                                'Étiquetage prix et codes-barres',
                                'Sauvegarde et restauration',
                                'Interface desktop optimisée',
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Copyright
            Text(
              '© ${DateTime.now().year} RAKOTOARISAONA Parfait. Tous droits réservés - parfait.dev@gmail.com - +261 38 06 760 97',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(String title, Color color, IconData icon, List<String> features) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: color.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
