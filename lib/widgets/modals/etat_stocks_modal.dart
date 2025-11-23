import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/stock_converter.dart';
import '../common/tab_navigation_widget.dart';

class EtatStocksModal extends StatefulWidget {
  const EtatStocksModal({super.key});

  @override
  State<EtatStocksModal> createState() => _EtatStocksModalState();
}

class _EtatStocksModalState extends State<EtatStocksModal> with TabNavigationMixin {
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
      final db = DatabaseService().database;
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
      final db = DatabaseService().database;
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
        width: 900,
        height: 750,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 3),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildCompanyHeader(),
            _buildReportTitle(),
            _buildFilterSection(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RALAIZANDRY Jean Frédéric',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Marchandises Générales - Gros/détails',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      Text(
                        'Lot IVO 69 D Antohomadnika Sud',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tél.: 020 22 123 45', style: TextStyle(fontSize: 11)),
                      Text('Portable: 034 21 363 03', style: TextStyle(fontSize: 11)),
                      Text('Fax: 020 22 123 46', style: TextStyle(fontSize: 11)),
                      Text('e-mail: contact@magasin.mg', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RCS: 2023 B 00123', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text('NIF: 3000123456', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text('STAT: 12345678901234', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTitle() {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.grey[100],
      ),
      child: Text(
        'ÉTAT DE STOCKS AU $today',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          const Text(
            'DÉPÔTS:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
            ),
            child: Text(
              _selectedDepot,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          Text(
            'Total articles: ${_articles.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
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
                      itemExtent: 24,
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
      height: 35,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.grey[800],
      ),
      child: Row(
        children: [
          _buildHeaderCell('N°', 50),
          _buildHeaderCell('DÉSIGNATION', 450),
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
          right: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Article article, int index, String stockDisplay) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[50];
    final isLowStock = _isLowStock(stockDisplay);

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          left: const BorderSide(color: Colors.black, width: 1),
          right: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildCell('${index + 1}', 50, alignment: Alignment.center, color: Colors.grey[600]),
          _buildCell(article.designation, 450),
          _buildCell(
            stockDisplay,
            350,
            alignment: Alignment.centerRight,
            color: isLowStock ? Colors.red[700] : Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  bool _isLowStock(String stockDisplay) {
    // Simple check for low stock (you can customize this logic)
    return stockDisplay.contains('0 ') || stockDisplay == '0';
  }

  Widget _buildCell(
    String text,
    double width, {
    Alignment alignment = Alignment.centerLeft,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color ?? Colors.black87,
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Édité le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildActionButton('Imprimer', Icons.print, _imprimerEtatStocks),
          const SizedBox(width: 12),
          _buildActionButton('Fermer', Icons.close, () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Future<void> _imprimerEtatStocks() async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Préparer les données de stock
    final List<Map<String, String>> stockData = [];
    for (int i = 0; i < _articles.length; i++) {
      final article = _articles[i];
      final stockDisplay = await _formatGlobalStockDisplay(article);
      stockData.add({
        'numero': '${i + 1}',
        'designation': article.designation,
        'stock': stockDisplay,
      });
    }

    // Pagination: environ 35 lignes par page
    const int lignesParPage = 35;
    final int nombrePages = (stockData.length / lignesParPage).ceil();

    for (int pageIndex = 0; pageIndex < nombrePages; pageIndex++) {
      final int debut = pageIndex * lignesParPage;
      final int fin = (debut + lignesParPage < stockData.length) ? debut + lignesParPage : stockData.length;
      final List<Map<String, String>> donneesPage = stockData.sublist(debut, fin);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          header: (pw.Context context) => _buildPdfHeader(today, pageIndex + 1, nombrePages),
          footer: (pw.Context context) => _buildPdfFooter(),
          build: (pw.Context context) => [
            // Tableau des stocks pour cette page
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // En-tête du tableau
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  children: [
                    _buildPdfHeaderCell('N°'),
                    _buildPdfHeaderCell('DÉSIGNATION'),
                    _buildPdfHeaderCell('STOCKS DISPONIBLES'),
                  ],
                ),
                // Lignes de données pour cette page
                ...donneesPage.map((item) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: int.parse(item['numero']!) % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                      ),
                      children: [
                        _buildPdfCell(item['numero']!, align: pw.TextAlign.center),
                        _buildPdfCell(item['designation']!),
                        _buildPdfCell(item['stock']!, align: pw.TextAlign.right),
                      ],
                    )),
              ],
            ),
          ],
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Etat_Stocks_$today.pdf',
    );
  }

  pw.Widget _buildPdfHeader(String today, int pageActuelle, int totalPages) {
    return pw.Column(
      children: [
        // En-tête société
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RALAIZANDRY Jean Frédéric',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Marchandises Générales - Gros/détails', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Lot IVO 69 D Antohomadnika Sud', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Tél.: 020 22 123 45', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Portable: 034 21 363 03', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Fax: 020 22 123 46', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('e-mail: contact@magasin.mg', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Informations légales
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('RCS: 2023 B 00123', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('NIF: 3000123456', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('STAT: 12345678901234', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Titre du rapport
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
            color: PdfColors.grey300,
          ),
          child: pw.Center(
            child: pw.Text(
              'ÉTAT DE STOCKS AU $today',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(height: 8),

        // Informations du filtre et pagination
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 1),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('DÉPÔTS: $_selectedDepot - Total: ${_articles.length} articles',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Page $pageActuelle / $totalPages',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 1),
        color: PdfColors.grey100,
      ),
      child: pw.Text(
        'Édité le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: align,
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: text == 'Fermer' ? Colors.grey[600] : Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}
