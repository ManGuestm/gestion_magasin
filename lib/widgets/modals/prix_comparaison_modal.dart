import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import 'edit_prix_vente_modal.dart';

class PrixComparaisonModal extends StatefulWidget {
  final List<Map<String, dynamic>> lignesAchat;

  const PrixComparaisonModal({super.key, required this.lignesAchat});

  @override
  State<PrixComparaisonModal> createState() => _PrixComparaisonModalState();
}

class _PrixComparaisonModalState extends State<PrixComparaisonModal> {
  List<Map<String, dynamic>> _comparaisonData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparaisonData();
  }

  Future<void> _loadComparaisonData() async {
    setState(() => _isLoading = true);

    final data = <Map<String, dynamic>>[];

    for (var ligne in widget.lignesAchat) {
      final designation = ligne['designation'] as String;
      final article = await DatabaseService().database.getArticleByDesignation(designation);

      if (article != null) {
        final unite = ligne['unites'] as String;
        final prixAchat = ligne['prixUnitaire'] as double;
        final quantite = ligne['quantite'] as double;
        final depot = ligne['depot'] as String;

        // Récupérer le prix de vente selon l'unité
        double prixVente = 0;
        if (unite == article.u1) {
          prixVente = article.pvu1 ?? 0;
        } else if (unite == article.u2) {
          prixVente = article.pvu2 ?? 0;
        } else if (unite == article.u3) {
          prixVente = article.pvu3 ?? 0;
        }

        final diffPrix = prixVente - prixAchat;

        data.add({
          'designation': designation,
          'unite': unite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'quantite': quantite,
          'diffPrix': diffPrix,
          'depot': depot,
          'article': article,
        });
      }
    }

    setState(() {
      _comparaisonData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.95,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Comparaison Prix Achat / Vente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(child: _buildComparaisonTable()),
            const SizedBox(height: 16),
            if (!_isLoading && _comparaisonData.isNotEmpty) _buildTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalAchat = _comparaisonData.fold<double>(
      0,
      (sum, row) => sum + (row['prixAchat'] as double) * (row['quantite'] as double),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Montant Total d\'Achat: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(
            '${NumberUtils.formatNumber(totalAchat)} Ar',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildComparaisonTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_comparaisonData.isEmpty) {
      return const Center(child: Text('Aucune donnée à comparer'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Désignation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Unité',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Prix Achat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Prix Vente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qté',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Diff Prix',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Dépôt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
            itemCount: _comparaisonData.length,
            itemBuilder: (context, index) {
              final row = _comparaisonData[index];
              final diffPrix = row['diffPrix'] as double;
              final diffColor = diffPrix < 0 ? Colors.red : (diffPrix == 0 ? Colors.orange : Colors.green);

              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row['designation'],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(flex: 1, child: Text(row['unite'], style: const TextStyle(fontSize: 13))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        NumberUtils.formatNumber(row['prixAchat']),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        NumberUtils.formatNumber(row['prixVente']),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        NumberUtils.formatNumber(row['quantite']),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        NumberUtils.formatNumber(diffPrix),
                        style: TextStyle(fontSize: 13, color: diffColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        row['depot'],
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        tooltip: 'Modifier prix de vente',
                        onPressed: () => _modifierPrixVente(row['article']),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _modifierPrixVente(Article article) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditPrixVenteModal(article: article),
    );

    if (result == true) {
      // Recharger les données après modification
      await _loadComparaisonData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prix de vente mis à jour')));
      }
    }
  }
}
