import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import 'verification_clients.dart';
import 'verification_fournisseur.dart';

class CaisseJournalierePage extends StatefulWidget {
  final AppDatabase database;

  const CaisseJournalierePage({super.key, required this.database});

  @override
  State<CaisseJournalierePage> createState() => _CaisseJournalierePageState();
}

class _CaisseJournalierePageState extends State<CaisseJournalierePage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> transactions = [];
  double soldeVeille = 0;
  bool isLoading = true;
  Map<String, dynamic>? selectedTransaction;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => isLoading = true);
    final db = widget.database;

    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final operations =
        await (db.select(db.caisse)..where((c) => c.daty.isBetweenValues(startOfDay, endOfDay))
            // ..orderBy([(c) => OrderingTerm.asc(c.daty)])
            )
            .get();

    // Calculer le solde des ventes Magasin de la veille
    final prevDayStart = startOfDay.subtract(const Duration(days: 1));
    final prevDayEnd = startOfDay;

    final ventesMagVeille =
        await (db.select(db.ventes)..where(
              (v) =>
                  v.daty.isBetweenValues(prevDayStart, prevDayEnd) &
                  v.verification.equals('JOURNAL') &
                  (v.type.isNull() | v.type.equals('MAG')) &
                  (v.contre.isNull() | v.contre.equals('0')),
            ))
            .get();

    final soldeMagVeille = ventesMagVeille.fold<double>(0.0, (sum, v) => sum + (v.totalttc ?? 0));

    setState(() {
      transactions = operations
          .map(
            (op) => {
              'date': DateFormat('dd/MM/yyyy').format(op.daty ?? DateTime.now()),
              'libelle': op.lib ?? '',
              'debit': op.debit ?? 0,
              'credit': op.credit ?? 0,
            },
          )
          .toList();

      soldeVeille = soldeMagVeille;
      isLoading = false;
    });
  }

  NumberFormat get currencyFormat => NumberFormat.decimalPattern('fr');

  double get totalDebit => transactions.fold(0, (sum, t) => sum + t['debit']);
  double get totalCredit => transactions.fold(0, (sum, t) => sum + t['credit']);
  double get soldeCaisse => soldeVeille + totalDebit - totalCredit;

  void _showVerificationClients() {
    showDialog(
      context: context,
      builder: (context) => VerificationClientsModal(database: widget.database),
    );
  }

  void _showVerificationFournisseurs() {
    showDialog(
      context: context,
      builder: (context) => VerificationFournisseursModal(database: widget.database),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Caisse journalière', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Caisse journalière',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {},
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Fermer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // En-tête avec date et solde de vente Magasin seulement de la veille
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date sélectionnée',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() => selectedDate = picked);
                                  _chargerDonnees();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.deepPurple),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Solde Magasin de la veille',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyFormat.format(soldeVeille)} Ar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tableau des transactions et Résumé en Row
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tableau des transactions
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
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
                                Icon(Icons.list_alt, color: Colors.deepPurple, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Opérations du jour',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${transactions.length} transactions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final dateWidth = constraints.maxWidth * 0.15;
                                final libelleWidth = constraints.maxWidth * 0.35;
                                final debitWidth = constraints.maxWidth * 0.18;
                                final creditWidth = constraints.maxWidth * 0.18;

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columnSpacing: 12,
                                      headingRowColor: WidgetStateProperty.all(
                                        Colors.grey.withValues(alpha: 0.2),
                                      ),
                                      border: TableBorder.symmetric(
                                        inside: BorderSide(color: Colors.grey[300]!),
                                        outside: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      dataRowMinHeight: 20,
                                      dataRowMaxHeight: 30,
                                      columns: [
                                        DataColumn(
                                          label: SizedBox(
                                            width: dateWidth.clamp(100, 150),
                                            child: const Text(
                                              'Date',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: libelleWidth.clamp(200, 400),
                                            child: const Text(
                                              'Libellé',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: debitWidth.clamp(120, 180),
                                            child: const Text(
                                              'Débit',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: creditWidth.clamp(120, 180),
                                            child: const Text(
                                              'Crédit',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          numeric: true,
                                        ),
                                      ],
                                      rows: transactions.map((t) {
                                        return DataRow(
                                          selected: selectedTransaction == t,
                                          onSelectChanged: (_) => setState(() => selectedTransaction = t),
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: dateWidth.clamp(100, 150),
                                                child: Text(t['date'], style: const TextStyle(fontSize: 13)),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: libelleWidth.clamp(200, 400),
                                                child: Text(
                                                  t['libelle'],
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: debitWidth.clamp(120, 180),
                                                child: Text(
                                                  t['debit'] > 0 ? currencyFormat.format(t['debit']) : '',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: creditWidth.clamp(120, 180),
                                                child: Text(
                                                  t['credit'] > 0 ? currencyFormat.format(t['credit']) : '',
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Résumé et actions
                  SizedBox(
                    width: 500,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (selectedTransaction == null || (selectedTransaction!['credit'] as double) > 0)
                            OutlinedButton.icon(
                              onPressed: () => _showVerificationClients(),
                              icon: const Icon(Icons.people, size: 18),
                              label: const Text('Vérification Clients'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          if (selectedTransaction != null && (selectedTransaction!['credit'] as double) > 0)
                            const SizedBox(height: 12),
                          if (selectedTransaction == null || (selectedTransaction!['debit'] as double) > 0)
                            OutlinedButton.icon(
                              onPressed: () => _showVerificationFournisseurs(),
                              icon: const Icon(Icons.business, size: 18),
                              label: const Text('Vérification Fournisseurs'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                foregroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Débit',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          currencyFormat.format(totalDebit),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Crédit',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          currencyFormat.format(totalCredit),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: soldeCaisse >= 0
                                    ? [Colors.green.shade50, Colors.green.shade100]
                                    : [Colors.red.shade50, Colors.red.shade100],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: soldeCaisse >= 0 ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SOLDE CAISSE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormat.format(soldeCaisse.abs()),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: soldeCaisse >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
