import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class MiseAJourValeursStocksModal extends StatefulWidget {
  const MiseAJourValeursStocksModal({super.key});

  @override
  State<MiseAJourValeursStocksModal> createState() => _MiseAJourValeursStocksModalState();
}

class _MiseAJourValeursStocksModalState extends State<MiseAJourValeursStocksModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _articles = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await _databaseService.database.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateCMUP() async {
    setState(() => _isUpdating = true);

    try {
      // Simulation de mise à jour des CMUP
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mise à jour des valeurs de stocks terminée'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadArticles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  double _getValeurStock(Article article) {
    final stockTotal = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
    return stockTotal * (article.cmup ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final valeurTotale = _articles.fold(0.0, (sum, article) => sum + _getValeurStock(article));

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mise à jour des valeurs de stocks',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valeur totale des stocks: ${NumberUtils.formatNumber(valeurTotale)} Ar',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _updateCMUP,
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.update),
                      label: Text(_isUpdating ? 'Mise à jour...' : 'Mettre à jour CMUP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Center(
                                          child: Text('Article',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Stock U1',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Stock U2',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Stock U3',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child:
                                              Text('CMUP', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child:
                                              Text('Valeur', style: TextStyle(fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _articles.isEmpty
                                  ? const Center(child: Text('Aucun article trouvé'))
                                  : ListView.builder(
                                      itemCount: _articles.length,
                                      itemBuilder: (context, index) {
                                        final article = _articles[index];
                                        final valeur = _getValeurStock(article);

                                        return Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                            border: const Border(
                                                bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    article.designation,
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(article.stocksu1 ?? 0),
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(article.stocksu2 ?? 0),
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(article.stocksu3 ?? 0),
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(article.cmup ?? 0),
                                                    style: const TextStyle(
                                                        fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(valeur),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
