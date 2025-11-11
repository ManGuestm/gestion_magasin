import 'package:flutter/material.dart';

import '../../database/database.dart';

class BonReceptionPreview extends StatelessWidget {
  final String numAchats;
  final String? nFact;
  final DateTime date;
  final String fournisseur;
  final String? modePaiement;
  final List<Map<String, dynamic>> lignesAchat;
  final double totalHT;
  final double tva;
  final double totalTTC;
  final String format;
  final SocData? societe;

  const BonReceptionPreview({
    super.key,
    required this.numAchats,
    this.nFact,
    required this.date,
    required this.fournisseur,
    this.modePaiement,
    required this.lignesAchat,
    required this.totalHT,
    required this.tva,
    required this.totalTTC,
    required this.format,
    this.societe,
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
        return 8;
      case 'A5':
        return 10;
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
                  'Aperçu BR N° $numAchats - Format $format',
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
                      child: _buildReceiptContent(),
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

  Widget _buildReceiptContent() {
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
                    societe?.rsoc ?? 'RALAIZANDRY Jean Frédéric',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: _headerFontSize),
                  ),
                  Text(
                    societe?.activites ?? 'Marchandises Générales - Gros/détails',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                  Text(
                    societe?.adr ?? 'Lot IVO 69 D Antohomadinka Sud',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ],
              ),
            ),
            // Right side - Receipt info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Date: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: TextStyle(fontSize: _fontSize),
                ),
                Row(
                  children: [
                    Text('BON DE RECEPTION N°',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                    SizedBox(width: format == 'A6' ? 4 : 8),
                    Text(numAchats, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                  ],
                ),
                if (nFact?.isNotEmpty == true) Text('Frns: $nFact', style: TextStyle(fontSize: _fontSize)),
                Text(fournisseur.toUpperCase(), style: TextStyle(fontSize: _fontSize)),
              ],
            ),
          ],
        ),

        SizedBox(height: format == 'A6' ? 10 : 20),

        // Table
        Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: format == 'A6'
              ? const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(2),
                  5: FlexColumnWidth(2),
                }
              : const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(2),
                },
          children: [
            // Header row
            TableRow(
              children: [
                _buildTableCell('DESIGNATION', isHeader: true),
                _buildTableCell('Dépôts', isHeader: true),
                _buildTableCell('Q', isHeader: true),
                _buildTableCell('Unités', isHeader: true),
                _buildTableCell('PU HT', isHeader: true),
                _buildTableCell('Montant', isHeader: true),
              ],
            ),
            // Data rows
            ...lignesAchat.map((ligne) => TableRow(
                  children: [
                    _buildTableCell(ligne['designation'] ?? ''),
                    _buildTableCell(ligne['depot'] ?? ''),
                    _buildTableCell(_formatNumber(ligne['quantite']?.toDouble() ?? 0)),
                    _buildTableCell(ligne['unites'] ?? ''),
                    _buildTableCell(_formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0)),
                    _buildTableCell(_formatNumber(ligne['montant']?.toDouble() ?? 0)),
                  ],
                )),
          ],
        ),

        SizedBox(height: format == 'A6' ? 5 : 10),

        // Totals
        Row(
          children: [
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text('TOTAL HT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                    SizedBox(width: format == 'A6' ? 10 : 20),
                    Text(_formatNumber(totalHT),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                  ],
                ),
                Row(
                  children: [
                    Text('TVA', style: TextStyle(fontSize: _fontSize)),
                    SizedBox(width: format == 'A6' ? 10 : 20),
                    Text(_formatNumber(tva), style: TextStyle(fontSize: _fontSize)),
                  ],
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black)),
                  ),
                  child: Row(
                    children: [
                      Text('TOTAL TTC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                      SizedBox(width: format == 'A6' ? 10 : 20),
                      Text(_formatNumber(totalTTC),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: format == 'A6' ? 10 : 20),

        // Amount in words
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(format == 'A6' ? 4 : 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Text(
            'Arrêté à la somme de ${_numberToWords(totalTTC.round())} Ariary',
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: format == 'A6' ? 10 : 20),

        // Footer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode de paiement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize)),
                Text(modePaiement ?? 'A crédit', style: TextStyle(fontSize: _fontSize)),
                SizedBox(height: format == 'A6' ? 5 : 10),
                Text('Fournisseur,', style: TextStyle(fontSize: _fontSize)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Signature,', style: TextStyle(fontSize: _fontSize)),
              ],
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
          fontSize: format == 'A6' ? 7 : (format == 'A5' ? 8 : 10),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
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

  void _imprimer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impression du BR N° $numAchats en format $format')),
    );
  }
}
