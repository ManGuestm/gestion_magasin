import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/app_functions.dart';

/// Service dédié à la génération de documents PDF
/// Encapsule la logique de création des factures et bons de livraison
class DocumentGenerationService {
  /// Génère un widget pour une ligne de totaux PDF
  pw.Widget buildPdfTotalRow(String label, String value, double fontSize, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Calcule la hauteur totale d'une page PDF
  double getPageHeight(String format) {
    final sizes = {
      'A4': PdfPageFormat.a4.height,
      'A5': PdfPageFormat.a5.height,
      'A6': PdfPageFormat.a6.height,
      'TICKET': 150.0,
    };
    return sizes[format] ?? PdfPageFormat.a4.height;
  }

  /// Calcule la largeur totale d'une page PDF
  double getPageWidth(String format) {
    final sizes = {
      'A4': PdfPageFormat.a4.width,
      'A5': PdfPageFormat.a5.width,
      'A6': PdfPageFormat.a6.width,
      'TICKET': 80.0,
    };
    return sizes[format] ?? PdfPageFormat.a4.width;
  }

  /// Formate un nombre pour l'affichage en PDF
  String formatNumberForPdf(double value) {
    return AppFunctions.formatNumber(value);
  }

  /// Formate une date pour l'affichage
  String formatDateForPdf(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Construit une ligne de détail pour la facture
  pw.Widget buildInvoiceDetailRow(
    String designation,
    String unite,
    double quantite,
    double prixUnitaire,
    double montant,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 3, child: pw.Text(designation, style: const pw.TextStyle(fontSize: 9))),
        pw.Expanded(flex: 1, child: pw.Text(unite, style: const pw.TextStyle(fontSize: 9))),
        pw.Expanded(
          flex: 1,
          child: pw.Text(quantite.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text(formatNumberForPdf(prixUnitaire), style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text(formatNumberForPdf(montant), style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  /// Construit l'en-tête du tableau d'articles
  pw.Widget buildTableHeader() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text('Désignation', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text('Unité', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text('Quantité', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text('P.U.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text('Montant', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  /// Vérifie si un format de papier est valide
  bool isValidPaperFormat(String format) {
    const validFormats = ['A4', 'A5', 'A6', 'TICKET'];
    return validFormats.contains(format);
  }

  /// Obtient la liste des formats de papier supportés
  List<String> getSupportedFormats() {
    return ['A4', 'A5', 'A6', 'TICKET'];
  }
}
