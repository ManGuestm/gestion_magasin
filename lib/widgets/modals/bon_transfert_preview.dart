import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';

class BonTransfertPreview extends StatelessWidget {
  final String numTransfert;
  final DateTime date;
  final String depotVenant;
  final String depotVers;
  final List<Map<String, dynamic>> lignesTransfert;
  final SocData? societe;
  final String format;

  const BonTransfertPreview({
    super.key,
    required this.numTransfert,
    required this.date,
    required this.depotVenant,
    required this.depotVers,
    required this.lignesTransfert,
    this.societe,
    this.format = 'A5',
  });

  double get _pageWidth {
    switch (format) {
      case 'A4':
        return 800;
      case 'A6':
        return 400;
      default:
        return 600; // A5
    }
  }

  double get _pageHeight {
    switch (format) {
      case 'A4':
        return 1100;
      case 'A6':
        return 600;
      default:
        return 850; // A5
    }
  }

  double get _fontSize {
    switch (format) {
      case 'A6':
        return 9;
      case 'A5':
        return 11;
      default:
        return 12; // A4
    }
  }

  double get _headerFontSize {
    switch (format) {
      case 'A6':
        return 10;
      case 'A5':
        return 12;
      default:
        return 14; // A4
    }
  }

  double get _padding {
    switch (format) {
      case 'A6':
        return 8;
      case 'A5':
        return 12;
      default:
        return 16; // A4
    }
  }

  PdfPageFormat get _pdfPageFormat {
    switch (format) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A6':
        return PdfPageFormat.a6;
      default:
        return PdfPageFormat.a5; // A5
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Window title bar
          Container(
            height: 32,
            color: const Color(0xFF2D2D30),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Aperçu BT N° $numTransfert - Format $format',
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
                ElevatedButton.icon(
                  onPressed: () => _imprimer(context),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Imprimer'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                const Spacer(),
                Text('Format: $format', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Container(
                      padding: EdgeInsets.all(_padding),
                      child: _buildTransferContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Company info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    societe?.rsoc ?? 'SOCIÉTÉ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: _headerFontSize),
                  ),
                  if (societe?.activites != null)
                    Text(
                      societe!.activites!,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  if (societe?.adr != null)
                    Text(
                      societe!.adr!,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                ],
              ),
            ),
            // Right side - Transfer info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Date: ${_formatDate(date)}',
                  style: TextStyle(fontSize: _fontSize),
                ),
                Row(
                  children: [
                    Text('BON DE TRANSFERT N°',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                    SizedBox(width: format == 'A6' ? 4 : 8),
                    Text(numTransfert, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                  ],
                ),
                Text('De: $depotVenant', style: TextStyle(fontSize: _fontSize)),
                Text('Vers: $depotVers', style: TextStyle(fontSize: _fontSize)),
              ],
            ),
          ],
        ),

        SizedBox(height: format == 'A6' ? 10 : 20),

        // Table
        Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            // Header row
            TableRow(
              children: [
                _buildTableCell('DÉSIGNATION', isHeader: true),
                _buildTableCell('UNITÉ', isHeader: true),
                _buildTableCell('QUANTITÉ', isHeader: true),
              ],
            ),
            // Data rows
            ...lignesTransfert.map((ligne) => TableRow(
                  children: [
                    _buildTableCell(ligne['designation'] ?? ''),
                    _buildTableCell(ligne['unites'] ?? ''),
                    _buildTableCell((ligne['quantite'] ?? 0).toString()),
                  ],
                )),
          ],
        ),

        SizedBox(height: format == 'A6' ? 20 : 40),

        // Footer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              width: 100,
              child: Text(
                'Expéditeur,',
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
            const Spacer(),
            Container(
              alignment: Alignment.center,
              width: 100,
              child: Text(
                'Réceptionnaire,',
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: EdgeInsets.all(format == 'A6' ? 2 : 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: format == 'A6' ? 9 : (format == 'A5' ? 10 : 11),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Générer le document PDF
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final pdfFontSize = format == 'A6' ? 7.0 : (format == 'A5' ? 9.0 : 10.0);
    final pdfHeaderFontSize = format == 'A6' ? 8.0 : (format == 'A5' ? 10.0 : 12.0);
    final pdfPadding = format == 'A6' ? 6.0 : (format == 'A5' ? 10.0 : 15.0);

    pdf.addPage(
      pw.Page(
        pageFormat: _pdfPageFormat,
        build: (context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left side - Company info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            societe?.rsoc ?? 'SOCIÉTÉ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfHeaderFontSize),
                          ),
                          if (societe?.activites != null)
                            pw.Text(
                              societe!.activites!,
                              style: pw.TextStyle(fontSize: pdfFontSize),
                            ),
                          if (societe?.adr != null)
                            pw.Text(
                              societe!.adr!,
                              style: pw.TextStyle(fontSize: pdfFontSize),
                            ),
                        ],
                      ),
                    ),
                    // Right side - Transfer info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${_formatDate(date)}',
                          style: pw.TextStyle(fontSize: pdfFontSize),
                        ),
                        pw.Row(
                          children: [
                            pw.Text('BON DE TRANSFERT N°',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize)),
                            pw.SizedBox(width: format == 'A6' ? 3 : 5),
                            pw.Text(numTransfert,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize)),
                          ],
                        ),
                        pw.Text('De: $depotVenant', style: pw.TextStyle(fontSize: pdfFontSize)),
                        pw.Text('Vers: $depotVers', style: pw.TextStyle(fontSize: pdfFontSize)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: format == 'A6' ? 8 : 15),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(4),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      children: [
                        _buildPdfTableCell('DÉSIGNATION', pdfFontSize, isHeader: true),
                        _buildPdfTableCell('UNITÉ', pdfFontSize, isHeader: true),
                        _buildPdfTableCell('QUANTITÉ', pdfFontSize, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...lignesTransfert.map((ligne) => pw.TableRow(
                          children: [
                            _buildPdfTableCell(ligne['designation'] ?? '', pdfFontSize),
                            _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                            _buildPdfTableCell((ligne['quantite'] ?? 0).toString(), pdfFontSize),
                          ],
                        )),
                  ],
                ),

                pw.SizedBox(height: format == 'A6' ? 20 : 40),

                // Footer
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      width: 80,
                      child: pw.Text(
                        'Expéditeur,',
                        style: pw.TextStyle(fontSize: pdfFontSize),
                      ),
                    ),
                    pw.Spacer(),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      width: 80,
                      child: pw.Text(
                        'Réceptionnaire,',
                        style: pw.TextStyle(fontSize: pdfFontSize),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfTableCell(String text, double fontSize, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(format == 'A6' ? 2 : 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  // Fonction d'impression
  Future<void> _imprimer(BuildContext context) async {
    try {
      // Générer le PDF
      final pdf = await _generatePdf();
      final bytes = await pdf.save();

      // Ouvrir directement la boîte de dialogue d'impression Windows
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'BT_${numTransfert}_${date.day}-${date.month}-${date.year}.pdf',
        format: _pdfPageFormat,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
