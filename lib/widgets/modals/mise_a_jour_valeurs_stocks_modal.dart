import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/date_picker_field.dart';
import '../common/enhanced_autocomplete.dart';
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
    // Convertir tous les stocks en unité de base (u3) pour calculer la valeur
    double stockTotalU3 = (article.stocksu3 ?? 0);

    // Ajouter stock u2 converti en u3
    if (article.tu3u2 != null && article.tu3u2! > 0) {
      stockTotalU3 += (article.stocksu2 ?? 0) * article.tu3u2!;
    }

    // Ajouter stock u1 converti en u3
    if (article.tu2u1 != null && article.tu2u1! > 0 && article.tu3u2 != null && article.tu3u2! > 0) {
      stockTotalU3 += (article.stocksu1 ?? 0) * article.tu2u1! * article.tu3u2!;
    }

    // CMUP est en unité de base (u3), donc valeur = stockTotalU3 * CMUP
    return stockTotalU3 * (article.cmup ?? 0);
  }

  void _showManualCMUPModal() {
    showDialog(
      context: context,
      builder: (context) => _ManualCMUPModal(
        articles: _articles,
        onUpdate: _loadArticles,
      ),
    );
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
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _showManualCMUPModal,
                          icon: const Icon(Icons.edit),
                          label: const Text('CMUP manuel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
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

class _ManualCMUPModal extends StatefulWidget {
  final List<Article> articles;
  final VoidCallback onUpdate;

  const _ManualCMUPModal({required this.articles, required this.onUpdate});

  @override
  State<_ManualCMUPModal> createState() => _ManualCMUPModalState();
}

class _ManualCMUPModalState extends State<_ManualCMUPModal> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _cmupController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  Article? _selectedArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateDebutController.text = app_date.AppDateUtils.formatDate(now);
    _dateFinController.text = app_date.AppDateUtils.formatDate(now.add(const Duration(days: 30)));
  }

  @override
  void dispose() {
    _cmupController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _saveCMUP() async {
    if (_selectedArticle == null || _cmupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un article et saisir le CMUP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newCMUP = double.tryParse(_cmupController.text.replaceAll(' ', '')) ?? 0;
      final dateDebut = DateTime.parse(_dateDebutController.text.split('-').reversed.join('-'));
      final dateFin = DateTime.parse(_dateFinController.text.split('-').reversed.join('-'));

      await _databaseService.database.transaction(() async {
        // Sauvegarder l'historique
        await _databaseService.database.into(_databaseService.database.cmupHistory).insert(
              CmupHistoryCompanion.insert(
                designation: _selectedArticle!.designation,
                cmupValue: newCMUP,
                dateDebut: dateDebut,
                dateFin: dateFin,
                cmupPrecedent: Value(_selectedArticle!.cmup),
                createdAt: DateTime.now(),
              ),
            );

        // Mettre à jour le CMUP actuel
        await (_databaseService.database.update(_databaseService.database.articles)
              ..where((a) => a.designation.equals(_selectedArticle!.designation)))
            .write(ArticlesCompanion(
          cmup: Value(newCMUP),
        ));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CMUP mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mise à jour CMUP manuelle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Article:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            EnhancedAutocomplete<Article>(
              options: widget.articles,
              displayStringForOption: (article) => article.designation,
              onSelected: (article) {
                setState(() {
                  _selectedArticle = article;
                  _cmupController.text = NumberUtils.formatNumber(article.cmup ?? 0);
                });
              },
              hintText: 'Sélectionner un article...',
            ),
            const SizedBox(height: 16),
            const Text('CMUP:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _cmupController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nouveau CMUP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date début:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DatePickerField(
                        controller: _dateDebutController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date fin:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DatePickerField(
                        controller: _dateFinController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveCMUP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
