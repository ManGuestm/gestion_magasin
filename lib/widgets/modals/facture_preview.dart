import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';

class FacturePreview extends StatelessWidget {
  final String numVente;
  final String nFacture;
  final String date;
  final String client;
  final List<Map<String, dynamic>> lignesVente;
  final double totalHT;
  final double remise;
  final double tva;
  final double totalTTC;
  final String format;
  final SocData? societe;
  final String modePaiement;
  final double montantRecu;
  final double monnaieARendre;

  const FacturePreview({
    super.key,
    required this.numVente,
    required this.nFacture,
    required this.date,
    required this.client,
    required this.lignesVente,
    required this.totalHT,
    required this.remise,
    required this.tva,
    required this.totalTTC,
    required this.format,
    this.societe,
    required this.modePaiement,
    required this.montantRecu,
    required this.monnaieARendre,
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

  String _numberToWords(int number) {
    if (number == 0) return 'zéro';

    final units = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf'];
    final teens = [
      'dix',
      'onze',
      'douze',
      'treize',
      'quatorze',
      'quinze',
      'seize',
      'dix-sept',
      'dix-huit',
      'dix-neuf'
    ];
    final tens = [
      '',
      '',
      'vingt',
      'trente',
      'quarante',
      'cinquante',
      'soixante',
      'soixante-dix',
      'quatre-vingt',
      'quatre-vingt-dix'
    ];

    String convertHundreds(int n) {
      String result = '';

      if (n >= 100) {
        int hundreds = n ~/ 100;
        if (hundreds == 1) {
          result += 'cent';
        } else {
          result += '${units[hundreds]} cent';
        }
        if (n % 100 == 0) result += 's';
        n %= 100;
        if (n > 0) result += ' ';
      }

      if (n >= 20) {
        int tensDigit = n ~/ 10;
        int unitsDigit = n % 10;

        if (tensDigit == 7) {
          result += 'soixante';
          if (unitsDigit == 1) {
            result += ' et onze';
          } else if (unitsDigit > 1) {
            result += '-${teens[unitsDigit]}';
          } else {
            result += '-dix';
          }
        } else if (tensDigit == 9) {
          result += 'quatre-vingt';
          if (unitsDigit == 1) {
            result += ' et onze';
          } else if (unitsDigit > 1) {
            result += '-${teens[unitsDigit]}';
          } else {
            result += '-dix';
          }
        } else {
          result += tens[tensDigit];
          if (unitsDigit == 1 &&
              (tensDigit == 2 || tensDigit == 3 || tensDigit == 4 || tensDigit == 5 || tensDigit == 6)) {
            result += ' et un';
          } else if (unitsDigit > 1) {
            result += '-${units[unitsDigit]}';
          }
        }
      } else if (n >= 10) {
        result += teens[n - 10];
      } else if (n > 0) {
        result += units[n];
      }

      return result;
    }

    String result = '';

    if (number >= 1000000) {
      int millions = number ~/ 1000000;
      if (millions == 1) {
        result += 'un million';
      } else {
        result += '${convertHundreds(millions)} million';
      }
      if (millions > 1) result += 's';
      number %= 1000000;
      if (number > 0) result += ' ';
    }

    if (number >= 1000) {
      int thousands = number ~/ 1000;
      if (thousands == 1) {
        result += 'mille';
      } else {
        result += '${convertHundreds(thousands)} mille';
      }
      number %= 1000;
      if (number > 0) result += ' ';
    }

    if (number > 0) {
      result += convertHundreds(number);
    }

    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
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
                  'Aperçu Facture N° $nFacture - Format $format',
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
                      child: _buildFactureContent(),
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
                        if (societe?.rcs != null)
                          Text(
                            'RCS: ${societe!.rcs!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                        if (societe?.nif != null)
                          Text(
                            'NIF: ${societe!.nif!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                        if (societe?.stat != null)
                          Text(
                            'STAT: ${societe!.stat!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                        if (societe?.cif != null)
                          Text(
                            'CIF: ${societe!.cif!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                        if (societe?.email != null)
                          Text(
                            'Email: ${societe!.email!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                        if (societe?.port != null)
                          Text(
                            'Tél: ${societe!.port!}',
                            style: TextStyle(fontSize: _fontSize - 2),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('N° FACTURE:', nFacture),
                        _buildInfoRow('DATE:', date),
                        _buildInfoRow('CLIENT:', client),
                        _buildInfoRow('MODE PAIEMENT:', modePaiement),
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
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                  verticalInside: BorderSide(color: Colors.black, width: 0.5),
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
                  ...lignesVente.asMap().entries.map((entry) {
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
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: EdgeInsets.all(_padding / 2),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTotalRow('TOTAL HT:', _formatNumber(totalHT)),
                      if (remise > 0) _buildTotalRow('REMISE:', _formatNumber(remise)),
                      if (tva > 0) _buildTotalRow('TVA:', _formatNumber(tva)),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.black)),
                        ),
                        child: _buildTotalRow('TOTAL TTC:', _formatNumber(totalTTC), isBold: true),
                      ),
                      SizedBox(height: _padding / 2),
                      _buildTotalRow('MONTANT REÇU:', _formatNumber(montantRecu)),
                      _buildTotalRow('MONNAIE À RENDRE:', _formatNumber(monnaieARendre)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: _padding / 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_padding / 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Arrêté à la somme de ${_numberToWords(totalTTC.round())} Ariary',
                  style: TextStyle(
                    fontSize: _fontSize - 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      'CLIENT',
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
                      'VENDEUR',
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

  Widget _buildTableCell(String text, {bool isHeader = false, bool isAmount = false}) {
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
                      'FACTURE',
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
                                if (societe?.rcs != null)
                                  pw.Text(
                                    'RCS: ${societe!.rcs!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (societe?.nif != null)
                                  pw.Text(
                                    'NIF: ${societe!.nif!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (societe?.stat != null)
                                  pw.Text(
                                    'STAT: ${societe!.stat!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (societe?.cif != null)
                                  pw.Text(
                                    'CIF: ${societe!.cif!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (societe?.email != null)
                                  pw.Text(
                                    'Email: ${societe!.email!}',
                                    style: pw.TextStyle(fontSize: pdfFontSize - 2),
                                  ),
                                if (societe?.port != null)
                                  pw.Text(
                                    'Tél: ${societe!.port!}',
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
                                _buildPdfInfoRow('N° FACTURE:', nFacture, pdfFontSize),
                                _buildPdfInfoRow('DATE:', date, pdfFontSize),
                                _buildPdfInfoRow('CLIENT:', client, pdfFontSize),
                                _buildPdfInfoRow('MODE PAIEMENT:', modePaiement, pdfFontSize),
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
                          ...lignesVente.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final ligne = entry.value;
                            return pw.TableRow(
                              children: [
                                _buildPdfTableCell(index.toString(), pdfFontSize),
                                _buildPdfTableCell(ligne['designation'] ?? '', pdfFontSize),
                                _buildPdfTableCell(ligne['depot'] ?? 'MAG', pdfFontSize),
                                _buildPdfTableCell(
                                    _formatNumber(ligne['quantite']?.toDouble() ?? 0), pdfFontSize),
                                _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                _buildPdfTableCell(
                                    _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0), pdfFontSize),
                                _buildPdfTableCell(
                                    _formatNumber(ligne['montant']?.toDouble() ?? 0), pdfFontSize,
                                    isAmount: true),
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
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Spacer(),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              _buildPdfTotalRow('TOTAL HT:', _formatNumber(totalHT), pdfFontSize),
                              if (remise > 0)
                                _buildPdfTotalRow('REMISE:', _formatNumber(remise), pdfFontSize),
                              if (tva > 0) _buildPdfTotalRow('TVA:', _formatNumber(tva), pdfFontSize),
                              pw.Container(
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                                ),
                                child: _buildPdfTotalRow('TOTAL TTC:', _formatNumber(totalTTC), pdfFontSize,
                                    isBold: true),
                              ),
                              pw.SizedBox(height: pdfPadding / 2),
                              _buildPdfTotalRow('MONTANT REÇU:', _formatNumber(montantRecu), pdfFontSize),
                              _buildPdfTotalRow(
                                  'MONNAIE À RENDRE:', _formatNumber(monnaieARendre), pdfFontSize),
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
                          'Arrêté à la somme de ${_numberToWords(totalTTC.round())} Ariary',
                          style: pw.TextStyle(
                            fontSize: pdfFontSize - 1,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
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
                              'CLIENT',
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
                              'VENDEUR',
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

  pw.Widget _buildPdfTableCell(String text, double fontSize, {bool isHeader = false, bool isAmount = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(format == 'A6' ? 3 : 5),
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
        name: 'Facture_${nFacture}_$date.pdf',
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
