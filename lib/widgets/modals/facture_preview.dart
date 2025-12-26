import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../services/auth_service.dart';
import '../facture/pdf_generator.dart';

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
        if (widget.format != 'A6')
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

        // Header section with company and document info
        Container(
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
                          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
                        ),

                        if (widget.format != 'A6') ...[
                          if (widget.societe?.activites != null)
                            Text(widget.societe!.activites!, style: TextStyle(fontSize: _fontSize - 1)),
                          if (widget.societe?.adr != null)
                            Text(widget.societe!.adr!, style: TextStyle(fontSize: _fontSize - 1)),
                          if (widget.societe?.rcs != null)
                            Text(
                              "RCS: ${widget.societe!.rcs!} ${widget.societe?.cif != null ? " | CIF: ${widget.societe!.cif!}" : ""}",
                              style: TextStyle(fontSize: _fontSize - 1),
                            ),
                          if (widget.societe?.nif != null)
                            Text(
                              "NIF: ${widget.societe!.nif!} ${widget.societe?.stat != null ? " | STAT: ${widget.societe!.stat!}" : ""}",
                              style: TextStyle(fontSize: _fontSize - 1),
                            ),
                          if (widget.societe?.port != null)
                            Text(
                              "Tél: ${widget.societe!.port!} ${widget.societe?.email != null ? " | Email: ${widget.societe!.email!}" : ""}",
                              style: TextStyle(fontSize: _fontSize - 1),
                            ),
                        ],
                        if (widget.societe?.port != null && widget.format == 'A6')
                          RichText(
                            text: TextSpan(
                              text: 'Tél: ${widget.societe!.port!}',
                              style: TextStyle(fontSize: _fontSize - 2, color: Colors.black),
                              children: [
                                TextSpan(
                                  text: ' | RCS: ${widget.societe?.rcs != null ? widget.societe!.rcs! : "-"}',
                                  style: TextStyle(fontSize: _fontSize - 2, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        if (widget.format == 'A6') _buildInfoRow('Doit:', widget.client),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('DATE:', widget.date),
                        _buildInfoRow('FACTURE N°:', widget.nFacture),
                        if (widget.format != 'A6') _buildInfoRow('Doit:', widget.client),
                        if (widget.format != 'A6') _buildInfoRow('Adresse:', widget.client),
                        _buildInfoRow('Mode de paiement:', widget.modePaiement),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                      'VENDEUR',
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
              style: TextStyle(fontSize: _fontSize - 2, fontWeight: FontWeight.normal),
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
  Future<pw.Document> _generateFacturePdf() async {
    final config = PdfConfig(
      selectedFormat: widget.format,
      documentType: DocumentType.facture,
      documentNumber: widget.nFacture,
      date: widget.date,
      client: widget.client,
      adrClient: widget.client,
      lignes: widget.lignesVente,
      remise: widget.remise,
      totalTTC: widget.totalTTC,
      societe: widget.societe,
      modePaiement: widget.modePaiement,
      showDepot: widget.format != 'A6',
      showSignatures: widget.format != 'A6' ? true : false,
    );

    final generator = PdfGenerator(config);
    return await generator.generate();
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
      final pdf = await _generateFacturePdf();
      final bytes = await pdf.save();

      // Obtenir la liste des imprimantes et trouver celle par défaut
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${widget.nFacture}_${widget.date.replaceAll('/', '-')}.pdf',
          format: widget.format == 'A4'
              ? PdfPageFormat.a4
              : (widget.format == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        // Fallback vers la boîte de dialogue si aucune imprimante par défaut
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${widget.nFacture}_${widget.date.replaceAll('/', '-')}.pdf',
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
            content: const Text('Facture envoyée à l\'imprimante par défaut'),
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
