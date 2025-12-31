import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/stock_converter.dart';
import '../../widgets/common/enhanced_autocomplete.dart';

class StocksFournisseursScreen extends StatefulWidget {
  const StocksFournisseursScreen({super.key});

  @override
  State<StocksFournisseursScreen> createState() => _StocksFournisseursScreenState();
}

class _StocksFournisseursScreenState extends State<StocksFournisseursScreen> {
  List<Map<String, dynamic>> _stocksData = [];
  String? _selectedFournisseur;
  List<Frn> _fournisseurs = [];
  bool _isLoading = true;
  final TextEditingController _fournisseurController = TextEditingController();
  final FocusNode _fournisseurFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  Future<void> _loadFournisseurs() async {
    final frns = await DatabaseService().database.getActiveFournisseurs();
    setState(() {
      _fournisseurs = frns;
      _isLoading = false;
    });
  }

  Future<void> _loadStocksParFournisseur(String fournisseur) async {
    setState(() => _isLoading = true);

    final data = await DatabaseService().database
        .customSelect(
          '''
      SELECT 
        a.designation,
        COALESCE(d_mag.stocksu1, 0) as stockU1_MAG,
        COALESCE(d_mag.stocksu2, 0) as stockU2_MAG,
        COALESCE(d_mag.stocksu3, 0) as stockU3_MAG,
        COALESCE(d_cda.stocksu1, 0) as stockU1_CDA,
        COALESCE(d_cda.stocksu2, 0) as stockU2_CDA,
        COALESCE(d_cda.stocksu3, 0) as stockU3_CDA,
        a.u1, a.u2, a.u3, a.tu2u1, a.tu3u2
      FROM articles a
      LEFT JOIN depart d_mag ON a.designation = d_mag.designation AND d_mag.depots = 'MAG'
      LEFT JOIN depart d_cda ON a.designation = d_cda.designation AND d_cda.depots = 'CDA'
      WHERE (a.frns1 = ? OR a.frns2 = ? OR a.frns3 = ?)
      ORDER BY a.designation
    ''',
          variables: [Variable(fournisseur), Variable(fournisseur), Variable(fournisseur)],
        )
        .get();

    setState(() {
      _stocksData = data
          .map(
            (row) => {
              'designation': row.read<String>('designation'),
              'stockU1_MAG': row.read<double>('stockU1_MAG'),
              'stockU2_MAG': row.read<double>('stockU2_MAG'),
              'stockU3_MAG': row.read<double>('stockU3_MAG'),
              'stockU1_CDA': row.read<double>('stockU1_CDA'),
              'stockU2_CDA': row.read<double>('stockU2_CDA'),
              'stockU3_CDA': row.read<double>('stockU3_CDA'),
              'u1': row.readNullable<String>('u1'),
              'u2': row.readNullable<String>('u2'),
              'u3': row.readNullable<String>('u3'),
              'tu2u1': row.readNullable<double>('tu2u1'),
              'tu3u2': row.readNullable<double>('tu3u2'),
            },
          )
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks par Fournisseurs'),
        actions: [
          if (_selectedFournisseur != null && _stocksData.isNotEmpty)
            IconButton(icon: const Icon(Icons.print), tooltip: 'Imprimer', onPressed: _imprimerStocks),
        ],
      ),
      body: Column(
        children: [
          _buildFournisseurSelector(),
          Expanded(child: _buildStocksTable()),
        ],
      ),
    );
  }

  Widget _buildFournisseurSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Text('Fournisseur : ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Expanded(
            child: EnhancedAutocomplete<Frn>(
              controller: _fournisseurController,
              focusNode: _fournisseurFocusNode,
              options: _fournisseurs,
              displayStringForOption: (frn) => frn.rsoc,
              onSelected: (frn) {
                setState(() => _selectedFournisseur = frn.rsoc);
                _loadStocksParFournisseur(frn.rsoc);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'Sélectionner un fournisseur',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedFournisseur == null) {
      return const Center(child: Text('Veuillez sélectionner un fournisseur'));
    }

    if (_stocksData.isEmpty) {
      return const Center(child: Text('Aucun article trouvé pour ce fournisseur'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(
              label: Text('Désignation article', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Stocks dans Magasin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Stocks dans le dépôt CDA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: _stocksData.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row['designation'])),
                DataCell(_buildStockCell(row['stockU1_MAG'], row['u1'], row, 'MAG')),
                DataCell(_buildStockCell(row['stockU1_CDA'], row['u1'], row, 'CDA')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStockCell(double stock, String? unite, Map<String, dynamic> row, String depot) {
    if (unite == null || unite.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }

    // Créer un article temporaire pour la conversion
    final article = Article(
      designation: row['designation'],
      u1: row['u1'],
      u2: row['u2'],
      u3: row['u3'],
      tu2u1: row['tu2u1'],
      tu3u2: row['tu3u2'],
    );

    // Récupérer les stocks bruts pour ce dépôt
    final stockU1 = row['stockU1_$depot'] as double;
    final stockU2 = row['stockU2_$depot'] as double;
    final stockU3 = row['stockU3_$depot'] as double;

    // Calculer le stock total en unité de base (U3) DIRECTEMENT
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    // Convertir le stock total vers les unités optimales
    final stocksOptimaux = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: stockTotalU3,
    );

    // Formater l'affichage avec conversion
    final displayText = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stocksOptimaux['u1']!,
      stockU2: stocksOptimaux['u2']!,
      stockU3: stocksOptimaux['u3']!,
    );

    Color color = Colors.black;
    if (stockTotalU3 < 0) {
      color = Colors.red;
    } else if (stockTotalU3 == 0) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Text(
      displayText,
      style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
    );
  }

  Future<void> _imprimerStocks() async {
    final pdf = pw.Document();

    final tableData = _stocksData.map((row) {
      final article = Article(
        designation: row['designation'],
        u1: row['u1'],
        u2: row['u2'],
        u3: row['u3'],
        tu2u1: row['tu2u1'],
        tu3u2: row['tu3u2'],
      );

      String getStockText(String depot) {
        final stockU1 = row['stockU1_$depot'] as double;
        final stockU2 = row['stockU2_$depot'] as double;
        final stockU3 = row['stockU3_$depot'] as double;

        final stockTotalU3 = StockConverter.calculerStockTotalU3(
          article: article,
          stockU1: stockU1,
          stockU2: stockU2,
          stockU3: stockU3,
        );

        final stocksOptimaux = StockConverter.convertirStockOptimal(
          article: article,
          quantiteU1: 0.0,
          quantiteU2: 0.0,
          quantiteU3: stockTotalU3,
        );

        return StockConverter.formaterAffichageStock(
          article: article,
          stockU1: stocksOptimaux['u1']!,
          stockU2: stocksOptimaux['u2']!,
          stockU3: stocksOptimaux['u3']!,
        );
      }

      return [row['designation'], getStockText('MAG'), getStockText('CDA')];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Stocks par Fournisseur',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fournisseur: $_selectedFournisseur', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Désignation article', 'Stock dans Magasin', 'Stock dans le dépôt CDA'],
            data: tableData,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  void dispose() {
    _fournisseurController.dispose();
    _fournisseurFocusNode.dispose();
    super.dispose();
  }
}
