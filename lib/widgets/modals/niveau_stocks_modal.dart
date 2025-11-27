import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class NiveauStocksModal extends StatefulWidget {
  const NiveauStocksModal({super.key});

  @override
  State<NiveauStocksModal> createState() => _NiveauStocksModalState();
}

class _NiveauStocksModalState extends State<NiveauStocksModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _articlesACommander = [];
  bool _isLoading = true;
  double _seuilMinimum = 10.0;

  @override
  void initState() {
    super.initState();
    _loadArticlesACommander();
  }

  Future<void> _loadArticlesACommander() async {
    try {
      final allArticles = await _databaseService.database.getAllArticles();
      // Filtrer les articles avec stock faible
      final articlesACommander = allArticles.where((article) {
        final stockTotal = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
        return stockTotal <= _seuilMinimum;
      }).toList();

      setState(() {
        _articlesACommander = articlesACommander;
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

  Color _getStockColor(double stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= _seuilMinimum * 0.5) return Colors.orange;
    return Colors.yellow[700]!;
  }

  Future<void> _printDirect() async {
    if (_articlesACommander.isEmpty) {
      _showMessage('Aucune donnée à imprimer', Colors.orange[600]!);
      return;
    }

    try {
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.firstWhere(
        (printer) => printer.isDefault,
        orElse: () => printers.isNotEmpty ? printers.first : throw Exception('Aucune imprimante'),
      );

      await Printing.directPrintPdf(
        printer: defaultPrinter,
        onLayout: _generatePdf,
        usePrinterSettings: true,
      );
      _showMessage('Impression lancée vers ${defaultPrinter.name}', Colors.green[600]!);
    } catch (e) {
      _showMessage('Erreur lors de l\'impression: $e', Colors.red[600]!);
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NIVEAU DES STOCKS - ARTICLES À COMMANDER',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Seuil minimum: ${_seuilMinimum.toString()}'),
              pw.Text('Nombre d\'articles à commander: ${_articlesACommander.length}'),
              pw.Text('Date d\'impression: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildPdfHeaderCell('ARTICLE'),
                      _buildPdfHeaderCell('STOCK U1'),
                      _buildPdfHeaderCell('STOCK U2'),
                      _buildPdfHeaderCell('STOCK U3'),
                      _buildPdfHeaderCell('TOTAL'),
                      _buildPdfHeaderCell('STATUT'),
                    ],
                  ),
                  ..._articlesACommander.map((article) {
                    final stockTotal =
                        (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
                    return pw.TableRow(
                      children: [
                        _buildPdfCell(article.designation),
                        _buildPdfCell(NumberUtils.formatNumber(article.stocksu1 ?? 0)),
                        _buildPdfCell(NumberUtils.formatNumber(article.stocksu2 ?? 0)),
                        _buildPdfCell(NumberUtils.formatNumber(article.stocksu3 ?? 0)),
                        _buildPdfCell(NumberUtils.formatNumber(stockTotal)),
                        _buildPdfCell(stockTotal <= 0 ? 'Épuisé' : 'Faible'),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GESTION COMMERCIALE DES PME'),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())),
                  pw.Text('1'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Niveau des stocks (Articles à commander)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _printDirect,
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  children: [
                    const Text('Seuil minimum: '),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newSeuil = double.tryParse(value);
                          if (newSeuil != null) {
                            setState(() {
                              _seuilMinimum = newSeuil;
                              _isLoading = true;
                            });
                            _loadArticlesACommander();
                          }
                        },
                        controller: TextEditingController(text: _seuilMinimum.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_articlesACommander.length} article(s) à commander',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
                                color: Colors.red[100],
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
                                              Text('Total', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child:
                                              Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _articlesACommander.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                                          SizedBox(height: 16),
                                          Text('Tous les stocks sont suffisants'),
                                          Text('Aucun article à commander',
                                              style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _articlesACommander.length,
                                      itemBuilder: (context, index) {
                                        final article = _articlesACommander[index];
                                        final stockTotal = (article.stocksu1 ?? 0) +
                                            (article.stocksu2 ?? 0) +
                                            (article.stocksu3 ?? 0);
                                        final stockColor = _getStockColor(stockTotal);

                                        return Container(
                                          height: 40,
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
                                                    NumberUtils.formatNumber(stockTotal),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: stockColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: stockTotal <= 0 ? Colors.red : Colors.orange,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      stockTotal <= 0 ? 'Épuisé' : 'Faible',
                                                      style:
                                                          const TextStyle(fontSize: 9, color: Colors.white),
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
      ),
    );
  }
}
