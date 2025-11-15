import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class MouvementsClientsModal extends StatefulWidget {
  const MouvementsClientsModal({super.key});

  @override
  State<MouvementsClientsModal> createState() => _MouvementsClientsModalState();
}

class _MouvementsClientsModalState extends State<MouvementsClientsModal> {
  final DatabaseService _databaseService = DatabaseService();

  List<ComptecltData> _mouvements = [];
  List<ComptecltData> _filteredMouvements = [];
  List<CltData> _clients = [];
  String? _selectedClient;
  String? _selectedCommercial;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final clients = await _databaseService.database.getAllClients();
      final mouvements = await _databaseService.database.getAllCompteclts();

      setState(() {
        _clients = clients;
        _mouvements = mouvements;
        _filteredMouvements = mouvements;
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

  void _filterMouvements() {
    setState(() {
      _filteredMouvements = _mouvements.where((mouvement) {
        bool matchClient = _selectedClient == null || mouvement.clt == _selectedClient;
        return matchClient;
      }).toList();
    });
  }

  String _formatNumber(double? number) {
    if (number == null || number == 0) return '';
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: 1200,
        height: 700,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildTable(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[300],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            'MOUVEMENTS CLIENTS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          const Text('Commercial:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            width: 150,
            height: 25,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCommercial,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11, color: Colors.black),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCommercial = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          const Text('Client:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            width: 200,
            height: 25,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedClient,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11, color: Colors.black),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les clients')),
                ..._clients.map((client) => DropdownMenuItem(
                      value: client.rsoc,
                      child: Text(client.rsoc, style: const TextStyle(fontSize: 11)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedClient = value;
                });
                _filterMouvements();
              },
            ),
          ),
          const Spacer(),
          const Text('Commercial:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          const Text('Vérification:', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredMouvements.length,
                      itemExtent: 18,
                      itemBuilder: (context, index) {
                        final mouvement = _filteredMouvements[index];
                        return _buildTableRow(mouvement, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: Row(
        children: [
          _buildHeaderCell('DATE', 80),
          _buildHeaderCell('N° FACTURES', 80),
          _buildHeaderCell('N° PIECES', 80),
          _buildHeaderCell('MONTANT', 100),
          _buildHeaderCell('ECHEANCE BL', 80),
          _buildHeaderCell('LIBELLE PAIEMENT', 120),
          _buildHeaderCell('ECHEANCE P.', 80),
          _buildHeaderCell('MONTANT PAYE', 100),
          _buildHeaderCell('RESTE A PAYER', 100),
          _buildHeaderCell('Vérification', 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
          bottom: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(ComptecltData mouvement, int index) {
// Pas de sélection pour l'instant
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[50];

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: Row(
        children: [
          _buildCell(_formatDate(mouvement.daty), 80),
          _buildCell(mouvement.nfact ?? '', 80),
          _buildCell(mouvement.ref, 80),
          _buildCell(_formatNumber(mouvement.entres), 100, alignment: Alignment.centerRight),
          _buildCell('', 80), // Echéance BL
          _buildCell(mouvement.lib ?? '', 120),
          _buildCell('', 80), // Echéance P.
          _buildCell(_formatNumber(mouvement.sorties), 100, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(mouvement.solde), 100, alignment: Alignment.centerRight),
          _buildCell(mouvement.verification ?? '', 80),
        ],
      ),
    );
  }

  Widget _buildCell(String text, double width, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
