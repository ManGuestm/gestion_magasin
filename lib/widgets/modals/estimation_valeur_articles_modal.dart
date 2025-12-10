import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../utils/stock_converter.dart';
import '../common/tab_navigation_widget.dart';

class EstimationValeurArticlesModal extends StatefulWidget {
  const EstimationValeurArticlesModal({super.key});

  @override
  State<EstimationValeurArticlesModal> createState() => _EstimationValeurArticlesModalState();
}

class _EstimationValeurArticlesModalState extends State<EstimationValeurArticlesModal>
    with TabNavigationMixin {
  List<Article> _articles = [];
  bool _isLoading = false;
  double _totalValeur = 0;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final articles = await db.getActiveArticles();
      double total = 0;
      for (var article in articles) {
        final stockTotal = StockConverter.calculerStockTotalU3(
          article: article,
          stockU1: article.stocksu1 ?? 0,
          stockU2: article.stocksu2 ?? 0,
          stockU3: article.stocksu3 ?? 0,
        );
        total += stockTotal * (article.cmup ?? 0);
      }
      setState(() {
        _articles = articles;
        _totalValeur = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatNumber(double? number) {
    if (number == null) return '0.00';
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: 600,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.grey[200],
        ),
        child: Column(children: [_buildHeader(), _buildTable(), _buildSummary(), _buildFooter()]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.blue[400],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.assessment, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          const Text(
            'ESTIMATION EN VALEUR DES ARTICLES (CMUP)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 1)),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _articles.length,
                      itemExtent: 16,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return _buildTableRow(article, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.orange[300],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          _buildHeaderCell('DESIGNATION', 200),
          _buildHeaderCell('STOCK U1', 80),
          _buildHeaderCell('STOCK U2', 80),
          _buildHeaderCell('STOCK U3', 80),
          _buildHeaderCell('STOCK TOTAL', 100),
          _buildHeaderCell('CMUP', 80),
          _buildHeaderCell('VALEUR STOCK', 120),
          _buildHeaderCell('CATEGORIE', 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Article article, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    final stockTotal = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: article.stocksu1 ?? 0,
      stockU2: article.stocksu2 ?? 0,
      stockU3: article.stocksu3 ?? 0,
    );
    final valeurStock = stockTotal * (article.cmup ?? 0);

    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          _buildCell(article.designation, 200),
          _buildCell(_formatNumber(article.stocksu1), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(article.stocksu2), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(article.stocksu3), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(stockTotal), 100, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(article.cmup), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(valeurStock), 120, alignment: Alignment.centerRight),
          _buildCell(article.categorie ?? '', 100),
        ],
      ),
    );
  }

  Widget _buildCell(String text, double width, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.black, width: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: Colors.black),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'TOTAL VALEUR STOCK: ${_formatNumber(_totalValeur)} Ar',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton('Exporter Excel', () {}),
          _buildActionButton('Imprimer', () {}),
          _buildActionButton('Fermer', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.black)),
        ),
      ),
    );
  }
}
