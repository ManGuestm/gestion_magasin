import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';
import 'add_fournisseur_modal.dart';

class FournisseursModal extends StatefulWidget {
  const FournisseursModal({super.key});

  @override
  State<FournisseursModal> createState() => _FournisseursModalState();
}

class _FournisseursModalState extends State<FournisseursModal> with TabNavigationMixin {
  List<Frn> _fournisseurs = [];
  List<Frn> _filteredFournisseurs = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  late final FocusNode _keyboardFocusNode;
  Frn? _selectedFournisseur;
  List<Comptefrn> _historiqueFournisseur = [];
  final int _pageSize = 100;
  bool _isLoading = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchFocus = createFocusNode();
    _keyboardFocusNode = createFocusNode();
    _loadFournisseurs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _selectFournisseur(Frn fournisseur) {
    setState(() {
      _selectedFournisseur = fournisseur;
    });
    _loadHistoriqueFournisseur(fournisseur.rsoc);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcut,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: AppConstants.defaultModalWidth,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: GestureDetector(
                  onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSearchCard(),
                        const SizedBox(height: 12),
                        _buildFournisseursCard(),
                        const SizedBox(height: 12),
                        _buildHistoriqueCard(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
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
            child: const Icon(Icons.business, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Fournisseurs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Gérer et consulter vos fournisseurs',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildHeaderButton(Icons.add, 'Nouveau', () => _showAddFournisseurModal()),
        const SizedBox(width: 8),
        _buildHeaderButton(Icons.refresh, 'Actualiser', _loadFournisseurs),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            const Text(
              'Rechercher:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Tapez le nom du fournisseur...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  onChanged: filterFournisseurs,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAllFournisseurs,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tout afficher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFournisseursCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildFournisseursHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFournisseurs.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun fournisseur trouvé',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFournisseurs.length,
                          itemExtent: 32,
                          itemBuilder: (context, index) {
                            final fournisseur = _filteredFournisseurs[index];
                            final isSelected = _selectedFournisseur?.rsoc == fournisseur.rsoc;
                            return _buildFournisseurRow(fournisseur, isSelected, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFournisseursHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        children: [
          _buildSortableHeaderCell('RAISON SOCIALE', 'rsoc', flex: 4),
          _buildSortableHeaderCell('SOLDES', 'soldes', flex: 2),
          _buildSortableHeaderCell('ACTION', 'action', width: 100),
        ],
      ),
    );
  }

  Widget _buildSortableHeaderCell(String text, String column, {int? flex, double? width}) {
    Widget cell = GestureDetector(
      onTap: () => _sortBy(column),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
          color: _sortColumn == column ? Colors.blue[50] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _sortColumn == column ? Colors.blue[800] : Colors.black87,
              ),
            ),
            if (_sortColumn == column)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.blue[800],
              ),
          ],
        ),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
  }

  Widget _buildFournisseurRow(Frn fournisseur, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectFournisseur(fournisseur),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[25]),
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildDataCell(
              fournisseur.rsoc,
              flex: 4,
              isSelected: isSelected,
              alignment: Alignment.centerLeft,
            ),
            _buildDataCell(
              _formatMontant(fournisseur.soldes ?? 0),
              flex: 2,
              isSelected: isSelected,
              alignment: Alignment.centerRight,
              isAmount: true,
              amount: fournisseur.soldes ?? 0,
            ),
            _buildStatusCell(fournisseur.action ?? 'A', isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status, bool isSelected) {
    final isActive = status == 'A';
    return Container(
      width: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[100] : Colors.red[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green[300]! : Colors.red[300]!,
          ),
        ),
        child: Text(
          isActive ? 'Actif' : 'Inactif',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    int? flex,
    double? width,
    required bool isSelected,
    required Alignment alignment,
    bool isAmount = false,
    double? amount,
  }) {
    Widget cell = Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isAmount && amount != null
              ? (amount >= 0 ? Colors.green[700] : Colors.red[700])
              : (isSelected ? Colors.blue[800] : Colors.black87),
          fontWeight: isSelected || isAmount ? FontWeight.w500 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildNavButton(Icons.first_page, _goToFirst, 'Premier'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.chevron_left, _goToPrevious, 'Précédent'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.chevron_right, _goToNext, 'Suivant'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.last_page, _goToLast, 'Dernier'),
          const Spacer(),
          if (_selectedFournisseur != null) ...[
            ElevatedButton.icon(
              onPressed: () => _showAddFournisseurModal(fournisseur: _selectedFournisseur),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _deleteFournisseur(_selectedFournisseur!),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[100],
          foregroundColor: Colors.blue[700],
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Future<void> _loadFournisseurs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Chargement direct avec requête SQL pour éviter les problèmes de conversion
      final result = await DatabaseService()
          .database
          .customSelect(
            'SELECT rsoc, adr, capital, rcs, nif, stat, tel, port, email, site, fax, telex, soldes, datedernop, delai, soldesa, action FROM frns',
          )
          .get();

      final fournisseurs = result
          .map((row) => Frn(
                rsoc: row.read<String>('rsoc'),
                adr: row.read<String?>('adr'),
                capital: _safeReadDouble(row, 'capital'),
                rcs: row.read<String?>('rcs'),
                nif: row.read<String?>('nif'),
                stat: row.read<String?>('stat'),
                tel: row.read<String?>('tel'),
                port: row.read<String?>('port'),
                email: row.read<String?>('email'),
                site: row.read<String?>('site'),
                fax: row.read<String?>('fax'),
                telex: row.read<String?>('telex'),
                soldes: _safeReadDouble(row, 'soldes'),
                datedernop: row.read<DateTime?>('datedernop'),
                delai: row.read<int?>('delai'),
                soldesa: _safeReadDouble(row, 'soldesa'),
                action: row.read<String?>('action'),
              ))
          .toList();

      debugPrint('Nombre de fournisseurs trouvés: ${fournisseurs.length}');

      setState(() {
        _fournisseurs = fournisseurs;
        _isLoading = false;
      });
      _applySort();

      debugPrint('Fournisseurs chargés: ${_filteredFournisseurs.length}');
    } catch (e) {
      debugPrint('Erreur lors du chargement des fournisseurs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double? _safeReadDouble(QueryRow row, String column) {
    try {
      // Essayer d'abord comme double
      try {
        return row.readNullable<double>(column);
      } catch (_) {}

      // Puis comme int
      try {
        final intValue = row.readNullable<int>(column);
        return intValue?.toDouble();
      } catch (_) {}

      // Enfin comme string
      try {
        final stringValue = row.readNullable<String>(column);
        if (stringValue == null || stringValue.isEmpty) return 0.0;
        return double.tryParse(stringValue) ?? 0.0;
      } catch (_) {}

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void filterFournisseurs(String query) {
    if (query.length < 2 && query.isNotEmpty) return;

    setState(() {
      if (query.isEmpty) {
        _filteredFournisseurs = _fournisseurs.take(_pageSize).toList();
      } else {
        final filtered = _fournisseurs
            .where((fournisseur) => fournisseur.rsoc.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _filteredFournisseurs = filtered.take(_pageSize).toList();
      }
    });
  }

  void _showAllFournisseurs() {
    setState(() {
      _filteredFournisseurs = _fournisseurs.take(_pageSize).toList();
      _searchController.clear();
    });
    _applySort();
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _applySort();
  }

  void _applySort() {
    List<Frn> toSort =
        _filteredFournisseurs.isEmpty ? _fournisseurs.take(_pageSize).toList() : _filteredFournisseurs;

    if (_sortColumn != null) {
      toSort.sort((a, b) {
        dynamic aValue, bValue;
        switch (_sortColumn) {
          case 'rsoc':
            aValue = a.rsoc;
            bValue = b.rsoc;
            break;
          case 'soldes':
            aValue = a.soldes ?? 0;
            bValue = b.soldes ?? 0;
            break;
          case 'action':
            aValue = a.action ?? 'A';
            bValue = b.action ?? 'A';
            break;
          default:
            return 0;
        }

        int result;
        if (aValue is String && bValue is String) {
          result = aValue.compareTo(bValue);
        } else if (aValue is num && bValue is num) {
          result = aValue.compareTo(bValue);
        } else {
          result = aValue.toString().compareTo(bValue.toString());
        }

        return _sortAscending ? result : -result;
      });
    }

    setState(() {
      _filteredFournisseurs = toSort;
    });
  }

  void _goToFirst() {
    if (_filteredFournisseurs.isNotEmpty) {
      _selectFournisseur(_filteredFournisseurs.first);
    }
  }

  void _goToPrevious() {
    if (_selectedFournisseur != null && _filteredFournisseurs.isNotEmpty) {
      final currentIndex = _filteredFournisseurs.indexWhere((f) => f.rsoc == _selectedFournisseur?.rsoc);
      if (currentIndex > 0) {
        _selectFournisseur(_filteredFournisseurs[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedFournisseur != null && _filteredFournisseurs.isNotEmpty) {
      final currentIndex = _filteredFournisseurs.indexWhere((f) => f.rsoc == _selectedFournisseur?.rsoc);
      if (currentIndex < _filteredFournisseurs.length - 1) {
        _selectFournisseur(_filteredFournisseurs[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_filteredFournisseurs.isNotEmpty) {
      _selectFournisseur(_filteredFournisseurs.last);
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final isActive = _selectedFournisseur?.action == 'A';
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'create',
          child: Text('Créer', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'modify',
          child: Text('Modifier', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Supprimer', style: TextStyle(fontSize: 12)),
        ),
        if (_selectedFournisseur != null)
          PopupMenuItem(
            value: 'toggle_status',
            child: Text(
              isActive ? 'Désactiver' : 'Activer',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  void _handleContextMenuAction(String action) {
    switch (action) {
      case 'create':
        _showAddFournisseurModal();
        break;
      case 'modify':
        if (_selectedFournisseur != null) {
          _showAddFournisseurModal(fournisseur: _selectedFournisseur);
        }
        break;
      case 'delete':
        if (_selectedFournisseur != null) {
          _deleteFournisseur(_selectedFournisseur!);
        }
        break;
      case 'toggle_status':
        if (_selectedFournisseur != null) {
          _toggleFournisseurStatus(_selectedFournisseur!);
        }
        break;
    }
  }

  void _showAddFournisseurModal({Frn? fournisseur}) {
    showDialog(
      context: context,
      builder: (context) => AddFournisseurModal(fournisseur: fournisseur),
    ).then((_) => _loadFournisseurs());
  }

  Future<void> _deleteFournisseur(Frn fournisseur) async {
    try {
      await DatabaseService().database.deleteFournisseur(fournisseur.rsoc);
      await _loadFournisseurs();
      if (_selectedFournisseur?.rsoc == fournisseur.rsoc) {
        setState(() {
          _selectedFournisseur = null;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
    }
  }

  Future<void> _toggleFournisseurStatus(Frn fournisseur) async {
    try {
      final newStatus = fournisseur.action == 'A' ? 'D' : 'A';
      await DatabaseService().database.customUpdate(
        'UPDATE frns SET action = ? WHERE rsoc = ?',
        variables: [Variable.withString(newStatus), Variable.withString(fournisseur.rsoc)],
      );

      // Mettre à jour localement pour éviter de recharger toute la liste
      setState(() {
        final index = _fournisseurs.indexWhere((f) => f.rsoc == fournisseur.rsoc);
        if (index != -1) {
          _fournisseurs[index] = _fournisseurs[index].copyWith(action: Value(newStatus));
        }

        final filteredIndex = _filteredFournisseurs.indexWhere((f) => f.rsoc == fournisseur.rsoc);
        if (filteredIndex != -1) {
          _filteredFournisseurs[filteredIndex] =
              _filteredFournisseurs[filteredIndex].copyWith(action: Value(newStatus));
        }

        // Mettre à jour la sélection
        if (_selectedFournisseur?.rsoc == fournisseur.rsoc) {
          _selectedFournisseur = _selectedFournisseur!.copyWith(action: Value(newStatus));
        }
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Erreur lors du changement de statut: $e');
      }
    }
  }

  Future<void> _loadHistoriqueFournisseur(String rsocFournisseur) async {
    final historique = await DatabaseService().database.customSelect(
      'SELECT * FROM comptefrns WHERE frns = ? ORDER BY daty DESC LIMIT 50',
      variables: [Variable(rsocFournisseur)],
    ).get();

    setState(() {
      _historiqueFournisseur = historique
          .map((row) => Comptefrn(
                ref: row.read<String>('ref'),
                daty: row.read<DateTime?>('daty'),
                lib: row.read<String?>('lib'),
                numachats: row.read<String?>('numachats'),
                nfact: row.read<String?>('nfact'),
                refart: row.read<String?>('refart'),
                qe: row.read<double?>('qe'),
                pu: row.read<double?>('pu'),
                entres: row.read<double?>('entres'),
                sortie: row.read<double?>('sortie'),
                solde: row.read<double?>('solde'),
                frns: row.read<String?>('frns'),
                verification: row.read<String?>('verification'),
              ))
          .toList();
    });
  }

  Widget _buildHistoriqueCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 140,
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.history, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'HISTORIQUE DES MOUVEMENTS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_selectedFournisseur != null)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Solde: ${_formatMontant(_selectedFournisseur!.soldes ?? 0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[200]!, Colors.grey[300]!],
                ),
                border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'DATE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'LIBELLÉ',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'DÉBIT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'CRÉDIT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'SOLDE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _historiqueFournisseur.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun mouvement',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historiqueFournisseur.length,
                      itemExtent: 18,
                      itemBuilder: (context, index) {
                        final mouvement = _historiqueFournisseur[index];
                        return GestureDetector(
                          onTap: () => _showMovementDetails(mouvement),
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                              border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      mouvement.daty?.toString().substring(0, 10) ?? '',
                                      style: const TextStyle(fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      mouvement.lib ?? '',
                                      style: const TextStyle(fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      (mouvement.sortie ?? 0) > 0 ? _formatMontant(mouvement.sortie!) : '',
                                      style: const TextStyle(fontSize: 9),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      (mouvement.entres ?? 0) > 0 ? _formatMontant(mouvement.entres!) : '',
                                      style: const TextStyle(fontSize: 9),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      _formatMontant(mouvement.solde ?? 0),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            (mouvement.solde ?? 0) >= 0 ? Colors.green[700] : Colors.red[700],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMontant(double montant) {
    return _numberFormat.format(montant.round());
  }

  void _showMovementDetails(Comptefrn mouvement) {
    showDialog(
      context: context,
      builder: (context) => _MovementDetailsDialog(mouvement: mouvement),
    );
  }

  void _handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocus.requestFocus();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showAddFournisseurModal();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyM) {
        if (_selectedFournisseur != null) {
          _showAddFournisseurModal(fournisseur: _selectedFournisseur);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        if (_selectedFournisseur != null) {
          _deleteFournisseur(_selectedFournisseur!);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
}

class _MovementDetailsDialog extends StatefulWidget {
  final Comptefrn mouvement;

  const _MovementDetailsDialog({required this.mouvement});

  @override
  State<_MovementDetailsDialog> createState() => _MovementDetailsDialogState();
}

class _MovementDetailsDialogState extends State<_MovementDetailsDialog> with TabNavigationMixin {
  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingArticles = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    if (widget.mouvement.numachats?.isNotEmpty == true) {
      _loadArticles();
    }
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoadingArticles = true);
    try {
      debugPrint('Loading articles for numachats: ${widget.mouvement.numachats}');
      final result = await DatabaseService().database.customSelect(
        'SELECT * FROM achats WHERE numachats = ?',
        variables: [Variable(widget.mouvement.numachats!)],
      ).get();

      debugPrint('Found ${result.length} articles');

      setState(() {
        _articles = result
            .map((row) => {
                  'refart': row.read<String?>('refart') ?? '',
                  'design': row.read<String?>('design') ?? '',
                  'qte': row.read<double?>('qte') ?? 0.0,
                  'pu': row.read<double?>('pu') ?? 0.0,
                  'montant': row.read<double?>('montant') ?? 0.0,
                })
            .toList();
        _isLoadingArticles = false;
      });

      debugPrint('Articles loaded: $_articles');
    } catch (e) {
      debugPrint('Error loading articles: $e');
      setState(() => _isLoadingArticles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'DÉTAILS DU MOUVEMENT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDetailRow('Référence', widget.mouvement.ref),
                    _buildDetailRow('Date', widget.mouvement.daty?.toString().substring(0, 10) ?? ''),
                    _buildDetailRow('Libellé', widget.mouvement.lib ?? ''),
                    if (widget.mouvement.numachats?.isNotEmpty == true)
                      _buildDetailRow('N° Achat', widget.mouvement.numachats!),
                    if (widget.mouvement.nfact?.isNotEmpty == true)
                      _buildDetailRow('N° Facture', widget.mouvement.nfact!),
                    if (widget.mouvement.refart?.isNotEmpty == true)
                      _buildDetailRow('Référence Article', widget.mouvement.refart!),
                    if ((widget.mouvement.qe ?? 0) > 0)
                      _buildDetailRow('Quantité', widget.mouvement.qe!.toString()),
                    if ((widget.mouvement.pu ?? 0) > 0)
                      _buildDetailRow('Prix Unitaire', _formatMontant(widget.mouvement.pu!)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Débit:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                (widget.mouvement.sortie ?? 0) > 0
                                    ? _formatMontant(widget.mouvement.sortie!)
                                    : '0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Crédit:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                (widget.mouvement.entres ?? 0) > 0
                                    ? _formatMontant(widget.mouvement.entres!)
                                    : '0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Solde:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                _formatMontant(widget.mouvement.solde ?? 0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: (widget.mouvement.solde ?? 0) >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.mouvement.verification?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Vérification', widget.mouvement.verification!),
                    ],
                    if (widget.mouvement.numachats?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'ARTICLES ACHETÉS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildArticlesSection(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    debugPrint(
        'Building articles section. Loading: $_isLoadingArticles, Articles count: ${_articles.length}');

    if (_isLoadingArticles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_articles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Aucun article trouvé pour l\'achat ${widget.mouvement.numachats}',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('RÉFÉRENCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 3,
                    child: Text('DÉSIGNATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    child: Text('QTÉ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('P.U.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.right)),
                Expanded(
                    child: Text('MONTANT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...List.generate(_articles.length, (index) {
            final article = _articles[index];
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      article['refart'],
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      article['design'],
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      article['qte'].toString(),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatMontant(article['pu']),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatMontant(article['montant']),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMontant(double montant) {
    return _numberFormat.format(montant.round());
  }
}
