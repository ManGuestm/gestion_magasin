import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../services/auth_service.dart';

class FacturePreview extends StatefulWidget {
  final String numVente;
  final String nFacture;
  final String date;
  final String client;
  final List<Map<String, dynamic>> lignesVente;
  final double remise;
  final double totalTTC;
  final String format;
  final SocData? societe;
  final String modePaiement;

  const FacturePreview({
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
    required this.modePaiement,
  });

  @override
  State<FacturePreview> createState() => _FacturePreviewState();
}

class _FacturePreviewState extends State<FacturePreview> {
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
        return PdfPageFormat.a5;
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
                const Icon(Icons.receipt, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Aperçu Facture N° ${widget.nFacture} - Format ${widget.format}',
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
                    onPressed: () => _imprimer(context),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimer'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
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
                    child: Container(padding: EdgeInsets.all(_padding), child: _buildFactureContent()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactureContent() {
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
              'FACTURE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: _headerFontSize + 2, letterSpacing: 2),
            ),
          ),
        ),

        SizedBox(height: _padding),

        // Header section with company and document info
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
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
                          widget.societe?.rsoc ?? 'SOCIÉTÉ',
                          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
                        ),
                        if (widget.societe?.activites != null)
                          Text(widget.societe!.activites!, style: TextStyle(fontSize: _fontSize - 1)),
                        if (widget.societe?.adr != null)
                          Text(widget.societe!.adr!, style: TextStyle(fontSize: _fontSize - 1)),
                        if (widget.societe?.rcs != null)
                          Text('RCS: ${widget.societe!.rcs!}', style: TextStyle(fontSize: _fontSize - 2)),
                        if (widget.societe?.nif != null)
                          Text('NIF: ${widget.societe!.nif!}', style: TextStyle(fontSize: _fontSize - 2)),
                        if (widget.societe?.stat != null)
                          Text('STAT: ${widget.societe!.stat!}', style: TextStyle(fontSize: _fontSize - 2)),
                        if (widget.societe?.cif != null)
                          Text('CIF: ${widget.societe!.cif!}', style: TextStyle(fontSize: _fontSize - 2)),
                        if (widget.societe?.email != null)
                          Text('Email: ${widget.societe!.email!}', style: TextStyle(fontSize: _fontSize - 2)),
                        if (widget.societe?.port != null)
                          Text('Tél: ${widget.societe!.port!}', style: TextStyle(fontSize: _fontSize - 2)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('N° FACTURE:', widget.nFacture),
                        _buildInfoRow('DATE:', widget.date),
                        _buildInfoRow('CLIENT:', widget.client),
                        _buildInfoRow('MODE PAIEMENT:', widget.modePaiement),
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
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          child: Column(
            children: [
              // Table header
              Container(
                color: Colors.grey[200],
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey, width: 0.5),
                    verticalInside: BorderSide.none,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableCell('N°', isHeader: true),
                        _buildTableCell('DÉSIGNATION', isHeader: true),
                        _buildTableCell('DÉPÔT', isHeader: true),
                        _buildTableCell('QTÉ', isHeader: true),
                        _buildTableCell('UNITÉ', isHeader: true),
                        _buildTableCell('PU HT', isHeader: true),
                        _buildTableCell('MONTANT', isHeader: true),
                      ],
                    ),
                  ],
                ),
              ),
              // Table data
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey, width: 0.5),
                  verticalInside: BorderSide.none,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1.5),
                  6: FlexColumnWidth(1.5),
                },
                children: [
                  ...widget.lignesVente.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final ligne = entry.value;
                    return TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(ligne['designation'] ?? ''),
                        _buildTableCell(ligne['depot'] ?? 'MAG'),
                        _buildTableCell(_formatNumber(ligne['quantite']?.toDouble() ?? 0)),
                        _buildTableCell(ligne['unites'] ?? ''),
                        _buildTableCell(_formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0)),
                        _buildTableCell(_formatNumber(ligne['montant']?.toDouble() ?? 0), isAmount: true),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: _padding),

        // Totals section
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
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
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.black)),
                        ),
                        child: _buildTotalRow('TOTAL TTC:', _formatNumber(widget.totalTTC), isBold: true),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: _padding / 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_padding / 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.5)),
                alignment: Alignment.center,
                child: Text(
                  'Arrêté à la somme de ${AppFunctions.numberToWords(widget.totalTTC.round())} Ariary',
                  style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: _padding * 2),

        // Signatures section
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
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
                    SizedBox(height: _padding * 2),
                    Container(
                      height: 1,
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    SizedBox(height: _padding / 2),
                    Text('Nom et signature', style: TextStyle(fontSize: _fontSize - 2)),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: Colors.black),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'VENDEUR',
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: _padding * 2),
                    Container(
                      height: 1,
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    SizedBox(height: _padding / 2),
                    Text('Nom et signature', style: TextStyle(fontSize: _fontSize - 2)),
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
              style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isAmount = false}) {
    return Container(
      padding: EdgeInsets.all(widget.format == 'A6' ? 3 * _zoomLevel : 6 * _zoomLevel),
      decoration: isHeader ? BoxDecoration(color: Colors.grey[200]) : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: (widget.format == 'A6' ? 8 : (widget.format == 'A5' ? 9 : 10)) * _zoomLevel,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isHeader ? TextAlign.center : (isAmount ? TextAlign.right : TextAlign.left),
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
                      'FACTURE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfHeaderFontSize + 2),
                    ),
                  ),
                ),

                pw.SizedBox(height: pdfPadding),

                // Header section with company and document info
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
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
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: pdfFontSize - 1,
                                  ),
                                ),
                                pw.Text(
                                  widget.societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                                ),
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
                                if (widget.societe?.rcs != null)
                                  pw.Text(
                                    'RCS: ${widget.societe!.rcs!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (widget.societe?.nif != null)
                                  pw.Text(
                                    'NIF: ${widget.societe!.nif!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (widget.societe?.stat != null)
                                  pw.Text(
                                    'STAT: ${widget.societe!.stat!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (widget.societe?.cif != null)
                                  pw.Text(
                                    'CIF: ${widget.societe!.cif!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (widget.societe?.email != null)
                                  pw.Text(
                                    'Email: ${widget.societe!.email!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (widget.societe?.port != null)
                                  pw.Text(
                                    'Tél: ${widget.societe!.port!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('N° FACTURE:', widget.nFacture, pdfFontSize),
                                _buildPdfInfoRow('DATE:', widget.date, pdfFontSize),
                                _buildPdfInfoRow('CLIENT:', widget.client, pdfFontSize),
                                _buildPdfInfoRow('MODE PAIEMENT:', widget.modePaiement, pdfFontSize),
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
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
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
                            1: pw.FlexColumnWidth(3),
                            2: pw.FlexColumnWidth(1),
                            3: pw.FlexColumnWidth(1),
                            4: pw.FlexColumnWidth(1),
                            5: pw.FlexColumnWidth(1.5),
                            6: pw.FlexColumnWidth(1.5),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                _buildPdfTableCell('N°', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('DÉSIGNATION', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('DÉPÔT', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('QTÉ', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('UNITÉ', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('PU HT', pdfFontSize, isHeader: true),
                                _buildPdfTableCell('MONTANT', pdfFontSize, isHeader: true),
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
                          1: pw.FlexColumnWidth(3),
                          2: pw.FlexColumnWidth(1),
                          3: pw.FlexColumnWidth(1),
                          4: pw.FlexColumnWidth(1),
                          5: pw.FlexColumnWidth(1.5),
                          6: pw.FlexColumnWidth(1.5),
                        },
                        children: [
                          ...widget.lignesVente.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final ligne = entry.value;
                            return pw.TableRow(
                              children: [
                                _buildPdfTableCell(index.toString(), pdfFontSize),
                                _buildPdfTableCell(ligne['designation'] ?? '', pdfFontSize),
                                _buildPdfTableCell(ligne['depot'] ?? 'MAG', pdfFontSize),
                                _buildPdfTableCell(
                                  _formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                  pdfFontSize,
                                ),
                                _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                _buildPdfTableCell(
                                  _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                  pdfFontSize,
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

                pw.SizedBox(height: pdfPadding),

                // Totals section
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
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
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                                ),
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
                      pw.SizedBox(height: pdfPadding / 2),
                      pw.Container(
                        width: double.infinity,
                        padding: pw.EdgeInsets.all(pdfPadding / 2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.5),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Arrêté à la somme de ${AppFunctions.numberToWords(widget.totalTTC.round())} Ariary',
                          style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: pdfPadding * 2),

                // Signatures section
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
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
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 60, color: PdfColors.black),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'VENDEUR',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
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

  pw.Widget _buildPdfTableCell(String text, double fontSize, {bool isHeader = false, bool isAmount = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(widget.format == 'A6' ? 3 : 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : (isAmount ? pw.TextAlign.right : pw.TextAlign.left),
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
              style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.normal),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
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
  Future<void> _imprimer(BuildContext context) async {
    try {
      // Générer le PDF
      final pdf = await _generatePdf();
      final bytes = await pdf.save();

      // Ouvrir directement la boîte de dialogue d'impression Windows
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Facture_${widget.nFacture}_${widget.date}.pdf',
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
