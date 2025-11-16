import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../services/stock_management_service.dart';
import '../common/base_modal.dart';

class HistoriqueStockModal extends StatefulWidget {
  final String refArticle;

  const HistoriqueStockModal({
    super.key,
    required this.refArticle,
  });

  @override
  State<HistoriqueStockModal> createState() => _HistoriqueStockModalState();
}

class _HistoriqueStockModalState extends State<HistoriqueStockModal> {
  List<Stock> _mouvements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    try {
      final mouvements = await StockManagementService().getHistoriqueStock(widget.refArticle);
      setState(() {
        _mouvements = mouvements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Historique Stock - ${widget.refArticle}',
      width: 1000,
      height: 600,
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[200]!, Colors.blue[300]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.blue[400]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Date', flex: 2),
          _buildHeaderCell('Réf', flex: 2),
          _buildHeaderCell('Libellé', flex: 3),
          _buildHeaderCell('Dépôt', flex: 2),
          _buildHeaderCell('Entrée', flex: 2),
          _buildHeaderCell('Sortie', flex: 2),
          _buildHeaderCell('P.U.', flex: 2),
          _buildHeaderCell('CMUP', flex: 2),
          _buildHeaderCell('Client/Fournisseur', flex: 3),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.blue[400]!, width: 1)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_mouvements.isEmpty) {
      return const Center(
        child: Text('Aucun mouvement de stock trouvé'),
      );
    }

    return ListView.builder(
      itemCount: _mouvements.length,
      itemExtent: 24,
      itemBuilder: (context, index) {
        final mouvement = _mouvements[index];
        return _buildRow(mouvement, index);
      },
    );
  }

  Widget _buildRow(Stock mouvement, int index) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildDataCell(
            _formatDate(mouvement.daty),
            flex: 2,
          ),
          _buildDataCell(mouvement.ref, flex: 2),
          _buildDataCell(mouvement.lib ?? '', flex: 3),
          _buildDataCell(mouvement.depots ?? '', flex: 2),
          _buildDataCell(
            mouvement.entres != null ? mouvement.entres!.toStringAsFixed(2) : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.green[700],
          ),
          _buildDataCell(
            mouvement.sortie != null ? mouvement.sortie!.toStringAsFixed(2) : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.red[700],
          ),
          _buildDataCell(
            mouvement.pus?.toStringAsFixed(2) ?? '',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _buildDataCell(
            mouvement.cmup?.toStringAsFixed(2) ?? '',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _buildDataCell(
            mouvement.clt ?? mouvement.frns ?? '',
            flex: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    required int flex,
    Alignment alignment = Alignment.centerLeft,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color ?? Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
