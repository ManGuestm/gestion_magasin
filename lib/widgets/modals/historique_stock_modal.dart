import 'package:flutter/material.dart';
import 'package:gestion_magasin/constants/app_functions.dart';

import '../../services/stock_management_service.dart';
import '../common/tab_navigation_widget.dart';

class HistoriqueStockModal extends StatefulWidget {
  final String refArticle;

  const HistoriqueStockModal({
    super.key,
    required this.refArticle,
  });

  @override
  State<HistoriqueStockModal> createState() => _HistoriqueStockModalState();
}

class _HistoriqueStockModalState extends State<HistoriqueStockModal> with TabNavigationMixin {
  List<Map<String, dynamic>> _mouvements = [];
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
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 1200,
          height: 700,
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
              _buildModernHeader(),
              _buildStatsBar(),
              Expanded(child: _buildModernContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[700]!],
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
              Icons.history,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique des Mouvements de Stock',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Article: ${widget.refArticle}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadHistorique,
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
    );
  }

  Widget _buildStatsBar() {
    if (_isLoading) return const SizedBox.shrink();

    final totalEntrees =
        _mouvements.fold<double>(0, (sum, m) => sum + (double.tryParse(m['entree']?.toString() ?? '0') ?? 0));
    final totalSorties =
        _mouvements.fold<double>(0, (sum, m) => sum + (double.tryParse(m['sortie']?.toString() ?? '0') ?? 0));
    final soldeNet = totalEntrees - totalSorties;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildStatItem('Total Mouvements', _mouvements.length.toString(), Icons.swap_horiz, Colors.blue),
          const SizedBox(width: 24),
          _buildStatItem(
              'Total Entrées', AppFunctions.formatNumber(totalEntrees), Icons.arrow_downward, Colors.green),
          const SizedBox(width: 24),
          _buildStatItem(
              'Total Sorties', AppFunctions.formatNumber(totalSorties), Icons.arrow_upward, Colors.red),
          const SizedBox(width: 24),
          _buildStatItem('Solde Net', AppFunctions.formatNumber(soldeNet), Icons.balance,
              soldeNet >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
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
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Date', flex: 2),
          _buildHeaderCell('Type', flex: 2),
          _buildHeaderCell('Réf', flex: 2),
          _buildHeaderCell('Libellé', flex: 3),
          _buildHeaderCell('Dépôt', flex: 2),
          _buildHeaderCell('Entrée', flex: 2),
          _buildHeaderCell('Sortie', flex: 2),
          _buildHeaderCell('P.U.', flex: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 0.5)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildModernContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de l\'historique...'),
          ],
        ),
      );
    }

    if (_mouvements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun mouvement de stock trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les mouvements de stock apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _mouvements.length,
              itemBuilder: (context, index) {
                final mouvement = _mouvements[index];
                return _buildModernRow(mouvement, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRow(Map<String, dynamic> mouvement, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
      ),
      child: Row(
        children: [
          _buildDataCell(
            _formatDate(mouvement['daty']),
            flex: 2,
          ),
          _buildDataCell(
            _getSourceLabel(mouvement['source']),
            flex: 2,
            color: _getSourceColor(mouvement['source']),
            isBadge: true,
          ),
          _buildDataCell(mouvement['ref'] ?? '', flex: 2),
          _buildDataCell(mouvement['lib'] ?? '', flex: 3),
          _buildDataCell(mouvement['depots'] ?? '', flex: 2),
          _buildDataCell(
            (double.tryParse(mouvement['entree']?.toString() ?? '0') ?? 0) > 0
                ? '+${(AppFunctions.formatNumber(double.tryParse(mouvement['entree']?.toString() ?? '0') ?? 0))} ${mouvement['unite_entree'] ?? ''}'
                : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.green[700],
            isBold: (double.tryParse(mouvement['entree']?.toString() ?? '0') ?? 0) > 0,
          ),
          _buildDataCell(
            (double.tryParse(mouvement['sortie']?.toString() ?? '0') ?? 0) > 0
                ? '-${(AppFunctions.formatNumber(double.tryParse(mouvement['sortie']?.toString() ?? '0') ?? 0))} ${mouvement['unite_sortie'] ?? ''}'
                : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.red[700],
            isBold: (double.tryParse(mouvement['sortie']?.toString() ?? '0') ?? 0) > 0,
          ),
          _buildDataCell(
            (double.tryParse(mouvement['pus']?.toString() ?? '0') ?? 0) > 0
                ? '${(AppFunctions.formatNumber(double.tryParse(mouvement['pus']?.toString() ?? '0') ?? 0))} Ar'
                : '',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _buildDataCell(
            mouvement['clt'] ?? mouvement['frns'] ?? '',
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
    bool isBadge = false,
    bool isBold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 30,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.1),
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
            right: BorderSide(color: Colors.grey[400]!, width: 0.5),
          ),
        ),
        child: isBadge && text.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.black87,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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

  String _getSourceLabel(String source) {
    switch (source) {
      case 'VENTE':
        return 'Vente';
      case 'ACHAT':
        return 'Achat';
      case 'RETOUR_VENTE':
        return 'Ret. Vente';
      case 'RETOUR_ACHAT':
        return 'Ret. Achat';
      case 'STOCK':
        return 'Mouvement';
      default:
        return source;
    }
  }

  Color? _getSourceColor(String source) {
    switch (source) {
      case 'VENTE':
        return Colors.red[600];
      case 'ACHAT':
        return Colors.green[600];
      case 'RETOUR_VENTE':
        return Colors.orange[600];
      case 'RETOUR_ACHAT':
        return Colors.blue[600];
      case 'STOCK':
        return Colors.purple[600];
      default:
        return null;
    }
  }
}
