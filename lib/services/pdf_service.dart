import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/database.dart';

class PDFService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<void> _loadFonts() async {
    if (_regularFont == null || _boldFont == null) {
      try {
        _regularFont = await PdfGoogleFonts.notoSansRegular();
        _boldFont = await PdfGoogleFonts.notoSansBold();
      } catch (e) {
        // Fallback vers les polices par défaut
        _regularFont = pw.Font.helvetica();
        _boldFont = pw.Font.helveticaBold();
      }
    }
  }

  /// Génère une facture PDF
  static Future<Uint8List> generateInvoicePDF({
    required Vente vente,
    required List<Detvente> details,
    required CltData client,
    required SocData societe,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildInvoiceHeader(societe, client, vente),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(details),
            pw.SizedBox(height: 20),
            _buildInvoiceTotal(vente),
            pw.Spacer(),
            _buildInvoiceFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Génère un rapport de stock PDF
  static Future<Uint8List> generateStockReportPDF({
    required List<Article> articles,
    required SocData societe,
    String? depot,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildReportHeader(societe, 'Rapport de Stock', depot: depot),
            pw.SizedBox(height: 20),
            _buildStockTable(articles),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Génère un rapport de ventes PDF
  static Future<Uint8List> generateSalesReportPDF({
    required List<Vente> ventes,
    required SocData societe,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildReportHeader(
              societe,
              'Rapport de Ventes',
              period: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            ),
            pw.SizedBox(height: 20),
            _buildSalesTable(ventes),
            pw.SizedBox(height: 20),
            _buildSalesSummary(ventes),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoiceHeader(SocData societe, CltData client, Vente vente) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(societe.rsoc ?? 'Société', style: pw.TextStyle(font: _boldFont, fontSize: 18)),
              pw.Text(societe.adr ?? '', style: pw.TextStyle(font: _regularFont, fontSize: 10)),
              pw.Text('Tél: ${societe.tel ?? ''}', style: pw.TextStyle(font: _regularFont, fontSize: 10)),
              pw.Text('NIF: ${societe.nif ?? ''}', style: pw.TextStyle(font: _regularFont, fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('FACTURE', style: pw.TextStyle(font: _boldFont, fontSize: 24)),
              pw.Text(
                'N° ${vente.nfact ?? vente.numventes ?? ''}',
                style: pw.TextStyle(font: _boldFont, fontSize: 14),
              ),
              pw.Text(
                'Date: ${_formatDate(vente.daty)}',
                style: pw.TextStyle(font: _regularFont, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(List<Detvente> details) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Désignation', isHeader: true),
            _buildTableCell('Qté', isHeader: true),
            _buildTableCell('Unité', isHeader: true),
            _buildTableCell('P.U.', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        ...details.map(
          (detail) => pw.TableRow(
            children: [
              _buildTableCell(detail.designation ?? ''),
              _buildTableCell('${detail.q ?? 0}'),
              _buildTableCell(detail.unites ?? ''),
              _buildTableCell('${detail.pu ?? 0}'),
              _buildTableCell('${(detail.q ?? 0) * (detail.pu ?? 0)}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTotal(Vente vente) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total TTC:', style: pw.TextStyle(font: _boldFont, fontSize: 14)),
                pw.Text('${vente.totalttc ?? 0} Ar', style: pw.TextStyle(font: _boldFont, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildInvoiceFooter() {
    return pw.Center(
      child: pw.Text(
        'Merci pour votre confiance',
        style: pw.TextStyle(font: _regularFont, fontSize: 12, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  static pw.Widget _buildReportHeader(SocData societe, String title, {String? depot, String? period}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(societe.rsoc ?? 'Société', style: pw.TextStyle(font: _boldFont, fontSize: 16)),
        pw.SizedBox(height: 10),
        pw.Text(title, style: pw.TextStyle(font: _boldFont, fontSize: 20)),
        if (depot != null) pw.Text('Dépôt: $depot', style: pw.TextStyle(font: _regularFont, fontSize: 12)),
        if (period != null)
          pw.Text('Période: $period', style: pw.TextStyle(font: _regularFont, fontSize: 12)),
        pw.Text(
          'Généré le: ${_formatDate(DateTime.now())}',
          style: pw.TextStyle(font: _regularFont, fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildStockTable(List<Article> articles) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Désignation', isHeader: true),
            _buildTableCell('Stock U1', isHeader: true),
            _buildTableCell('Stock U2', isHeader: true),
            _buildTableCell('Stock U3', isHeader: true),
            _buildTableCell('CMUP', isHeader: true),
          ],
        ),
        ...articles.map(
          (article) => pw.TableRow(
            children: [
              _buildTableCell(article.designation),
              _buildTableCell('${article.stocksu1 ?? 0}'),
              _buildTableCell('${article.stocksu2 ?? 0}'),
              _buildTableCell('${article.stocksu3 ?? 0}'),
              _buildTableCell('${article.cmup ?? 0}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSalesTable(List<Vente> ventes) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('N° Facture', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Client', isHeader: true),
            _buildTableCell('Montant', isHeader: true),
          ],
        ),
        ...ventes.map(
          (vente) => pw.TableRow(
            children: [
              _buildTableCell(vente.nfact ?? vente.numventes ?? ''),
              _buildTableCell(_formatDate(vente.daty)),
              _buildTableCell(vente.clt ?? ''),
              _buildTableCell('${vente.totalttc ?? 0}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSalesSummary(List<Vente> ventes) {
    final total = ventes.fold<double>(0, (sum, vente) => sum + (vente.totalttc ?? 0));
    final count = ventes.length;
    final average = count > 0 ? total / count : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.grey100),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Résumé:', style: pw.TextStyle(font: _boldFont, fontSize: 14)),
          pw.Text('Nombre de ventes: $count'),
          pw.Text('Total des ventes: ${total.toStringAsFixed(2)} Ar'),
          pw.Text('Moyenne par vente: ${average.toStringAsFixed(2)} Ar'),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: isHeader ? _boldFont : _regularFont, fontSize: isHeader ? 12 : 10),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Sauvegarde le PDF dans le dossier Documents
  static Future<String> savePDF(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Imprime le PDF
  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}
