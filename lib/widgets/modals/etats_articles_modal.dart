import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class EtatsArticlesModal extends StatefulWidget {
  const EtatsArticlesModal({super.key});

  @override
  State<EtatsArticlesModal> createState() => _EtatsArticlesModalState();
}

class _EtatsArticlesModalState extends State<EtatsArticlesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await _databaseService.database.getActiveArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[100]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'États Articles',
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
                              color: Colors.purple[100],
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
                                    child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text('Stock U1', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text('Stock U2', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text('Stock U3', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text('CMUP', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
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
                                      return Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
    );
  }
}
