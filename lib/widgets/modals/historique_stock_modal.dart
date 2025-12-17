import 'package:flutter/material.dart';
import 'package:gestion_magasin/constants/app_functions.dart';

import '../../services/stock_management_service.dart';
import '../common/tab_navigation_widget.dart';

class HistoriqueStockModal extends StatefulWidget {
  final String refArticle;
  final String stockDisponible;

  const HistoriqueStockModal({super.key, required this.refArticle, required this.stockDisponible});

  @override
  State<HistoriqueStockModal> createState() => _HistoriqueStockModalState();
}

class _HistoriqueStockModalState extends State<HistoriqueStockModal> with TabNavigationMixin {
  List<Map<String, dynamic>> _mouvements = [];
  List<Map<String, dynamic>> _mouvementsAffiches = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 50;
  String _selectedDepot = 'Tous';
  List<String> _depots = ['Tous'];

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() => _isLoading = true);
    try {
      final mouvements = await StockManagementService().getHistoriqueStock(widget.refArticle);

      // Extraire les dépôts uniques
      final depotsSet = <String>{'Tous'};
      for (final mouvement in mouvements) {
        final depot = mouvement['depots']?.toString().trim();
        if (depot != null && depot.isNotEmpty) {
          depotsSet.add(depot);
        }
      }

      setState(() {
        _mouvements = mouvements;
        _depots = depotsSet.toList()..sort();
        _currentPage = 0;
        _isLoading = false;
      });
      _updateDisplayedMovements();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateDisplayedMovements() {
    final filtered = _selectedDepot == 'Tous'
        ? _mouvements
        : _mouvements.where((m) => m['depots']?.toString() == _selectedDepot).toList();

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);

    setState(() {
      _mouvementsAffiches = filtered.sublist(startIndex, endIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => handleTabNavigation(event),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique des Mouvements de Stock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Article: ${widget.refArticle}',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
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

    final filteredMovements = _selectedDepot == 'Tous'
        ? _mouvements
        : _mouvements.where((m) => m['depots']?.toString() == _selectedDepot).toList();

    final totalEntrees = filteredMovements.fold<double>(
      0,
      (sum, m) => sum + ((m['entree'] as num?)?.toDouble() ?? 0),
    );
    final totalSorties = filteredMovements.fold<double>(
      0,
      (sum, m) => sum + ((m['sortie'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            children: [
              _buildStatItem(
                'Total Mouvements',
                filteredMovements.length.toString(),
                Icons.swap_horiz,
                Colors.blue,
              ),
              _buildStatItem(
                'Total Entrées',
                AppFunctions.formatNumber(totalEntrees),
                Icons.arrow_downward,
                Colors.green,
              ),
              _buildStatItem(
                'Total Sorties',
                AppFunctions.formatNumber(totalSorties),
                Icons.arrow_upward,
                Colors.red,
              ),
              _buildStatItem(
                'Stock Disponible tous dépôts',
                widget.stockDisponible,
                Icons.balance,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: _buildDepotFilter()),
        ],
      ),
    );
  }

  Widget _buildDepotFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_list, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedDepot,
          isDense: true,
          underline: const SizedBox(),
          items: _depots
              .map(
                (depot) => DropdownMenuItem(
                  value: depot,
                  child: Text(depot, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDepot = value!;
              _currentPage = 0;
            });
            _updateDisplayedMovements();
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
          _buildHeaderCell('Libellé', flex: 4),
          _buildHeaderCell('Dépôt', flex: 2),
          _buildHeaderCell('Entrée', flex: 2),
          _buildHeaderCell('Sortie', flex: 2),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
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

    final filteredMovements = _selectedDepot == 'Tous'
        ? _mouvements
        : _mouvements.where((m) => m['depots']?.toString() == _selectedDepot).toList();

    if (filteredMovements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun mouvement de stock trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDepot == 'Tous'
                  ? 'Les mouvements de stock apparaîtront ici'
                  : 'Aucun mouvement pour le dépôt $_selectedDepot',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _mouvementsAffiches.length,
              itemBuilder: (context, index) {
                final mouvement = _mouvementsAffiches[index];
                return _buildModernRow(mouvement, index);
              },
            ),
          ),
          if (filteredMovements.length > _itemsPerPage) _buildPagination(filteredMovements.length),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} sur $totalPages ($totalItems éléments)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _updateDisplayedMovements();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
              ),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() => _currentPage++);
                        _updateDisplayedMovements();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernRow(Map<String, dynamic> mouvement, int index) {
    final entree = (mouvement['entree'] as num?)?.toDouble() ?? 0;
    final sortie = (mouvement['sortie'] as num?)?.toDouble() ?? 0;

    return Container(
      decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : Colors.grey[50]),
      child: Row(
        children: [
          _buildDataCell(_formatDate(mouvement['daty']), flex: 2),
          _buildDataCell(
            _getSourceLabel(mouvement['source']?.toString() ?? ''),
            flex: 2,
            color: _getSourceColor(mouvement['source']?.toString() ?? ''),
            isBadge: true,
          ),
          _buildDataCell(mouvement['ref']?.toString() ?? '', flex: 2),
          _buildDataCell(mouvement['lib']?.toString() ?? '', flex: 4),
          _buildDataCell(mouvement['depots']?.toString() ?? '', flex: 2),
          _buildDataCell(
            entree > 0
                ? '+${AppFunctions.formatNumber(entree)} ${mouvement['unite_entree']?.toString() ?? ''}'
                : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.green[700],
            isBold: entree > 0,
          ),
          _buildDataCell(
            sortie > 0
                ? '-${AppFunctions.formatNumber(sortie)} ${mouvement['unite_sortie']?.toString() ?? ''}'
                : '',
            flex: 2,
            alignment: Alignment.centerRight,
            color: Colors.red[700],
            isBold: sortie > 0,
          ),
          _buildDataCell(mouvement['clt']?.toString() ?? mouvement['frns']?.toString() ?? '', flex: 3),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? Colors.black87),
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

  String _formatDate(dynamic date) {
    if (date == null) return '';

    DateTime? dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is int) {
      // Timestamp en secondes ou millisecondes
      dateTime = DateTime.fromMillisecondsSinceEpoch(date > 1000000000000 ? date : date * 1000);
    }

    if (dateTime == null) return '';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
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
