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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(String label, DateTime? date, IconData icon, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onChanged(selectedDate);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _formatDate(date) : 'Sélectionner',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDifferenceRow(Map<String, dynamic> diff, int index) {
    final diffPrix = (diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0);
    final quantite = diff['quantite'] ?? 0.0;
    final totDiff = quantite * diffPrix;

    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                _formatDateFromString(diff['date_vente']),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['numero_vente']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['bl_numero']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['nom_article']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['unite']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                quantite.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                '${_formatNumber(diff['prix_standard'] ?? 0.0)} Ar',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                '${_formatNumber(diff['prix_vendu'] ?? 0.0)} Ar',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getDifferenceColor(diffPrix).withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                '${_formatNumber(diffPrix)} Ar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getDifferenceColor(diffPrix),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getDifferenceColor(totDiff).withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                '${_formatNumber(totDiff)} Ar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getDifferenceColor(totDiff),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['nom_client']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                diff['commerciale']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifferenceColor(double difference) {
    if (difference > 0) return Colors.orange;
    if (difference < 0) return Colors.green;
    return Colors.grey;
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatDateFromString(dynamic dateValue) {
    if (dateValue == null) return '';

    try {
      DateTime date;
      if (dateValue is int) {
        // Timestamp Unix en secondes
        date = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else if (dateValue is String) {
        // Vérifier si c'est un timestamp en string
        final timestamp = int.tryParse(dateValue);
        if (timestamp != null) {
          date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else {
          date = DateTime.parse(dateValue);
        }
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return '';
      }
      return _formatDate(date);
    } catch (e) {
      return dateValue.toString();
    }
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
                    'Période: ${_dateDebut != null ? _formatDate(_dateDebut!) : 'Toutes'} - ${_dateFin != null ? _formatDate(_dateFin!) : 'Toutes'}',
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
                    _buildInfoRow('DATE DÉBUT:', _dateDebut != null ? _formatDate(_dateDebut!) : 'Toutes'),
                    _buildInfoRow('DATE FIN:', _dateFin != null ? _formatDate(_dateFin!) : 'Toutes'),
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
                        _buildTableCell(_formatDateFromString(diff['date_vente'])),
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
      name: 'Suivi_Difference_Prix_${_formatDate(DateTime.now())}.pdf',
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
                    _buildPdfInfoRow('DATE DÉBUT:', _dateDebut != null ? _formatDate(_dateDebut!) : 'Toutes'),
                    _buildPdfInfoRow('DATE FIN:', _dateFin != null ? _formatDate(_dateFin!) : 'Toutes'),
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
                  _buildPdfTableCell(_formatDateFromString(diff['date_vente'])),
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
    final totalDifferences = _differences.fold<double>(
      0,
      (sum, diff) =>
          sum + ((diff['quantite'] ?? 0.0) * ((diff['prix_standard'] ?? 0.0) - (diff['prix_vendu'] ?? 0.0))),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header moderne avec gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[600]!, Colors.deepPurple[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Suivi de Différence de Prix de Vente',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _loadDifferences(),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Actualiser',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),

              // Statistiques en cartes
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Nombre d\'écarts',
                        _differences.length.toString(),
                        Icons.trending_down,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total des différences',
                        '${_formatNumber(totalDifferences)} Ar',
                        Icons.monetization_on,
                        totalDifferences >= 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Écart moyen',
                        _differences.isNotEmpty
                            ? '${_formatNumber(totalDifferences / _differences.length)} Ar'
                            : '0 Ar',
                        Icons.calculate,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),

              // Filtres modernes
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Filtres de recherche',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateFilter(
                            'Date début',
                            _dateDebut,
                            Icons.calendar_today,
                            (date) {
                              if (date != null && _dateFin != null && date.isAfter(_dateFin!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('La date de début doit être antérieure à la date de fin'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setState(() => _dateDebut = date);
                              _loadDifferences();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateFilter(
                            'Date fin',
                            _dateFin,
                            Icons.event,
                            (date) {
                              if (date != null && _dateDebut != null && date.isBefore(_dateDebut!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('La date de fin doit être postérieure à la date de début'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setState(() => _dateFin = date);
                              _loadDifferences();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _blController,
                            decoration: InputDecoration(
                              labelText: 'N° Bon de Livraison',
                              prefixIcon: const Icon(Icons.receipt_long),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (_) => _loadDifferences(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _dateDebut = null;
                              _dateFin = null;
                              _blController.clear();
                            });
                            _loadDifferences();
                          },
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Réinitialiser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _differences.isNotEmpty ? _showPreview : null,
                          icon: const Icon(Icons.preview, size: 18),
                          label: const Text('Aperçu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tableau moderne
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Analyse des différences de prix...'),
                            ],
                          ),
                        )
                      : _differences.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.green[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune différence de prix détectée',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tous les prix de vente correspondent aux prix standards',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // En-tête du tableau
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeaderCell('Date', flex: 1),
                                      _buildHeaderCell('N° Vente', flex: 1),
                                      _buildHeaderCell('BL N°', flex: 1),
                                      _buildHeaderCell('Article', flex: 2),
                                      _buildHeaderCell('Unité', flex: 1),
                                      _buildHeaderCell('Qté', flex: 1),
                                      _buildHeaderCell('Prix Std', flex: 1),
                                      _buildHeaderCell('Prix Vendu', flex: 1),
                                      _buildHeaderCell('Écart', flex: 1),
                                      _buildHeaderCell('Total Écart', flex: 1),
                                      _buildHeaderCell('Client', flex: 2),
                                      _buildHeaderCell('Vendeur', flex: 1),
                                    ],
                                  ),
                                ),
                                // Corps du tableau
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _differences.length,
                                    itemBuilder: (context, index) {
                                      final diff = _differences[index];
                                      return _buildDifferenceRow(diff, index);
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blController.dispose();
    super.dispose();
  }
}
