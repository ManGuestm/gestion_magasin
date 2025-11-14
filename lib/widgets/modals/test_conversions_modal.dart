import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../utils/stock_converter.dart';
import '../../utils/stock_converter_test.dart';
import '../common/stock_display_widget.dart';

class TestConversionsModal extends StatefulWidget {
  const TestConversionsModal({super.key});

  @override
  State<TestConversionsModal> createState() => _TestConversionsModalState();
}

class _TestConversionsModalState extends State<TestConversionsModal> {
  late Article article;
  double stockU1 = 48.0;
  double stockU2 = 0.0;
  double stockU3 = 0.0;

  final TextEditingController _quantiteController = TextEditingController();
  String _uniteSelectionnee = 'Grs';

  @override
  void initState() {
    super.initState();
    article = StockConverterTest.creerArticleTest();
  }

  void _ajouterStock() {
    final quantite = double.tryParse(_quantiteController.text) ?? 0;
    if (quantite <= 0) return;

    final conversion = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: _uniteSelectionnee,
      quantiteAchat: quantite,
    );

    final nouveauxStocks = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: stockU1 + conversion['u1']!,
      quantiteU2: stockU2 + conversion['u2']!,
      quantiteU3: stockU3 + conversion['u3']!,
    );

    setState(() {
      stockU1 = nouveauxStocks['u1']!;
      stockU2 = nouveauxStocks['u2']!;
      stockU3 = nouveauxStocks['u3']!;
    });

    _quantiteController.clear();
  }

  void _reinitialiserStock() {
    setState(() {
      stockU1 = 48.0;
      stockU2 = 0.0;
      stockU3 = 0.0;
    });
  }

  void _executerScenarioComplet() {
    // Réinitialiser
    _reinitialiserStock();

    // Achat 1: 230 Grs
    final achat1 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: 'Grs',
      quantiteAchat: 230.0,
    );

    final stocks1 = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: stockU1 + achat1['u1']!,
      quantiteU2: stockU2 + achat1['u2']!,
      quantiteU3: stockU3 + achat1['u3']!,
    );

    // Achat 2: 13 Pcs
    final achat2 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: 'Pcs',
      quantiteAchat: 13.0,
    );

    final stocks2 = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: stocks1['u1']! + achat2['u1']!,
      quantiteU2: stocks1['u2']! + achat2['u2']!,
      quantiteU3: stocks1['u3']! + achat2['u3']!,
    );

    setState(() {
      stockU1 = stocks2['u1']!;
      stockU2 = stocks2['u2']!;
      stockU3 = stocks2['u3']!;
    });

    // Afficher les détails
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scénario complet exécuté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Étapes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('1. Stock initial: 48 Ctn / 0 Grs / 0 Pcs'),
            const SizedBox(height: 4),
            const Text('2. Achat 230 Grs → +4 Ctn +30 Grs'),
            Text(
                '   Résultat: ${stocks1['u1']!.toInt()} Ctn / ${stocks1['u2']!.toInt()} Grs / ${stocks1['u3']!.toInt()} Pcs'),
            const SizedBox(height: 4),
            const Text('3. Achat 13 Pcs → +1 Grs +3 Pcs'),
            Text(
                '   Résultat final: ${stocks2['u1']!.toInt()} Ctn / ${stocks2['u2']!.toInt()} Grs / ${stocks2['u3']!.toInt()} Pcs'),
            const SizedBox(height: 12),
            const Text('Résultat attendu: 52 Ctn / 31 Grs / 3 Pcs',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Test des Conversions Automatiques',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Article info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Article: ${article.designation}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Unités: ${article.u1} / ${article.u2} / ${article.u3}'),
                  Text(
                      'Conversions: 1 ${article.u1} = ${article.tu2u1!.toInt()} ${article.u2}, 1 ${article.u2} = ${article.tu3u2!.toInt()} ${article.u3}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stock actuel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stock Actuel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Stock réel: ${stockU1.toInt()} ${article.u1}, ${stockU2.toInt()} ${article.u2}, ${stockU3.toInt()} ${article.u3}'),
                  const SizedBox(height: 4),
                  StockDisplayWidget(
                    article: article,
                    stockU1: stockU1,
                    stockU2: stockU2,
                    stockU3: stockU3,
                    showTotal: true,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ajouter stock
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajouter du Stock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Quantité:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _quantiteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Unité:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _uniteSelectionnee,
                        items: [
                          DropdownMenuItem(value: article.u1, child: Text(article.u1!)),
                          DropdownMenuItem(value: article.u2, child: Text(article.u2!)),
                          DropdownMenuItem(value: article.u3, child: Text(article.u3!)),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _uniteSelectionnee = value!;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _ajouterStock,
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_quantiteController.text.isNotEmpty &&
                      double.tryParse(_quantiteController.text) != null)
                    ConversionAchatWidget(
                      article: article,
                      uniteAchat: _uniteSelectionnee,
                      quantiteAchat: double.parse(_quantiteController.text),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                ElevatedButton(
                  onPressed: _executerScenarioComplet,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Exécuter Scénario Complet', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _reinitialiserStock,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    StockConverterTest.testerScenarioComplet();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test exécuté dans la console')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Test Console', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explication
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exemple "Good Look Maintso"',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Stock initial: 48 Ctn, 0 Grs, 0 Pcs'),
                      Text('Affichage: 48 Ctn / 0 Grs / 0 Pcs'),
                      SizedBox(height: 8),
                      Text('Après achat de 230 Grs:'),
                      Text('• 230 Grs = 4×50 + 30 = 4 Ctn + 30 Grs'),
                      Text('• Stock: 52 Ctn, 30 Grs, 0 Pcs'),
                      Text('• Affichage: 52 Ctn / 30 Grs / 0 Pcs'),
                      SizedBox(height: 8),
                      Text('Après achat de 13 Pcs:'),
                      Text('• 13 Pcs = 1×10 + 3 = 1 Grs + 3 Pcs'),
                      Text('• Stock: 52 Ctn, 31 Grs, 3 Pcs'),
                      Text('• Affichage: 52 Ctn / 31 Grs / 3 Pcs'),
                      SizedBox(height: 12),
                      Text(
                        'Le système convertit automatiquement les excédents vers les unités supérieures pour un affichage optimal.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    super.dispose();
  }
}
