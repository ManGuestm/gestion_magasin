import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';
import '../../utils/stock_converter.dart';

class EtatStocksModal extends StatefulWidget {
  const EtatStocksModal({super.key});

  @override
  State<EtatStocksModal> createState() => _EtatStocksModalState();
}

class _EtatStocksModalState extends State<EtatStocksModal> {
  List<Article> _articles = [];
  bool _isLoading = false;
  final String _selectedDepot = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final articles = await db.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _formatGlobalStockDisplay(Article article) async {
    try {
      final db = AppDatabase();
      final stocksDetail = await db.getStockDetailleArticle(article.designation);
      
      double totalU1 = 0, totalU2 = 0, totalU3 = 0;
      
      for (var depot in stocksDetail.values) {
        totalU1 += depot['u1'] ?? 0;
        totalU2 += depot['u2'] ?? 0;
        totalU3 += depot['u3'] ?? 0;
      }
      
      return StockConverter.formaterAffichageStock(
        article: article,
        stockU1: totalU1,
        stockU2: totalU2,
        stockU3: totalU3,
      );
    } catch (e) {
      return StockConverter.formaterAffichageStock(
        article: article,
        stockU1: article.stocksu1 ?? 0,
        stockU2: article.stocksu2 ?? 0,
        stockU3: article.stocksu3 ?? 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        height: 700,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildCompanyHeader(),
            _buildReportTitle(),
            _buildTable(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RALAIZANDRY Jean Frédéric',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Marchandises Générales - Gros/détails',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    'Lot IVO 69 D Antohomadnika Sud',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tél.:', style: TextStyle(fontSize: 10)),
                  Text('Portable:', style: TextStyle(fontSize: 10)),
                  Text('Fax:', style: TextStyle(fontSize: 10)),
                  Text('e-mail:', style: TextStyle(fontSize: 10)),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    border: Border.all(color: Colors.black),
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('RCS:', style: TextStyle(fontSize: 10)),
              Spacer(),
              Text('NIF:', style: TextStyle(fontSize: 10)),
              Spacer(),
              Text('STAT:-------- Mobile: 034 21 363 03 -----------', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTitle() {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        'ETAT DE STOCKS LE $today - DEPOTS: $_selectedDepot',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _articles.length,
                      itemExtent: 18,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return FutureBuilder<String>(
                          future: _formatGlobalStockDisplay(article),
                          builder: (context, snapshot) {
                            final stockDisplay = snapshot.data ?? '0 / 0 / 0';
                            return _buildTableRow(article, index, stockDisplay);
                          },
                        );
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
      height: 25,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          _buildHeaderCell('DESIGNATION', 400),
          _buildHeaderCell('STOCKS DISPONIBLES', 350),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Article article, int index, String stockDisplay) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[50];

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          _buildCell(article.designation, 400),
          _buildCell(stockDisplay, 350, alignment: Alignment.centerRight, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCell(String text, double width, {Alignment alignment = Alignment.centerLeft, Color? color}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color ?? Colors.black),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton('Imprimer', () {}),
          const SizedBox(width: 8),
          _buildActionButton('Fermer', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}