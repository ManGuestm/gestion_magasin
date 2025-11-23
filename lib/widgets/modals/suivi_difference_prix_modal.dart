import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class SuiviDifferencePrixModal extends StatefulWidget {
  const SuiviDifferencePrixModal({super.key});

  @override
  State<SuiviDifferencePrixModal> createState() => _SuiviDifferencePrixModalState();
}

class _SuiviDifferencePrixModalState extends State<SuiviDifferencePrixModal> with TabNavigationMixin {
  List<Map<String, dynamic>> _differences = [];
  bool _isLoading = true;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final TextEditingController _blController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDifferences();
  }

  Future<void> _loadDifferences() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final differences = await db.getDifferencesPrixVente(_dateDebut, _dateFin, _blController.text.trim());
      setState(() {
        _differences = differences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Color _getDifferenceColor(double difference) {
    if (difference > 0) return Colors.orange;
    if (difference < 0) return Colors.green;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _showPreview() async {
    final db = DatabaseService().database;
    final societe = await db.getAllSoc().then((socs) => socs.isNotEmpty ? socs.first : null);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Scaffold(
        body: Column(
          children: [
            // Window title bar
            Container(
              height: 32,
              color: const Color(0xFF2D2D30),
              child: const Row(
                children: [
                  SizedBox(width: 8),
                  Icon(Icons.analytics, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Aperçu - Suivi de différence de Prix de vente',
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
                    onPressed: () => _printReport(),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimer'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                  const Spacer(),
                  Text(
                    'Période: ${_dateDebut?.toString().split(' ')[0] ?? 'Toutes'} - ${_dateFin?.toString().split(' ')[0] ?? 'Toutes'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    width: 1100,
                    height: 800,
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
                        padding: const EdgeInsets.all(16),
                        child: _buildReportContent(societe),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(SocData? societe) {
    final totalDifferences = _differences.fold<double>(
      0,
      (sum, diff) =>
          sum + ((diff['quantite'] ?? 0.0) * ((diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0))),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document title centered
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: const Text(
              'SUIVI DE DIFFÉRENCE DE PRIX DE VENTE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Header section with company info
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOCIÉTÉ:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    Text(
                      societe?.rsoc ?? 'SOCIÉTÉ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (societe?.activites != null)
                      Text(
                        societe!.activites!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (societe?.adr != null)
                      Text(
                        societe!.adr!,
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('DATE DÉBUT:', _dateDebut?.toString().split(' ')[0] ?? 'Toutes'),
                    _buildInfoRow('DATE FIN:', _dateFin?.toString().split(' ')[0] ?? 'Toutes'),
                    if (_blController.text.isNotEmpty) _buildInfoRow('BL N°:', _blController.text),
                    _buildInfoRow('DATE ÉDITION:', _formatDate(DateTime.now())),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Data table
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
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(3),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.5),
                    7: FlexColumnWidth(1.5),
                    8: FlexColumnWidth(1.5),
                    9: FlexColumnWidth(2),
                    10: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableCell('DATE', isHeader: true),
                        _buildTableCell('N° VENTE', isHeader: true),
                        _buildTableCell('BL N°', isHeader: true),
                        _buildTableCell('ARTICLE', isHeader: true),
                        _buildTableCell('QTÉ', isHeader: true),
                        _buildTableCell('PRIX STD', isHeader: true),
                        _buildTableCell('PRIX VENDU', isHeader: true),
                        _buildTableCell('DIFF-PRIX', isHeader: true),
                        _buildTableCell('TOT-DIFF', isHeader: true),
                        _buildTableCell('CLIENT', isHeader: true),
                        _buildTableCell('VENDEUR', isHeader: true),
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
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(3),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1.5),
                  6: FlexColumnWidth(1.5),
                  7: FlexColumnWidth(1.5),
                  8: FlexColumnWidth(1.5),
                  9: FlexColumnWidth(2),
                  10: FlexColumnWidth(1.5),
                },
                children: [
                  ..._differences.map((diff) {
                    final diffPrix = (diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0);
                    final quantite = diff['quantite'] ?? 0.0;
                    final totDiff = quantite * diffPrix;
                    return TableRow(
                      children: [
                        _buildTableCell(diff['date_vente']?.toString().split(' ')[0] ?? ''),
                        _buildTableCell(diff['numero_vente']?.toString() ?? ''),
                        _buildTableCell(diff['bl_numero']?.toString() ?? ''),
                        _buildTableCell(diff['nom_article']?.toString() ?? ''),
                        _buildTableCell(quantite.toStringAsFixed(0), isAmount: true),
                        _buildTableCell('${(diff['prix_standard'] ?? 0.0).toStringAsFixed(0)} Ar',
                            isAmount: true),
                        _buildTableCell('${(diff['prix_vendu'] ?? 0.0).toStringAsFixed(0)} Ar',
                            isAmount: true),
                        _buildTableCell('${diffPrix.toStringAsFixed(0)} Ar', isAmount: true),
                        _buildTableCell('${totDiff.toStringAsFixed(0)} Ar', isAmount: true),
                        _buildTableCell(diff['nom_client']?.toString() ?? ''),
                        _buildTableCell(diff['commerciale']?.toString() ?? ''),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Total section
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'TOTAL DES DIFFÉRENCES: ${totalDifferences.toStringAsFixed(0)} Ar',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
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
      padding: const EdgeInsets.all(6),
      decoration: isHeader
          ? BoxDecoration(
              color: Colors.grey[200],
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: isHeader ? TextAlign.center : (isAmount ? TextAlign.right : TextAlign.left),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _printReport() async {
    final db = DatabaseService().database;
    final societe = await db.getAllSoc().then((socs) => socs.isNotEmpty ? socs.first : null);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          _buildPdfContent(societe),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Suivi_Difference_Prix_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  pw.Widget _buildPdfContent(SocData? societe) {
    final totalDifferences = _differences.fold<double>(
      0,
      (sum, diff) =>
          sum + ((diff['quantite'] ?? 0.0) * ((diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0))),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 2),
                bottom: pw.BorderSide(width: 2),
              ),
            ),
            child: pw.Text(
              'SUIVI DE DIFFÉRENCE DE PRIX DE VENTE',
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        // Header info
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SOCIÉTÉ:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(societe?.rsoc ?? 'SOCIÉTÉ', style: const pw.TextStyle(fontSize: 12)),
                    if (societe?.activites != null)
                      pw.Text(societe!.activites!, style: const pw.TextStyle(fontSize: 11)),
                    if (societe?.adr != null) pw.Text(societe!.adr!, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfInfoRow('DATE DÉBUT:', _dateDebut?.toString().split(' ')[0] ?? 'Toutes'),
                    _buildPdfInfoRow('DATE FIN:', _dateFin?.toString().split(' ')[0] ?? 'Toutes'),
                    if (_blController.text.isNotEmpty) _buildPdfInfoRow('BL N°:', _blController.text),
                    _buildPdfInfoRow('DATE ÉDITION:', _formatDate(DateTime.now())),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Data table
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(3),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(1.5),
            7: const pw.FlexColumnWidth(1.5),
            8: const pw.FlexColumnWidth(1.5),
            9: const pw.FlexColumnWidth(2),
            10: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildPdfTableCell('DATE', isHeader: true),
                _buildPdfTableCell('N° VENTE', isHeader: true),
                _buildPdfTableCell('BL N°', isHeader: true),
                _buildPdfTableCell('ARTICLE', isHeader: true),
                _buildPdfTableCell('QTÉ', isHeader: true),
                _buildPdfTableCell('PRIX STD', isHeader: true),
                _buildPdfTableCell('PRIX VENDU', isHeader: true),
                _buildPdfTableCell('DIFF-PRIX', isHeader: true),
                _buildPdfTableCell('TOT-DIFF', isHeader: true),
                _buildPdfTableCell('CLIENT', isHeader: true),
                _buildPdfTableCell('VENDEUR', isHeader: true),
              ],
            ),
            // Data rows
            ..._differences.map((diff) {
              final diffPrix = (diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0);
              final quantite = diff['quantite'] ?? 0.0;
              final totDiff = quantite * diffPrix;
              return pw.TableRow(
                children: [
                  _buildPdfTableCell(diff['date_vente']?.toString().split(' ')[0] ?? ''),
                  _buildPdfTableCell(diff['numero_vente']?.toString() ?? ''),
                  _buildPdfTableCell(diff['bl_numero']?.toString() ?? ''),
                  _buildPdfTableCell(diff['nom_article']?.toString() ?? ''),
                  _buildPdfTableCell(quantite.toStringAsFixed(0), isAmount: true),
                  _buildPdfTableCell('${(diff['prix_standard'] ?? 0.0).toStringAsFixed(0)} Ar',
                      isAmount: true),
                  _buildPdfTableCell('${(diff['prix_vendu'] ?? 0.0).toStringAsFixed(0)} Ar', isAmount: true),
                  _buildPdfTableCell('${diffPrix.toStringAsFixed(0)} Ar', isAmount: true),
                  _buildPdfTableCell('${totDiff.toStringAsFixed(0)} Ar', isAmount: true),
                  _buildPdfTableCell(diff['nom_client']?.toString() ?? ''),
                  _buildPdfTableCell(diff['commerciale']?.toString() ?? ''),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 16),

        // Total
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL DES DIFFÉRENCES: ${totalDifferences.toStringAsFixed(0)} Ar',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false, bool isAmount = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: isHeader ? pw.TextAlign.center : (isAmount ? pw.TextAlign.right : pw.TextAlign.left),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suivi de différence de Prix de vente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtres
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateDebut ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateDebut = date);
                        _loadDifferences();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateDebut?.toString().split(' ')[0] ?? 'Sélectionner',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateFin = date);
                        _loadDifferences();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateFin?.toString().split(' ')[0] ?? 'Sélectionner',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _blController,
                    decoration: const InputDecoration(
                      labelText: 'BL N°',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _loadDifferences(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dateDebut = null;
                      _dateFin = null;
                      _blController.clear();
                    });
                    _loadDifferences();
                  },
                  child: const Text('Réinitialiser'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _differences.isNotEmpty ? () => _showPreview() : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Aperçus', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tableau des différences
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('N° Vente')),
                          DataColumn(label: Text('BL N°')),
                          DataColumn(label: Text('Article')),
                          DataColumn(label: Text('Qté')),
                          DataColumn(label: Text('Prix Standard')),
                          DataColumn(label: Text('Prix Vendu')),
                          DataColumn(label: Text('Diff-Prix')),
                          DataColumn(label: Text('Tot-Diff')),
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Vendeur')),
                        ],
                        rows: _differences.map((diff) {
                          final diffPrix = (diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0);
                          final quantite = diff['quantite'] ?? 0.0;
                          final totDiff = quantite * diffPrix;
                          return DataRow(
                            cells: [
                              DataCell(Text(diff['date_vente']?.toString().split(' ')[0] ?? '')),
                              DataCell(Text(diff['numero_vente']?.toString() ?? '')),
                              DataCell(Text(diff['bl_numero']?.toString() ?? '')),
                              DataCell(Text(diff['nom_article']?.toString() ?? '')),
                              DataCell(Container(
                                alignment: Alignment.centerRight,
                                child: Text('${quantite.toStringAsFixed(0)}'),
                              )),
                              DataCell(Container(
                                alignment: Alignment.centerRight,
                                child: Text('${diff['prix_standard']?.toStringAsFixed(2) ?? '0.00'} Ar'),
                              )),
                              DataCell(Container(
                                alignment: Alignment.centerRight,
                                child: Text('${diff['prix_vendu']?.toStringAsFixed(2) ?? '0.00'} Ar'),
                              )),
                              DataCell(Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDifferenceColor(diffPrix).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${diffPrix.toStringAsFixed(2)} Ar',
                                  style: TextStyle(
                                    color: _getDifferenceColor(diffPrix),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )),
                              DataCell(Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDifferenceColor(totDiff).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${totDiff.toStringAsFixed(2)} Ar',
                                  style: TextStyle(
                                    color: _getDifferenceColor(totDiff),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )),
                              DataCell(Text(diff['nom_client']?.toString() ?? '')),
                              DataCell(Text(diff['commerciale']?.toString() ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Total des différences
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total des différences: ${_differences.fold<double>(0, (sum, diff) => sum + ((diff['quantite'] ?? 0.0) * ((diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0)))).toStringAsFixed(2)} Ar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  @override
  void dispose() {
    _blController.dispose();
    super.dispose();
  }
}
