import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';

/// Énumération des types de documents
enum DocumentType { facture, bonLivraison, bonCommande, devis }

/// Configuration pour la génération de PDF
class PdfConfig {
  final String selectedFormat;
  final DocumentType documentType;
  final String documentNumber;
  final String date;
  final String client;
  final String adrClient;
  final List<Map<String, dynamic>> lignes;
  final double remise;
  final double totalTTC;
  final SocData? societe;
  final String? modePaiement;
  final bool showDepot;
  final bool showSignatures;
  final String? additionalInfo;

  PdfConfig({
    this.selectedFormat = 'A6',
    required this.documentType,
    required this.documentNumber,
    required this.date,
    required this.client,
    required this.adrClient,
    required this.lignes,
    this.remise = 0,
    required this.totalTTC,
    this.societe,
    this.modePaiement,
    this.showDepot = true,
    this.showSignatures = true,
    this.additionalInfo,
    this.itemsPerPage,
  });

  final int? itemsPerPage; // Nombre d'articles par page (optionnel)

  // Getters pour les dimensions selon le format
  double get fontSize => selectedFormat == 'A6' ? 7.0 : (selectedFormat == 'A5' ? 9.0 : 10.0);
  double get headerFontSize => selectedFormat == 'A6' ? 8.0 : (selectedFormat == 'A5' ? 10.0 : 12.0);
  double get padding => selectedFormat == 'A6' ? 8.0 : (selectedFormat == 'A5' ? 10.0 : 12.0);

  PdfPageFormat get pageFormat {
    switch (selectedFormat) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A5':
        return PdfPageFormat.a5;
      case 'A6':
      default:
        return PdfPageFormat.a6;
    }
  }

  // Titre du document selon le type
  String get documentTitle {
    switch (documentType) {
      case DocumentType.facture:
        return 'FACTURE';
      case DocumentType.bonLivraison:
        return 'BON DE LIVRAISON';
      case DocumentType.bonCommande:
        return 'BON DE COMMANDE';
      case DocumentType.devis:
        return 'DEVIS';
    }
  }

  // Label du numéro de document
  String get documentNumberLabel {
    switch (documentType) {
      case DocumentType.facture:
        return 'FACTURE N°:';
      case DocumentType.bonLivraison:
        return 'BON DE LIVRAISON:';
      case DocumentType.bonCommande:
        return 'BON DE COMMANDE:';
      case DocumentType.devis:
        return 'DEVIS N°:';
    }
  }

  // Signature selon le type de document
  String get signatureLabel {
    switch (documentType) {
      case DocumentType.facture:
        return 'VENDEUR';
      case DocumentType.bonLivraison:
        return 'LIVREUR';
      case DocumentType.bonCommande:
        return 'FOURNISSEUR';
      case DocumentType.devis:
        return 'COMMERCIAL';
    }
  }
}

/// Classe principale pour générer des PDFs
class PdfGenerator {
  final PdfConfig config;

  PdfGenerator(this.config);

  /// Génère le document PDF avec support multi-pages
  Future<pw.Document> generate() async {
    final pdf = pw.Document();

    // Calculer combien d'articles par page
    final itemsPerPage = _calculateItemsPerPage();

    // Si tous les articles tiennent sur une page
    if (config.lignes.length <= itemsPerPage) {
      pdf.addPage(_buildSinglePage(config.lignes, isLastPage: true));
    } else {
      // Diviser en plusieurs pages
      int currentIndex = 0;
      int pageNumber = 1;

      while (currentIndex < config.lignes.length) {
        final endIndex = (currentIndex + itemsPerPage).clamp(0, config.lignes.length);
        final pageItems = config.lignes.sublist(currentIndex, endIndex);
        final isLastPage = endIndex >= config.lignes.length;

        pdf.addPage(
          _buildSinglePage(
            pageItems,
            isLastPage: isLastPage,
            pageNumber: pageNumber,
            totalPages: ((config.lignes.length / itemsPerPage).ceil()),
          ),
        );

        currentIndex = endIndex;
        pageNumber++;
      }
    }

    return pdf;
  }

  /// Calcule le nombre d'articles par page selon le format
  int _calculateItemsPerPage() {
    // Si un nombre personnalisé est défini, l'utiliser
    if (config.itemsPerPage != null) {
      return config.itemsPerPage!;
    }

    // Sinon, utiliser les valeurs par défaut
    switch (config.selectedFormat) {
      case 'A4':
        return 26; // ~26 articles par page A4
      case 'A5':
        return 24; // ~24 articles par page A5
      case 'A6':
      default:
        return 13; // ~13 articles par page A6
    }
  }

  /// Construit une page unique
  pw.Page _buildSinglePage(
    List<Map<String, dynamic>> pageItems, {
    required bool isLastPage,
    int? pageNumber,
    int? totalPages,
  }) {
    return pw.Page(
      pageFormat: config.pageFormat,
      margin: const pw.EdgeInsets.all(3),
      build: (context) {
        return pw.Container(
          padding: pw.EdgeInsets.all(config.padding),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Titre du document (sauf pour A6)
              if (config.selectedFormat != 'A6') _buildTitle(),

              // En-tête avec infos société et document (première page uniquement)
              if (pageNumber == null || pageNumber == 1) _buildHeader(),

              // Numéro de page si multi-pages
              if (pageNumber != null && totalPages != null && totalPages > 1)
                _buildPageNumber(pageNumber, totalPages),

              // Tableau des articles de cette page
              _buildArticlesTableForPage(pageItems),

              // Section totaux (dernière page uniquement)
              if (isLastPage) ...[
                _buildTotalsSection(),

                // Section signatures
                if (config.showSignatures && config.selectedFormat != 'A6') _buildSignaturesSection(),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Construit l'indicateur de numéro de page
  pw.Widget _buildPageNumber(int pageNumber, int totalPages) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: config.padding / 4),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page $pageNumber / $totalPages',
        style: pw.TextStyle(fontSize: config.fontSize - 1, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  /// Construit le titre du document
  pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: config.padding / 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.black, width: 2),
            bottom: pw.BorderSide(color: PdfColors.black, width: 2),
          ),
        ),
        child: pw.Text(
          config.documentTitle,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: config.headerFontSize + 2),
        ),
      ),
    );
  }

  /// Construit l'en-tête du document
  pw.Widget _buildHeader() {
    return pw.Container(
      padding: pw.EdgeInsets.all(config.padding / 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Informations société
          pw.Expanded(flex: 3, child: _buildCompanyInfo()),
          // Informations document
          pw.Expanded(flex: 2, child: _buildDocumentInfo()),
        ],
      ),
    );
  }

  /// Construit les informations de la société
  pw.Widget _buildCompanyInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          config.societe?.rsoc ?? 'SOCIÉTÉ',
          style: pw.TextStyle(fontSize: config.fontSize, fontWeight: pw.FontWeight.bold),
        ),
        if (config.selectedFormat != 'A6') ...[
          if (config.societe?.activites != null)
            pw.Text(config.societe!.activites!, style: pw.TextStyle(fontSize: config.fontSize - 1)),
          if (config.societe?.adr != null)
            pw.Text(config.societe!.adr!, style: pw.TextStyle(fontSize: config.fontSize - 1)),
          if (config.societe?.rcs != null)
            pw.Text(
              "RCS: ${config.societe!.rcs!}${config.societe!.cif != null ? " | CIF: ${config.societe!.cif!}" : ""}",
              style: pw.TextStyle(fontSize: config.fontSize - 1),
            ),
          if (config.societe?.nif != null)
            pw.Text(
              "NIF: ${config.societe!.nif!}${config.societe!.stat != null ? " | STAT: ${config.societe!.stat!}" : ""}",
              style: pw.TextStyle(fontSize: config.fontSize - 1),
            ),
          if (config.societe?.port != null)
            pw.Text(
              "Tél: ${config.societe!.port!}${config.societe!.email != null ? " | Email: ${config.societe!.email!}" : ""}",
              style: pw.TextStyle(fontSize: config.fontSize - 1),
            ),
        ],
        if (config.selectedFormat == 'A6' && config.societe?.port != null)
          pw.RichText(
            text: pw.TextSpan(
              text: 'Tél: ${config.societe!.port!}',
              style: pw.TextStyle(fontSize: config.fontSize - 1, color: PdfColors.black),
              children: [
                if (config.societe!.rcs != null)
                  pw.TextSpan(
                    text: ' | RCS: ${config.societe!.rcs!}',
                    style: pw.TextStyle(fontSize: config.fontSize - 1, color: PdfColors.black),
                  ),
              ],
            ),
          ),
        if (config.selectedFormat == 'A6') _buildInfoRow('Doit:', config.client),
      ],
    );
  }

  /// Construit les informations du document
  pw.Widget _buildDocumentInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow(config.documentNumberLabel, config.documentNumber),
        _buildInfoRow('DATE:', config.date),
        if (config.selectedFormat != 'A6') ...[
          _buildInfoRow('Doit:', config.client),
          _buildInfoRow('Adresse:', config.adrClient),
        ],
        if (config.modePaiement != null) _buildInfoRow('Mode de paiement:', config.modePaiement!),
      ],
    );
  }

  /// Construit une ligne d'information
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: config.fontSize - 1, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: config.fontSize - 1, fontWeight: pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le tableau des articles pour une page spécifique
  pw.Widget _buildArticlesTableForPage(List<Map<String, dynamic>> pageItems) {
    return pw.Container(
      padding: pw.EdgeInsets.all(config.padding / 2),
      child: pw.Column(children: [_buildTableHeader(), _buildTableDataForPage(pageItems)]),
    );
  }

  /// Construit les données du tableau pour une page spécifique
  pw.Widget _buildTableDataForPage(List<Map<String, dynamic>> pageItems) {
    final columnWidths = config.showDepot && config.selectedFormat != 'A6'
        ? {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.5),
          }
        : {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          };

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
        top: pw.BorderSide(color: PdfColors.black, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.75),
      ),
      columnWidths: columnWidths,
      children: pageItems.map((ligne) => _buildTableRow(ligne)).toList(),
    );
  }

  /// Construit l'en-tête du tableau
  pw.Widget _buildTableHeader() {
    final headers = config.showDepot && config.selectedFormat != 'A6'
        ? ['Désignation', 'Dépôt', 'Q', 'U', 'PU HT', 'Montant']
        : ['Désignation', 'Q', 'U', 'PU HT', 'Montant'];

    final columnWidths = config.showDepot && config.selectedFormat != 'A6'
        ? {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.5),
          }
        : {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          };

    return pw.Container(
      color: PdfColors.grey300,
      child: pw.Table(
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5)),
        columnWidths: columnWidths,
        children: [
          pw.TableRow(children: headers.map((header) => _buildTableCell(header, isHeader: true)).toList()),
        ],
      ),
    );
  }

  /// Construit une ligne du tableau
  pw.TableRow _buildTableRow(Map<String, dynamic> ligne) {
    final cells = <pw.Widget>[_buildTableCell(ligne['designation'] ?? '', isArticle: true)];

    if (config.showDepot && config.selectedFormat != 'A6') {
      cells.add(_buildTableCell(ligne['depot'] ?? 'MAG'));
    }

    cells.addAll([
      _buildTableCell(AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0)),
      _buildTableCell(ligne['unites'] ?? ''),
      _buildTableCell(AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0), isAmount: true),
      _buildTableCell(AppFunctions.formatNumber(ligne['montant']?.toDouble() ?? 0), isAmount: true),
    ]);

    return pw.TableRow(children: cells);
  }

  /// Construit une cellule de tableau
  pw.Widget _buildTableCell(
    String text, {
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
      padding: pw.EdgeInsets.all(
        config.selectedFormat == 'A6' ? 8.0 : (config.selectedFormat == 'A5' ? 3.0 : 5.0),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: config.fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Construit la section des totaux
  pw.Widget _buildTotalsSection() {
    return pw.Container(
      padding: pw.EdgeInsets.all(config.padding / 2),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (config.remise > 0) _buildTotalRow('REMISE:', AppFunctions.formatNumber(config.remise)),
                  _buildTotalRow('TOTAL TTC:', AppFunctions.formatNumber(config.totalTTC), isBold: true),
                ],
              ),
            ],
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(config.padding / 2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Arrêté à la somme de ${AppFunctions.numberToWords(config.totalTTC.round())} Ariary',
              style: pw.TextStyle(fontSize: config.fontSize - 1, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de total
  pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: config.fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: config.fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des signatures
  pw.Widget _buildSignaturesSection() {
    return pw.Container(
      padding: pw.EdgeInsets.all(config.padding),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(fontSize: config.fontSize, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  config.signatureLabel,
                  style: pw.TextStyle(fontSize: config.fontSize, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Imprime le document
  static Future<void> printDocument(
    BuildContext context,
    PdfConfig config, {
    bool useDefaultPrinter = true,
  }) async {
    if (config.lignes.isEmpty) {
      _showSnackBar(context, 'Aucun article à imprimer');
      return;
    }

    try {
      final generator = PdfGenerator(config);
      final pdf = await generator.generate();
      final bytes = await pdf.save();

      if (useDefaultPrinter) {
        final printers = await Printing.listPrinters();
        final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

        if (defaultPrinter != null) {
          await Printing.directPrintPdf(
            printer: defaultPrinter,
            onLayout: (PdfPageFormat format) async => bytes,
            name: '${config.documentTitle}_${config.documentNumber}_${config.date.replaceAll('/', '-')}.pdf',
            format: config.pageFormat,
          );

          if (context.mounted) {
            _showSnackBar(context, '${config.documentTitle} envoyée à l\'imprimante par défaut');
          }
          return;
        }
      }

      // Fallback vers la boîte de dialogue
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: '${config.documentTitle}_${config.documentNumber}_${config.date.replaceAll('/', '-')}.pdf',
        format: config.pageFormat,
      );

      if (context.mounted) _showSnackBar(context, '${config.documentTitle} envoyée à l\'impression');
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Erreur d\'impression: $e', isError: true);
    }
  }

  /// Affiche un SnackBar
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8,
          right: 20,
          left: MediaQuery.of(context).size.width * 0.75,
        ),
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
