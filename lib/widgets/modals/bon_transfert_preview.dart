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
              'BON DE TRANSFERT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _headerFontSize + 2,
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        SizedBox(height: _padding),

        // Header section with company and document info
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
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
                          'SOCIÉTÉ:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize - 1),
                        ),
                        Text(
                          societe?.rsoc ?? 'SOCIÉTÉ',
                          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
                        ),
                        if (societe?.activites != null)
                          Text(
                            societe!.activites!,
                            style: TextStyle(fontSize: _fontSize - 1),
                          ),
                        if (societe?.adr != null)
                          Text(
                            societe!.adr!,
                            style: TextStyle(fontSize: _fontSize - 1),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('N° DOCUMENT:', numTransfert),
                        _buildInfoRow('DATE:', _formatDate(date)),
                        _buildInfoRow('DE:', depotVenant),
                        _buildInfoRow('VERS:', depotVers),
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
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                color: Colors.grey[200],
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                    verticalInside: BorderSide(color: Colors.black, width: 0.5),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableCell('N°', isHeader: true),
                        _buildTableCell('DÉSIGNATION', isHeader: true),
                        _buildTableCell('UNITÉ', isHeader: true),
                        _buildTableCell('QUANTITÉ', isHeader: true),
                      ],
                    ),
                  ],
                ),
              ),
              // Table data
              Table(
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                  verticalInside: BorderSide(color: Colors.black, width: 0.5),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(4),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  ...lignesTransfert.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final ligne = entry.value;
                    return TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(ligne['designation'] ?? ''),
                        _buildTableCell(ligne['unites'] ?? ''),
                        _buildTableCell((ligne['quantite'] ?? 0).toString()),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: _padding * 2),

        // Signatures section
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: EdgeInsets.all(_padding),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'EXPÉDITEUR',
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: _padding * 2),
                    Container(
                      height: 1,
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    SizedBox(height: _padding / 2),
                    Text(
                      'Nom et signature',
                      style: TextStyle(fontSize: _fontSize - 2),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.black,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'RÉCEPTIONNAIRE',
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: _padding * 2),
                    Container(
                      height: 1,
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    SizedBox(height: _padding / 2),
                    Text(
                      'Nom et signature',
                      style: TextStyle(fontSize: _fontSize - 2),
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
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _fontSize - 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: _fontSize - 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: EdgeInsets.all(format == 'A6' ? 3 : 6),
      decoration: isHeader
          ? BoxDecoration(
              color: Colors.grey[200],
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: format == 'A6' ? 8 : (format == 'A5' ? 9 : 10),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isHeader
            ? TextAlign.center
            : (text.contains(RegExp(r'^\d+$')) ? TextAlign.center : TextAlign.left),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Générer le document PDF
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final pdfFontSize = format == 'A6' ? 7.0 : (format == 'A5' ? 9.0 : 10.0);
    final pdfHeaderFontSize = format == 'A6' ? 8.0 : (format == 'A5' ? 10.0 : 12.0);
    final pdfPadding = format == 'A6' ? 8.0 : (format == 'A5' ? 10.0 : 12.0);

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
                      'BON DE TRANSFERT',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: pdfHeaderFontSize + 2,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: pdfPadding),

                // Header section with company and document info
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
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
                                  'SOCIÉTÉ:',
                                  style:
                                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
                                ),
                                pw.Text(
                                  societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                                ),
                                if (societe?.activites != null)
                                  pw.Text(
                                    societe!.activites!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                                if (societe?.adr != null)
                                  pw.Text(
                                    societe!.adr!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('N° DOCUMENT:', numTransfert, pdfFontSize),
                                _buildPdfInfoRow('DATE:', _formatDate(date), pdfFontSize),
                                _buildPdfInfoRow('DE:', depotVenant, pdfFontSize),
                                _buildPdfInfoRow('VERS:', depotVers, pdfFontSize),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: pdfPadding),

                // Articles table
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      // Table header
                      pw.Container(
                        color: PdfColors.grey300,
                        child: pw.Table(
                          border: const pw.TableBorder(
                            horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                            verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                          ),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(1),
                            1: pw.FlexColumnWidth(4),
                            2: pw.FlexColumnWidth(1.5),
                            3: pw.FlexColumnWidth(1.5),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                _buildPdfTableCell('N°', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('DÉSIGNATION', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('UNITÉ', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('QUANTITÉ', pdfFontSize, isHeader: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Table data
                      pw.Table(
                        border: const pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                          verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                        ),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(4),
                          2: pw.FlexColumnWidth(1.5),
                          3: pw.FlexColumnWidth(1.5),
                        },
                        children: [
                          ...lignesTransfert.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final ligne = entry.value;
                            return pw.TableRow(
                              children: [
                                _buildPdfTableCell(index.toString(), pdfFontSize),
                                _buildPdfTableCell(ligne['designation'] ?? '', pdfFontSize),
                                _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                _buildPdfTableCell((ligne['quantite'] ?? 0).toString(), pdfFontSize),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: pdfPadding * 2),

                // Signatures section
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  padding: pw.EdgeInsets.all(pdfPadding),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'EXPÉDITEUR',
                              style: pw.TextStyle(
                                fontSize: pdfFontSize,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text(
                              'Nom et signature',
                              style: pw.TextStyle(fontSize: pdfFontSize - 2),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 1,
                        height: 60,
                        color: PdfColors.black,
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'RÉCEPTIONNAIRE',
                              style: pw.TextStyle(
                                fontSize: pdfFontSize,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text(
                              'Nom et signature',
                              style: pw.TextStyle(fontSize: pdfFontSize - 2),
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

  pw.Widget _buildPdfTableCell(String text, double fontSize, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(format == 'A6' ? 3 : 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader
            ? pw.TextAlign.center
            : (RegExp(r'^\d+$').hasMatch(text) ? pw.TextAlign.center : pw.TextAlign.left),
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
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: fontSize - 1,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: fontSize - 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
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
