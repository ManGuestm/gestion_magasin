import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../services/auth_service.dart';
import '../common/tab_navigation_widget.dart';

class BonLivraisonPreview extends StatefulWidget {
  final String numVente;
  final String nFacture;
  final String date;
  final String client;
  final List<Map<String, dynamic>> lignesVente;
  final double remise;
  final double totalTTC;
  final String format;
  final SocData? societe;

  const BonLivraisonPreview({
    super.key,
    required this.numVente,
    required this.nFacture,
    required this.date,
    required this.client,
    required this.lignesVente,
    required this.remise,
    required this.totalTTC,
    required this.format,
    this.societe,
  });

  @override
  State<BonLivraisonPreview> createState() => _BonLivraisonPreviewState();
}

class _BonLivraisonPreviewState extends State<BonLivraisonPreview> with TabNavigationMixin {
  double _zoomLevel = 1.0;

  double get _pageWidth {
    switch (widget.format) {
      case 'A4':
        return 800 * _zoomLevel;
      case 'A6':
        return 400 * _zoomLevel;
      default:
        return 600 * _zoomLevel;
    }
  }

  double get _pageHeight {
    switch (widget.format) {
      case 'A4':
        return 1100 * _zoomLevel;
      case 'A6':
        return 600 * _zoomLevel;
      default:
        return 850 * _zoomLevel;
    }
  }

  double get _fontSize {
    switch (widget.format) {
      case 'A6':
        return 9 * _zoomLevel;
      case 'A5':
        return 11 * _zoomLevel;
      default:
        return 12 * _zoomLevel;
    }
  }

  double get _headerFontSize {
    switch (widget.format) {
      case 'A6':
        return 10 * _zoomLevel;
      case 'A5':
        return 12 * _zoomLevel;
      default:
        return 14 * _zoomLevel;
    }
  }

  double get _padding {
    switch (widget.format) {
      case 'A6':
        return 8 * _zoomLevel;
      case 'A5':
        return 12 * _zoomLevel;
      default:
        return 16 * _zoomLevel;
    }
  }

  PdfPageFormat get _pdfPageFormat {
    switch (widget.format) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A6':
        return PdfPageFormat.a6;
      default:
        return PdfPageFormat.a5; // A5
    }
  }

  bool _canPrint() {
    final authService = AuthService();
    final role = authService.currentUserRole;
    return role == 'Administrateur' || role == 'Caisse';
  }

  String _formatNumber(double number) {
    String integerPart = number.round().toString();
    String formatted = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formatted += ' ';
      }
      formatted += integerPart[i];
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Scaffold(
        body: Column(
          children: [
            // Window title bar
            Container(
              height: 32,
              color: const Color(0xFF2D2D30),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.receipt, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Aperçu BL N° ${widget.numVente} - Format ${widget.format}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Toolbar
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  if (_canPrint()) ...[
                    ElevatedButton.icon(
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.teal)),
                      onPressed: () => _imprimer(),
                      icon: const Icon(Icons.print, size: 16, color: Colors.white),
                      label: const Text('Imprimer', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                  ],

                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 2.0)),
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom -',
                  ),
                  Text('${(_zoomLevel * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 2.0)),
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom +',
                  ),
                  IconButton(
                    onPressed: () => setState(() => _zoomLevel = 1.0),
                    icon: const Icon(Icons.fit_screen),
                    tooltip: 'Réinitialiser',
                  ),
                  const Spacer(),
                  Text('Format: ${widget.format}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            // Preview
            Expanded(
              child: Container(
                color: Colors.grey[300],
                child: Center(
                  child: Container(
                    width: _pageWidth,
                    height: _pageHeight,
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Container(padding: EdgeInsets.all(_padding), child: _buildLivraisonContent()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivraisonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.format != 'A6') ...[
          // Document title centered
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: _padding / 2),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Text(
                'BON DE LIVRAISON',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _headerFontSize + 2,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],

        SizedBox(height: _padding),

        // Header section with company and document info
        Container(
          // decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 1)),
          padding: EdgeInsets.all(_padding / 2),
          child: Column(
            children: [
              // Company info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.societe?.rsoc ?? 'SOCIÉTÉ',
                          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
                        ),
                        if (widget.format != 'A6') ...[
                          if (widget.societe?.activites != null)
                            Text(widget.societe!.activites!, style: TextStyle(fontSize: _fontSize - 1)),
                          if (widget.societe?.adr != null)
                            Text(widget.societe!.adr!, style: TextStyle(fontSize: _fontSize - 1)),
                          if (widget.societe?.tel != null)
                            Text(widget.societe!.tel!, style: TextStyle(fontSize: _fontSize - 1)),
                        ],
                        if (widget.societe?.rcs != null)
                          Text(
                            "RCS: ${widget.societe!.rcs!}",
                            style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('DATE:', widget.date),
                        _buildInfoRow('BON DE LIVRAISON N°:', widget.nFacture),
                        _buildInfoRow('Doit:', widget.client),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: _padding),

        // Articles table
        Container(
          padding: EdgeInsets.all(_padding / 2),
          child: Column(
            children: [
              // Table header
              widget.format != 'A6'
                  ? Container(
                      color: Colors.grey[200],
                      child: Table(
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey, width: 0.5),
                          verticalInside: BorderSide.none,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(2),
                          5: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              _buildTableCell('Désignation', isHeader: true, isArticle: true),
                              _buildTableCell('Dépôts', isHeader: true),
                              _buildTableCell('Q', isHeader: true),
                              _buildTableCell('Unité', isHeader: true),
                              _buildTableCell('PU HT', isHeader: true),
                              _buildTableCell('Montant', isHeader: true),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Table(
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey, width: 0.5),
                          verticalInside: BorderSide.none,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              _buildTableCell('Désignation', isHeader: true, isArticle: true),
                              _buildTableCell('Q', isHeader: true),
                              _buildTableCell('Unité', isHeader: true),
                              _buildTableCell('PU HT', isHeader: true),
                              _buildTableCell('Montant', isHeader: true),
                            ],
                          ),
                        ],
                      ),
                    ),
              // Table data
              widget.format != 'A6'
                  ? Table(
                      border: const TableBorder(
                        bottom: BorderSide(color: Colors.black, width: 0.75),
                        top: BorderSide(color: Colors.grey, width: 0.5),
                        horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                      },
                      children: [
                        ...widget.lignesVente.asMap().entries.map((entry) {
                          final ligne = entry.value;
                          return TableRow(
                            children: [
                              _buildTableCell(ligne['designation'] ?? '', isArticle: true),
                              _buildTableCell(ligne['depot'] ?? 'MAG'),
                              _buildTableCell(_formatNumber(ligne['quantite']?.toDouble() ?? 0)),
                              _buildTableCell(ligne['unites'] ?? ''),
                              _buildTableCell(
                                _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                isAmount: true,
                              ),
                              _buildTableCell(
                                _formatNumber(ligne['montant']?.toDouble() ?? 0),
                                isAmount: true,
                              ),
                            ],
                          );
                        }),
                      ],
                    )
                  : Table(
                      border: const TableBorder(
                        bottom: BorderSide(color: Colors.black, width: 0.75),
                        top: BorderSide(color: Colors.grey, width: 0.5),
                        horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                      },
                      children: [
                        ...widget.lignesVente.asMap().entries.map((entry) {
                          final ligne = entry.value;
                          return TableRow(
                            children: [
                              _buildTableCell(ligne['designation'] ?? '', isArticle: true),
                              _buildTableCell(_formatNumber(ligne['quantite']?.toDouble() ?? 0)),
                              _buildTableCell(ligne['unites'] ?? ''),
                              _buildTableCell(
                                _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                isAmount: true,
                              ),
                              _buildTableCell(
                                _formatNumber(ligne['montant']?.toDouble() ?? 0),
                                isAmount: true,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
            ],
          ),
        ),

        // Totals section
        Container(
          padding: EdgeInsets.all(_padding / 2),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.remise > 0) _buildTotalRow('REMISE:', _formatNumber(widget.remise)),
                      Container(
                        child: _buildTotalRow('TOTAL TTC:', _formatNumber(widget.totalTTC), isBold: true),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_padding / 2),
                alignment: Alignment.center,
                child: Text(
                  'Arrêté à la somme de ${AppFunctions.numberToWords(widget.totalTTC.round())} Ariary',
                  style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (widget.format != 'A6')
          // Signatures section
          Container(
            padding: EdgeInsets.all(_padding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'CLIENT',
                        style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'LIVREUR',
                        style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Text(
              label,
              style: TextStyle(fontSize: _fontSize - 2, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isArticle = false,
    bool isAmount = false,
  }) {
    return Container(
      alignment: isArticle
          ? Alignment.centerLeft
          : isAmount
          ? Alignment.centerRight
          : Alignment.center,
      padding: EdgeInsets.all(widget.format == 'A6' ? 3 * _zoomLevel : 6 * _zoomLevel),
      decoration: isHeader ? BoxDecoration(color: Colors.grey[200]) : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: (widget.format == 'A6' ? 8 : (widget.format == 'A5' ? 9 : 10)) * _zoomLevel,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _fontSize - 1,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: _fontSize - 1,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Générer le document PDF
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final pdfFontSize = widget.format == 'A6' ? 7.0 : (widget.format == 'A5' ? 9.0 : 10.0);
    final pdfHeaderFontSize = widget.format == 'A6' ? 8.0 : (widget.format == 'A5' ? 10.0 : 12.0);
    final pdfPadding = widget.format == 'A6' ? 8.0 : (widget.format == 'A5' ? 10.0 : 12.0);

    pdf.addPage(
      pw.Page(
        pageFormat: _pdfPageFormat,
        margin: const pw.EdgeInsets.all(3),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (widget.format != 'A6')
                  // Document title centered
                  pw.Center(
                    child: pw.Container(
                      padding: pw.EdgeInsets.symmetric(vertical: pdfPadding / 2),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 2),
                          bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                        ),
                      ),
                      child: pw.Text(
                        'BON DE LIVRAISON',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfHeaderFontSize + 2),
                      ),
                    ),
                  ),

                // Header section with company and document info
                pw.Container(
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Column(
                    children: [
                      // Company info row
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  widget.societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                                ),
                                if (widget.format != 'A6') ...[
                                  if (widget.societe?.activites != null)
                                    pw.Text(
                                      widget.societe!.activites!,
                                      style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                    ),
                                  if (widget.societe?.adr != null)
                                    pw.Text(
                                      widget.societe!.adr!,
                                      style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                    ),
                                ],
                                if (widget.societe?.rcs != null)
                                  pw.Text(
                                    "RCS: ${widget.societe!.rcs!}",
                                    style: pw.TextStyle(
                                      fontSize: pdfFontSize - 1,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('DATE:', widget.date, pdfFontSize),
                                _buildPdfInfoRow('BON DE LIVRAISON:', widget.nFacture, pdfFontSize),
                                _buildPdfInfoRow('Doit:', widget.client, pdfFontSize),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Articles table
                pw.Container(
                  child: pw.Column(
                    children: [
                      // Table header
                      widget.format != 'A6'
                          ? pw.Container(
                              color: PdfColors.grey300,
                              child: pw.Table(
                                border: const pw.TableBorder(
                                  horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                  verticalInside: pw.BorderSide.none,
                                ),
                                columnWidths: const {
                                  0: pw.FlexColumnWidth(4),
                                  1: pw.FlexColumnWidth(1),
                                  2: pw.FlexColumnWidth(1),
                                  3: pw.FlexColumnWidth(1),
                                  4: pw.FlexColumnWidth(2),
                                  5: pw.FlexColumnWidth(2),
                                },
                                children: [
                                  pw.TableRow(
                                    children: [
                                      _buildPdfTableCell('Désignation', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Dépôts', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Q', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Unité', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('PU HT', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Montant', pdfFontSize, isHeader: true),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : pw.Container(
                              color: PdfColors.grey300,
                              child: pw.Table(
                                border: const pw.TableBorder(
                                  horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                  verticalInside: pw.BorderSide.none,
                                ),
                                columnWidths: const {
                                  0: pw.FlexColumnWidth(4),
                                  1: pw.FlexColumnWidth(1),
                                  2: pw.FlexColumnWidth(1),
                                  3: pw.FlexColumnWidth(2),
                                  4: pw.FlexColumnWidth(2),
                                },
                                children: [
                                  pw.TableRow(
                                    children: [
                                      _buildPdfTableCell('Désignation', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Q', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Unité', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('PU HT', pdfFontSize, isHeader: true),
                                      _buildPdfTableCell('Montant', pdfFontSize, isHeader: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      // Table data
                      widget.format != 'A6'
                          ? pw.Table(
                              border: const pw.TableBorder(
                                horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                bottom: pw.BorderSide(color: PdfColors.black, width: 0.75),
                              ),
                              columnWidths: const {
                                0: pw.FlexColumnWidth(4),
                                1: pw.FlexColumnWidth(1),
                                2: pw.FlexColumnWidth(1),
                                3: pw.FlexColumnWidth(1),
                                4: pw.FlexColumnWidth(2),
                                5: pw.FlexColumnWidth(2),
                              },
                              children: [
                                ...widget.lignesVente.asMap().entries.map((entry) {
                                  final ligne = entry.value;
                                  return pw.TableRow(
                                    children: [
                                      _buildPdfTableCell(
                                        ligne['designation'] ?? '',
                                        pdfFontSize,
                                        isArticle: true,
                                      ),
                                      _buildPdfTableCell(ligne['depot'] ?? 'MAG', pdfFontSize),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                        pdfFontSize,
                                      ),
                                      _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                        pdfFontSize,
                                        isAmount: true,
                                      ),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['montant']?.toDouble() ?? 0),
                                        pdfFontSize,
                                        isAmount: true,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            )
                          : pw.Table(
                              border: const pw.TableBorder(
                                horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                bottom: pw.BorderSide(color: PdfColors.black, width: 0.75),
                              ),
                              columnWidths: const {
                                0: pw.FlexColumnWidth(4),
                                1: pw.FlexColumnWidth(1),
                                2: pw.FlexColumnWidth(1),
                                3: pw.FlexColumnWidth(2),
                                4: pw.FlexColumnWidth(2),
                              },
                              children: [
                                ...widget.lignesVente.asMap().entries.map((entry) {
                                  final ligne = entry.value;
                                  return pw.TableRow(
                                    children: [
                                      _buildPdfTableCell(
                                        ligne['designation'] ?? '',
                                        pdfFontSize,
                                        isArticle: true,
                                      ),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                        pdfFontSize,
                                      ),
                                      _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                        pdfFontSize,
                                        isAmount: true,
                                      ),
                                      _buildPdfTableCell(
                                        _formatNumber(ligne['montant']?.toDouble() ?? 0),
                                        pdfFontSize,
                                        isAmount: true,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                    ],
                  ),
                ),

                // Totals section
                pw.Container(
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Spacer(),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              if (widget.remise > 0)
                                _buildPdfTotalRow('REMISE:', _formatNumber(widget.remise), pdfFontSize),
                              pw.Container(
                                child: _buildPdfTotalRow(
                                  'TOTAL TTC:',
                                  _formatNumber(widget.totalTTC),
                                  pdfFontSize,
                                  isBold: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Container(
                        width: double.infinity,
                        padding: pw.EdgeInsets.all(pdfPadding / 2),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Arrêté à la somme de ${AppFunctions.numberToWords(widget.totalTTC.round())} Ariary',
                          style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.format != 'A6')
                  // Signatures section
                  pw.Container(
                    padding: pw.EdgeInsets.all(pdfPadding),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'CLIENT',
                                style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'LIVREUR',
                                style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfTableCell(
    String text,
    double fontSize, {
    bool isHeader = false,
    bool isArticle = false,
    bool isAmount = false,
  }) {
    return pw.Container(
      alignment: isArticle
          ? pw.Alignment.centerLeft
          : isAmount
          ? pw.Alignment.centerRight
          : pw.Alignment.center,
      padding: pw.EdgeInsets.all(widget.format == 'A6' ? 3 : 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTotalRow(String label, String value, double fontSize, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Fonction d'impression
  Future<void> _imprimer() async {
    if (widget.lignesVente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.75,
          ),
          content: const Text('Aucun article à imprimer'),
        ),
      );
      return;
    }

    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();

      // Obtenir la liste des imprimantes et trouver celle par défaut
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL${widget.nFacture}_${widget.date.replaceAll('/', '-')}.pdf',
          format: widget.format == 'A4'
              ? PdfPageFormat.a4
              : (widget.format == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        // Fallback vers la boîte de dialogue si aucune imprimante par défaut
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL${widget.nFacture}_${widget.date.replaceAll('/', '-')}.pdf',
          format: widget.format == 'A4'
              ? PdfPageFormat.a4
              : (widget.format == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: const Text('Bon de livraison envoyée à l\'imprimante par défaut'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: Text('Erreur d\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
