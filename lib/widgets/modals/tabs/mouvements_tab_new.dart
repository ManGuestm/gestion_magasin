import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../models/inventaire_state.dart';
import '../../../utils/date_utils.dart';

/// Widget autonome pour l'affichage du tab Mouvements (Historique)
///
/// Responsabilités:
/// - Afficher historique des mouvements de stock
/// - Filtrer par type, date, dépôt
/// - Pagination de la liste
/// - Exporter données
/// - Calculer statistiques des mouvements
///
/// Utilise InventaireState pour immutabilité et callbacks pour mutations.
class MouvementsTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  final List<Stock> allMouvements;

  // === CALLBACKS ===
  final Function(String) onSearchChanged;
  final Function(String) onTypeChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function(String) onDepotChanged;
  final Function() onApplyFilters;
  final Function() onExport;
  final Function(int) onPageChanged;
  final Function(int?) onHoverChanged;

  const MouvementsTabNew({
    super.key,
    required this.state,
    required this.allMouvements,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onDateRangeChanged,
    required this.onDepotChanged,
    required this.onApplyFilters,
    required this.onExport,
    required this.onPageChanged,
    required this.onHoverChanged,
  });

  @override
  State<MouvementsTabNew> createState() => _MouvementsTabNewState();
}

class _MouvementsTabNewState extends State<MouvementsTabNew> {
  final ScrollController _scrollController = ScrollController();
  String _selectedMouvementType = 'Tous';
  String _selectedMouvementDepot = 'Tous';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildList()),
        _buildPagination(),
      ],
    );
  }

  /// En-tête avec titre et bouton export
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('Mouvements de Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.onExport,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Exporter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Barre de filtres
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Recherche
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher article...',
                prefixIcon: const Icon(Icons.search, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Type de mouvement
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedMouvementType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              items: [
                'Tous',
                'Entrée',
                'Sortie',
                'Inventaire',
                'Ajustement',
              ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMouvementType = value);
                  widget.onTypeChanged(value);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Dépôt
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedMouvementDepot,
              decoration: const InputDecoration(
                labelText: 'Dépôt',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              items: [
                'Tous',
                ...widget.state.depots.where((d) => d != 'Tous'),
              ].map((depot) => DropdownMenuItem(value: depot, child: Text(depot))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMouvementDepot = value);
                  widget.onDepotChanged(value);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Plage de dates
          SizedBox(
            width: 250,
            child: ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                );
                if (range != null) {
                  setState(() => _selectedDateRange = range);
                  widget.onDateRangeChanged(range);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _selectedDateRange == null
                    ? 'Sélectionner dates'
                    : '${AppDateUtils.formatDate(_selectedDateRange!.start)} - ${AppDateUtils.formatDate(_selectedDateRange!.end)}',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bouton appliquer
          ElevatedButton(
            onPressed: widget.onApplyFilters,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Appliquer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Liste virtualisée des mouvements
  Widget _buildList() {
    if (widget.state.filteredMouvements.isEmpty) {
      return const Center(
        child: Text('Aucun mouvement trouvé', style: TextStyle(color: Colors.grey)),
      );
    }

    final startIndex = widget.state.mouvementsPage * widget.state.itemsPerPage;
    final endIndex = (startIndex + widget.state.itemsPerPage).clamp(
      0,
      widget.state.filteredMouvements.length,
    );
    final pageMouvements = widget.state.filteredMouvements.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: _scrollController,
      itemCount: pageMouvements.length + 1, // +1 pour l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTableHeader();
        }

        final mouvement = pageMouvements[index - 1];
        return _buildMouvementRow(mouvement, index - 1);
      },
    );
  }

  /// En-tête du tableau des mouvements
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Article', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 1,
            child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 1,
            child: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 1,
            child: Text('Dépôt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  /// Ligne d'un mouvement
  Widget _buildMouvementRow(Stock mouvement, int itemIndex) {
    final typeText = mouvement.entres != null && mouvement.entres! > 0 ? 'Entrée' : 'Sortie';
    final typeColor = _getMouvementTypeColor(typeText);
    final isHovered = widget.state.hoveredMouvementIndex == itemIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHoverChanged(itemIndex),
      onExit: (_) => widget.onHoverChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Article
            Expanded(
              flex: 2,
              child: Text(
                mouvement.refart ?? 'N/A',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Type
            Expanded(
              flex: 1,
              child: Chip(
                label: Text(typeText),
                backgroundColor: typeColor.withValues(alpha: 0.3),
                labelStyle: TextStyle(color: typeColor, fontSize: 10),
              ),
            ),
            // Quantité
            Expanded(
              flex: 1,
              child: Text(
                (mouvement.entres ?? mouvement.qs ?? 0).toStringAsFixed(1),
                style: TextStyle(fontSize: 11, color: typeText == 'Entrée' ? Colors.green : Colors.red),
              ),
            ),
            // Dépôt
            Expanded(
              flex: 1,
              child: Text(mouvement.depots ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                mouvement.daty != null ? AppDateUtils.formatDate(mouvement.daty!) : 'N/A',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
            // Libellé
            Expanded(
              flex: 2,
              child: Text(
                mouvement.lib ?? 'Système',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Couleur selon le type de mouvement
  Color _getMouvementTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'entrée':
        return Colors.green;
      case 'sortie':
        return Colors.red;
      case 'inventaire':
        return Colors.orange;
      case 'ajustement':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Pagination
  Widget _buildPagination() {
    final totalPages = (widget.allMouvements.length / widget.state.itemsPerPage).ceil();

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < totalPages; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: i == widget.state.mouvementsPage ? null : () => widget.onPageChanged(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: i == widget.state.mouvementsPage ? Colors.blue : Colors.grey[300],
                  foregroundColor: i == widget.state.mouvementsPage ? Colors.white : Colors.black,
                ),
                child: Text('${i + 1}'),
              ),
            ),
        ],
      ),
    );
  }
}
