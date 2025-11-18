import 'package:flutter/material.dart';

import '../../database/database_service.dart';

class ReinitialiserDonneesModal extends StatefulWidget {
  const ReinitialiserDonneesModal({super.key});

  @override
  State<ReinitialiserDonneesModal> createState() => _ReinitialiserDonneesModalState();
}

class _ReinitialiserDonneesModalState extends State<ReinitialiserDonneesModal> {
  final DatabaseService _databaseService = DatabaseService();

  bool _reinitialiserTout = false;
  bool _toutSaufArticles = false;
  bool _articles = false;
  bool _clients = false;
  bool _fournisseurs = false;
  bool _achats = false;
  bool _ventes = false;
  bool _stocks = false;
  bool _quantitesStock = false;
  bool _tresorerie = false;
  bool _comptes = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'RÉINITIALISER LES DONNÉES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Réinitialiser tout
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'Réinitialiser TOUTES les données',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text(
                          'Supprime toutes les données de l\'application',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _reinitialiserTout,
                        onChanged: (value) {
                          setState(() {
                            _reinitialiserTout = value ?? false;
                            if (_reinitialiserTout) {
                              _toutSaufArticles = _articles = _clients = _fournisseurs = _achats =
                                  _ventes = _stocks = _quantitesStock = _tresorerie = _comptes = false;
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tout sauf articles
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'Tout sauf Articles/Clients/Fournisseurs/Dépôts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        subtitle: const Text(
                          'Remise à zéro intelligente : préserve les données maîtres, remet stocks et soldes à 0, CMUP à 0 pour recalcul',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _toutSaufArticles,
                        onChanged: (value) {
                          setState(() {
                            _toutSaufArticles = value ?? false;
                            if (_toutSaufArticles) {
                              _reinitialiserTout = _articles = _clients = _fournisseurs = _achats =
                                  _ventes = _stocks = _quantitesStock = _tresorerie = _comptes = false;
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'OU sélectionner des parties spécifiques :',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Options partielles
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildOptionTile(
                              'Articles et Stocks',
                              'Supprime tous les articles et mouvements de stock',
                              _articles,
                              (value) => setState(() {
                                _articles = value ?? false;
                                if (_articles) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Clients',
                              'Supprime tous les clients et leurs comptes',
                              _clients,
                              (value) => setState(() {
                                _clients = value ?? false;
                                if (_clients) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Fournisseurs',
                              'Supprime tous les fournisseurs et leurs comptes',
                              _fournisseurs,
                              (value) => setState(() {
                                _fournisseurs = value ?? false;
                                if (_fournisseurs) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Achats et Retours',
                              'Supprime toutes les transactions d\'achat',
                              _achats,
                              (value) => setState(() {
                                _achats = value ?? false;
                                if (_achats) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Ventes et Retours',
                              'Supprime toutes les transactions de vente',
                              _ventes,
                              (value) => setState(() {
                                _ventes = value ?? false;
                                if (_ventes) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Mouvements de Stock',
                              'Supprime uniquement l\'historique des mouvements',
                              _stocks,
                              (value) => setState(() {
                                _stocks = value ?? false;
                                if (_stocks) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Quantités de Stock',
                              'Remet à zéro les quantités de stock de tous les articles',
                              _quantitesStock,
                              (value) => setState(() {
                                _quantitesStock = value ?? false;
                                if (_quantitesStock) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Trésorerie',
                              'Supprime encaissements, décaissements, chèques',
                              _tresorerie,
                              (value) => setState(() {
                                _tresorerie = value ?? false;
                                if (_tresorerie) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                            _buildOptionTile(
                              'Autres Comptes',
                              'Supprime les comptes charges et produits',
                              _comptes,
                              (value) => setState(() {
                                _comptes = value ?? false;
                                if (_comptes) {
                                  _reinitialiserTout = false;
                                  _toutSaufArticles = false;
                                }
                              }),
                            ),
                          ],
                        ),
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
                    onPressed: _canReinitialiser() ? _confirmerReinitialisation : null,
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
    );
  }

  Widget _buildOptionTile(String title, String subtitle, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  bool _canReinitialiser() {
    return _reinitialiserTout ||
        _toutSaufArticles ||
        _articles ||
        _clients ||
        _fournisseurs ||
        _achats ||
        _ventes ||
        _stocks ||
        _quantitesStock ||
        _tresorerie ||
        _comptes;
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
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
        if (_reinitialiserTout) {
          await _reinitialiserToutesLesDonnees(db);
        } else if (_toutSaufArticles) {
          await _reinitialiserToutSaufArticles(db);
        } else {
          await _reinitialiserSelectif(db);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réinitialisation exécutée avec succès - Base de données mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Erreur: $e'),
            duration: const Duration(seconds: 15),
          ),
        );
      }
    }
  }

  Future<void> _reinitialiserToutesLesDonnees(dynamic db) async {
    const tables = [
      // Tables transactionnelles
      'achats', 'detachats', 'retachats', 'retdetachats', 'ventes', 'detventes',
      'retventes', 'retdeventes', 'stocks', 'prod', 'detprod', 'transf', 'dettransf',
      // Tables comptables
      'comptefrns', 'compteclt', 'comptecom', 'caisse', 'banque', 'chequier', 'effets',
      'autrescompte', 'blclt', 'emblclt', 'fstocks', 'tribanque', 'tricaisse',
      // Tables production
      'sintrant', 'sproduit', 'pv',
      // Tables maîtres
      'articles', 'clt', 'frns', 'com', 'depart', 'clti', 'emb', 'bq', 'ca', 'mp', 'tblunit'
    ];

    for (final table in tables) {
      await db.customStatement('DELETE FROM $table');
    }
  }

  Future<void> _reinitialiserToutSaufArticles(dynamic db) async {
    // Remise à zéro intelligente des stocks et CMUP dans articles
    await db.customStatement('''
      UPDATE articles SET 
        stocksu1 = 0,
        stocksu2 = 0,
        stocksu3 = 0,
        cmup = 0
    ''');

    // Remise à zéro des soldes clients/fournisseurs/commerciaux
    await db.customStatement('UPDATE clt SET soldes = 0, soldesa = 0, datedernop = NULL');
    await db.customStatement('UPDATE frns SET soldes = 0, soldesa = 0, datedernop = NULL');
    await db.customStatement('UPDATE com SET soldes = 0, soldesa = 0');
    await db.customStatement('UPDATE clti SET soldes = 0, soldes1 = 0, zanaka = 0');

    // Remise à zéro des soldes banques et comptes auxiliaires
    await db.customStatement('UPDATE bq SET soldes = 0');
    await db.customStatement('UPDATE ca SET soldes = 0, soldesa = 0');

    const tablesToClear = [
      // Tables transactionnelles (mouvements)
      'achats', 'detachats', 'retachats', 'retdetachats', 'ventes', 'detventes',
      'retventes', 'retdeventes', 'stocks', 'prod', 'detprod', 'transf', 'dettransf',
      // Tables comptables (écritures)
      'comptefrns', 'compteclt', 'comptecom', 'caisse', 'banque', 'chequier', 'effets',
      'autrescompte', 'blclt', 'emblclt', 'fstocks', 'tribanque', 'tricaisse',
      // Tables production et prix
      'pv', 'sintrant', 'sproduit',
      // Table depart (stocks par dépôt) - suppression complète
      'depart'
    ];

    for (final table in tablesToClear) {
      await db.customStatement('DELETE FROM $table');
    }
  }

  Future<void> _reinitialiserSelectif(dynamic db) async {
    if (_articles) {
      await db.customStatement('DELETE FROM articles');
      await db.customStatement('DELETE FROM depart');
      await db.customStatement('DELETE FROM pv');
    }
    if (_clients) {
      await db.customStatement('DELETE FROM clt');
      await db.customStatement('DELETE FROM compteclt');
      await db.customStatement('DELETE FROM clti');
    }
    if (_fournisseurs) {
      await db.customStatement('DELETE FROM frns');
      await db.customStatement('DELETE FROM comptefrns');
    }
    if (_achats) {
      await db.customStatement('DELETE FROM achats');
      await db.customStatement('DELETE FROM detachats');
      await db.customStatement('DELETE FROM retachats');
      await db.customStatement('DELETE FROM retdetachats');
    }
    if (_ventes) {
      await db.customStatement('DELETE FROM ventes');
      await db.customStatement('DELETE FROM detventes');
      await db.customStatement('DELETE FROM retventes');
      await db.customStatement('DELETE FROM retdeventes');
      await db.customStatement('DELETE FROM blclt');
    }
    if (_stocks) {
      await db.customStatement('DELETE FROM stocks');
      await db.customStatement('DELETE FROM fstocks');
    }
    if (_quantitesStock) {
      await db.customStatement('''
        UPDATE articles SET 
          stocksu1 = 0,
          stocksu2 = 0,
          stocksu3 = 0,
          cmup = 0
      ''');
      await db.customStatement('''
        UPDATE depart SET 
          stocksu1 = 0,
          stocksu2 = 0,
          stocksu3 = 0
      ''');
    }
    if (_tresorerie) {
      await db.customStatement('DELETE FROM caisse');
      await db.customStatement('DELETE FROM banque');
      await db.customStatement('DELETE FROM chequier');
      await db.customStatement('DELETE FROM effets');
      await db.customStatement('DELETE FROM tribanque');
      await db.customStatement('DELETE FROM tricaisse');
    }
    if (_comptes) {
      await db.customStatement('DELETE FROM autrescompte');
      await db.customStatement('DELETE FROM comptecom');
    }
  }
}
