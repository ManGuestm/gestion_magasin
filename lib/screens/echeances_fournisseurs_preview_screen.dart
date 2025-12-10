import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_functions.dart';
import '../database/database.dart';

class EchancesFournisseursPreviewScreen extends StatefulWidget {
  final List<Achat> achats;
  final String? selectedFournisseur;
  final String? selectedStatut;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const EchancesFournisseursPreviewScreen({
    super.key,
    required this.achats,
    this.selectedFournisseur,
    this.selectedStatut,
    this.dateDebut,
    this.dateFin,
  });

  @override
  State<EchancesFournisseursPreviewScreen> createState() => _EchancesFournisseursPreviewScreenState();
}

class _EchancesFournisseursPreviewScreenState extends State<EchancesFournisseursPreviewScreen> {
  final int _itemsPerPage = 25;
  int _currentPage = 0;
  SocData? _societe;

  @override
  void initState() {
    super.initState();
    _loadSociete();
  }

  Future<void> _loadSociete() async {
    try {
      final db = AppDatabase();
      final societes = await db.getAllSoc();
      if (societes.isNotEmpty) {
        setState(() {
          _societe = societes.first;
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  List<Achat> get _paginatedAchats {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.achats.length);
    return widget.achats.sublist(startIndex, endIndex);
  }

  int get _totalPages => (widget.achats.length / _itemsPerPage).ceil();

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu - Échéances Fournisseurs'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _printDirect, icon: const Icon(Icons.print), tooltip: 'Imprimer'),
          IconButton(onPressed: _showPrintPreview, icon: const Icon(Icons.preview), tooltip: 'Aperçu PDF'),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPreviewContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _societe?.rsoc ?? 'RALAIZANDRY Jean Frédéric',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      _societe?.activites ?? 'Marchandises Générales - Gros/détails',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    Text(
                      _societe?.adr ?? 'Lot IVO 69 D Antohomandrika Sud',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tél.: ${_societe?.tel ?? ''}', style: const TextStyle(fontSize: 12)),
                  Text('Portable: ${_societe?.port ?? ''}', style: const TextStyle(fontSize: 12)),
                  Text('Fax: ${_societe?.fax ?? ''}', style: const TextStyle(fontSize: 12)),
                  Text('e-mail: ${_societe?.email ?? ''}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('RCS: ${_societe?.rcs ?? ''}', style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text('NIF: ${_societe?.nif ?? ''}', style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text('STAT: ${_societe?.stat ?? ''}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
            child: const Text(
              'LISTE DES FACTURES À PAYER',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedAchats.length,
              itemBuilder: (context, index) {
                return _buildTableRow(_paginatedAchats[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Row(
        children: [
          _buildHeaderCell('FOURNISSEURS', flex: 3),
          _buildHeaderCell('N°ACHATS', flex: 2),
          _buildHeaderCell('N°BL/F', flex: 2),
          _buildHeaderCell('MONTANT', flex: 2),
          _buildHeaderCell('PAYER', flex: 2),
          _buildHeaderCell('RESTE À PAYER', flex: 2),
          _buildHeaderCell('DATE FACTURE', flex: 2),
          _buildHeaderCell('ÉCHÉANCE', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.black, width: 1)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableRow(Achat achat, int index) {
    // final isOverdue = achat.echeance != null && achat.echeance!.isBefore(DateTime.now());
    final resteAPayer = (achat.totalttc ?? 0) - (achat.regl ?? 0);

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          _buildCell(achat.frns ?? '', flex: 3),
          _buildCell(achat.numachats ?? '', flex: 2),
          _buildCell(achat.nfact ?? '', flex: 2),
          _buildCell(
            AppFunctions.formatNumber(achat.totalttc ?? 0),
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _buildCell(AppFunctions.formatNumber(achat.regl ?? 0), flex: 2, alignment: Alignment.centerRight),
          _buildCell(AppFunctions.formatNumber(resteAPayer), flex: 2, alignment: Alignment.centerRight),
          _buildCell(_formatDate(achat.daty), flex: 2),
          _buildCell(_formatDate(achat.echeance), flex: 2),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(2),
        alignment: alignment,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.black, width: 0.5)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 9, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GESTION COMMERCIALE DES PME',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
                style: const TextStyle(fontSize: 12),
              ),
              Text('${_currentPage + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_totalPages > 1) ...[
                IconButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${_currentPage + 1} / $_totalPages'),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
              ],
              ElevatedButton.icon(
                onPressed: _printDirect,
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Imprimer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Fermer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'current':
        return 'À jour';
      case 'overdue':
        return 'En retard';
      default:
        return 'Tous';
    }
  }

  Future<void> _printDirect() async {
    if (widget.achats.isEmpty) {
      _showMessage('Aucune donnée à imprimer', Colors.orange[600]!);
      return;
    }

    try {
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.firstWhere(
        (printer) => printer.isDefault,
        orElse: () => printers.isNotEmpty ? printers.first : throw Exception('Aucune imprimante'),
      );

      await Printing.directPrintPdf(
        printer: defaultPrinter,
        onLayout: _generatePdf,
        usePrinterSettings: true,
      );
      _showMessage('Impression lancée vers ${defaultPrinter.name}', Colors.green[600]!);
    } catch (e) {
      _showMessage('Erreur lors de l\'impression: $e', Colors.red[600]!);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showPrintPreview() async {
    await Printing.layoutPdf(onLayout: _generatePdf);
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    const itemsPerPage = 25;
    final totalPages = (widget.achats.length / itemsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, widget.achats.length);
      final pageAchats = widget.achats.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(),
                pw.SizedBox(height: 20),
                _buildPdfTable(pageAchats),
                pw.Spacer(),
                _buildPdfFooter(pageIndex + 1, totalPages),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildPdfHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LISTE DES FACTURES À PAYER',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        if (widget.selectedFournisseur != null) pw.Text('Fournisseur: ${widget.selectedFournisseur}'),
        if (widget.selectedStatut != null) pw.Text('Statut: ${_getStatutLabel(widget.selectedStatut!)}'),
        if (widget.dateDebut != null || widget.dateFin != null)
          pw.Text('Période: ${_formatDate(widget.dateDebut)} - ${_formatDate(widget.dateFin)}'),
        pw.Text('Total: ${widget.achats.length} échéance${widget.achats.length > 1 ? 's' : ''}'),
        pw.Text('Date d\'impression: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Achat> achats) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPdfHeaderCell('FOURNISSEURS'),
            _buildPdfHeaderCell('N°BL/F'),
            _buildPdfHeaderCell('MONTANT'),
            _buildPdfHeaderCell('PAYÉ'),
            _buildPdfHeaderCell('RESTE À PAYER'),
            _buildPdfHeaderCell('DATE FACTURE'),
            _buildPdfHeaderCell('ÉCHÉANCE'),
          ],
        ),
        ...achats.map((achat) {
          final resteAPayer = (achat.totalttc ?? 0) - (achat.regl ?? 0);
          return pw.TableRow(
            children: [
              _buildPdfCell(achat.frns ?? ''),
              _buildPdfCell(achat.nfact ?? ''),
              _buildPdfCell(AppFunctions.formatNumber(achat.totalttc ?? 0)),
              _buildPdfCell(AppFunctions.formatNumber(achat.regl ?? 0)),
              _buildPdfCell(AppFunctions.formatNumber(resteAPayer)),
              _buildPdfCell(_formatDate(achat.daty)),
              _buildPdfCell(_formatDate(achat.echeance)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildPdfFooter(int currentPage, int totalPages) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('GESTION COMMERCIALE DES PME'),
        pw.Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())),
        pw.Text('$currentPage'),
      ],
    );
  }
}
