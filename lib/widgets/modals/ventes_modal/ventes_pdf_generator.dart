import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../constants/app_functions.dart';
import '../../../database/database.dart';

class VentesPdfGenerator {
  Future<pw.Document> generateFacturePdf({
    required String numVente,
    required String nFacture,
    required String date,
    required String client,
    required List<Map<String, dynamic>> lignesVente,
    required double totalTTC,
    required double remise,
    required String selectedFormat,
    required SocData? societe,
    required String modePaiement,
  }) async {
    final pdf = pw.Document();
    final pdfFontSize = _getFontSizeForFormat(selectedFormat);
    final pdfPadding = _getPaddingForFormat(selectedFormat);
    final pageFormat = _getPageFormat(selectedFormat);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(3),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildHeader(pdfFontSize, pdfPadding),
                // Informations société et client
                _buildInfoSection(societe, numVente, date, client, modePaiement, pdfFontSize, pdfPadding),
                // Table des articles
                _buildArticlesTable(lignesVente, pdfFontSize, pdfPadding),
                // Totaux
                _buildTotalsSection(totalTTC, remise, pdfFontSize, pdfPadding),
                // Signatures
                _buildSignaturesSection(pdfFontSize, pdfPadding),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.Document> generateBLPdf({
    required String numVente,
    required String nFacture,
    required String date,
    required String client,
    required List<Map<String, dynamic>> lignesVente,
    required String selectedFormat,
    required SocData? societe,
    required bool tousDepots,
  }) async {
    final pdf = pw.Document();
    final pdfFontSize = _getFontSizeForFormat(selectedFormat);
    final pdfPadding = _getPaddingForFormat(selectedFormat);
    final pageFormat = _getPageFormat(selectedFormat);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(3),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildBLHeader(pdfFontSize, pdfPadding),
                // Informations
                _buildBLInfoSection(societe, nFacture, date, client, pdfFontSize, pdfPadding),
                // Table des articles
                _buildBLArticlesTable(lignesVente, tousDepots, pdfFontSize, pdfPadding),
                // Signatures
                _buildBLSignaturesSection(pdfFontSize, pdfPadding),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  // Méthodes auxiliaires privées
  double _getFontSizeForFormat(String format) {
    switch (format) {
      case 'A6':
        return 9.0;
      case 'A5':
        return 10.0;
      default: // A4
        return 12.0;
    }
  }

  double _getPaddingForFormat(String format) {
    switch (format) {
      case 'A6':
        return 8.0;
      case 'A5':
        return 10.0;
      default: // A4
        return 12.0;
    }
  }

  PdfPageFormat _getPageFormat(String format) {
    switch (format) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A5':
        return PdfPageFormat.a5;
      default: // A6
        return PdfPageFormat.a6;
    }
  }

  pw.Widget _buildHeader(double fontSize, double padding) {
    return pw.Center(
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: padding / 2),
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
            fontSize: fontSize + 2,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildInfoSection(
    SocData? societe,
    String numVente,
    String date,
    String client,
    String modePaiement,
    double fontSize,
    double padding,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(padding / 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Informations société
          pw.Expanded(
            flex: 3,
            child: _buildSocieteInfo(societe, fontSize),
          ),
          // Informations facture
          pw.Expanded(
            flex: 2,
            child: _buildFactureInfo(numVente, date, client, modePaiement, fontSize),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSocieteInfo(SocData? societe, double fontSize) {
    final children = <pw.Widget>[
      pw.Text(
        'SOCIÉTÉ:',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: fontSize - 1,
        ),
      ),
      pw.Text(
        societe?.rsoc ?? 'SOCIÉTÉ',
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ];

    if (societe?.adr != null) {
      children.add(pw.Text(societe!.adr!, style: pw.TextStyle(fontSize: fontSize - 1)));
    }
    if (societe?.activites != null) {
      children.add(pw.Text(societe!.activites!, style: pw.TextStyle(fontSize: fontSize - 1)));
    }
    if (societe?.port != null) {
      children.add(pw.Text('Tél: ${societe!.port!}', style: pw.TextStyle(fontSize: fontSize - 2)));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildFactureInfo(
    String numVente,
    String date,
    String client,
    String modePaiement,
    double fontSize,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'N° FACTURE: $numVente',
          style: pw.TextStyle(
            fontSize: fontSize - 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'DATE: $date',
          style: pw.TextStyle(
            fontSize: fontSize - 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'CLIENT: $client',
          style: pw.TextStyle(
            fontSize: fontSize - 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'MODE DE PAIEMENT: $modePaiement',
          style: pw.TextStyle(
            fontSize: fontSize - 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildArticlesTable(
    List<Map<String, dynamic>> lignesVente,
    double fontSize,
    double padding,
  ) {
    final tableRows = <pw.TableRow>[
      // En-tête du tableau
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildTableHeaderCell('DÉSIGNATION', fontSize),
          _buildTableHeaderCell('QTÉ', fontSize),
          _buildTableHeaderCell('PU HT', fontSize),
          _buildTableHeaderCell('MONTANT', fontSize),
        ],
      ),
      // Lignes d'articles
      ...lignesVente.map((ligne) => pw.TableRow(
            children: [
              _buildTableCell(ligne['designation'] ?? '', fontSize, pw.Alignment.centerLeft),
              _buildTableCell(
                AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0),
                fontSize,
                pw.Alignment.center,
              ),
              _buildTableCell(
                AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                fontSize,
                pw.Alignment.centerRight,
              ),
              _buildTableCell(
                AppFunctions.formatNumber(ligne['montant']?.toDouble() ?? 0),
                fontSize,
                pw.Alignment.centerRight,
              ),
            ],
          )),
    ];

    return pw.Container(
      margin: pw.EdgeInsets.only(top: padding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
        children: tableRows,
      ),
    );
  }

  pw.Container _buildTableHeaderCell(String text, double fontSize) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Container _buildTableCell(String text, double fontSize, pw.Alignment alignment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize - 1),
      ),
    );
  }

  pw.Widget _buildTotalsSection(
    double totalTTC,
    double remise,
    double fontSize,
    double padding,
  ) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: padding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(padding / 2),
      child: pw.Row(
        children: [
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL TTC: ${AppFunctions.formatNumber(totalTTC)}',
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignaturesSection(double fontSize, double padding) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: padding * 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(padding),
      child: pw.Row(
        children: [
          // Signature client
          pw.Expanded(
            child: _buildSignatureColumn('CLIENT', fontSize, padding),
          ),
          // Séparateur
          pw.Container(
            width: 1,
            height: 60,
            color: PdfColors.black,
          ),
          // Signature vendeur
          pw.Expanded(
            child: _buildSignatureColumn('VENDEUR', fontSize, padding),
          ),
        ],
      ),
    );
  }

  pw.Column _buildSignatureColumn(String title, double fontSize, double padding) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: padding * 2),
        pw.Container(
          height: 1,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20),
        ),
        pw.SizedBox(height: padding / 2),
        pw.Text(
          'Nom et signature',
          style: pw.TextStyle(fontSize: fontSize - 2),
        ),
      ],
    );
  }

  // Méthodes pour le BL
  pw.Widget _buildBLHeader(double fontSize, double padding) {
    return pw.Center(
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: padding / 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.black, width: 2),
            bottom: pw.BorderSide(color: PdfColors.black, width: 2),
          ),
        ),
        child: pw.Text(
          'BON DE LIVRAISON',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: fontSize + 2,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildBLInfoSection(
    SocData? societe,
    String nFacture,
    String date,
    String client,
    double fontSize,
    double padding,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(padding / 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: _buildSocieteInfo(societe, fontSize),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'N° BL: $nFacture',
                  style: pw.TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'DATE: $date',
                  style: pw.TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'CLIENT: $client',
                  style: pw.TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBLArticlesTable(
    List<Map<String, dynamic>> lignesVente,
    bool tousDepots,
    double fontSize,
    double padding,
  ) {
    final headers = <pw.Widget>[
      _buildTableHeaderCell('DÉSIGNATION', fontSize),
      _buildTableHeaderCell('UNITÉ', fontSize),
      _buildTableHeaderCell('QUANTITÉ', fontSize),
    ];

    if (tousDepots) {
      headers.add(_buildTableHeaderCell('DÉPÔT', fontSize));
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: headers,
      ),
      ...lignesVente.map((ligne) {
        final cells = <pw.Widget>[
          _buildTableCell(ligne['designation'] ?? '', fontSize, pw.Alignment.centerLeft),
          _buildTableCell(ligne['unites'] ?? '', fontSize, pw.Alignment.center),
          _buildTableCell(
            AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0),
            fontSize,
            pw.Alignment.center,
          ),
        ];

        if (tousDepots) {
          cells.add(_buildTableCell(ligne['depot'] ?? '', fontSize, pw.Alignment.center));
        }

        return pw.TableRow(children: cells);
      }),
    ];

    return pw.Container(
      margin: pw.EdgeInsets.only(top: padding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
        children: rows,
      ),
    );
  }

  pw.Widget _buildBLSignaturesSection(double fontSize, double padding) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: padding * 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(padding),
      child: pw.Row(
        children: [
          // Signature client
          pw.Expanded(
            child: _buildSignatureColumn('CLIENT', fontSize, padding),
          ),
          // Séparateur
          pw.Container(
            width: 1,
            height: 60,
            color: PdfColors.black,
          ),
          // Signature livreur
          pw.Expanded(
            child: _buildSignatureColumn('LIVREUR', fontSize, padding),
          ),
        ],
      ),
    );
  }
}
