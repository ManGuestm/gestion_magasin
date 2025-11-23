import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class DepotsModal extends StatefulWidget {
  const DepotsModal({super.key});

  @override
  State<DepotsModal> createState() => _DepotsModalState();
}

class _DepotsModalState extends State<DepotsModal> with TabNavigationMixin {
  List<Depot> _depots = [];
  List<Depot> _filteredDepots = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _focusNode;
  Depot? _selectedDepot;

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes with tab navigation
    _focusNode = createFocusNode();

    _loadDepots();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              width: 600,
              height: 500,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildContent(),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
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
              Icons.home_work,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Gestion des Dépôts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section d'ajout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Ajouter un nouveau dépôt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Nom du dépôt',
                      prefixIcon: const Icon(Icons.home_work, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade600),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onFieldSubmitted: (_) => _addDepot(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Liste des dépôts
            Row(
              children: [
                Icon(Icons.list, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Liste des dépôts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredDepots.length} dépôt(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _filteredDepots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun dépôt trouvé',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDepots.length,
                        itemBuilder: (context, index) {
                          final depot = _filteredDepots[index];
                          final isSelected = _selectedDepot?.depots == depot.depots;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectDepot(depot),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected ? Border.all(color: Colors.blue.shade200) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.home_work,
                                          size: 16,
                                          color: isSelected ? Colors.white : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          depot.depots,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.blue.shade600,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Navigation buttons
          Row(
            children: [
              _buildNavButton(Icons.first_page, _goToFirst, 'Premier'),
              const SizedBox(width: 4),
              _buildNavButton(Icons.chevron_left, _goToPrevious, 'Précédent'),
              const SizedBox(width: 4),
              _buildNavButton(Icons.chevron_right, _goToNext, 'Suivant'),
              const SizedBox(width: 4),
              _buildNavButton(Icons.last_page, _goToLast, 'Dernier'),
            ],
          ),
          const SizedBox(width: 16),
          // Search field
          Expanded(
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un dépôt...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchDepots();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterDepots,
            ),
          ),
          const SizedBox(width: 12),
          // Action buttons
          ElevatedButton.icon(
            onPressed: _addDepot,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 16, color: Colors.grey.shade600),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  void _selectDepot(Depot depot) {
    setState(() {
      _selectedDepot = depot;
      _controller.text = depot.depots;
    });
  }

  Future<void> _addDepot() async {
    if (_controller.text.trim().isEmpty) return;

    try {
      await DatabaseService().database.insertDepot(
            DepotsCompanion(
              depots: drift.Value(_controller.text.trim()),
            ),
          );
      _controller.clear();
      await _loadDepots();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout: $e');
    }
  }

  Future<void> _loadDepots() async {
    final depots = await DatabaseService().database.getAllDepots();
    setState(() {
      _depots = depots;
      _filteredDepots = depots;
    });
  }

  void _filterDepots(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDepots = _depots;
      } else {
        _filteredDepots =
            _depots.where((depot) => depot.depots.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _searchDepots() {
    setState(() {
      _filteredDepots = _depots;
      _searchController.clear();
    });
  }

  void _goToFirst() {
    if (_depots.isNotEmpty) {
      _selectDepot(_depots.first);
    }
  }

  void _goToPrevious() {
    if (_selectedDepot != null && _depots.isNotEmpty) {
      final currentIndex = _depots.indexWhere((d) => d.depots == _selectedDepot?.depots);
      if (currentIndex > 0) {
        _selectDepot(_depots[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedDepot != null && _depots.isNotEmpty) {
      final currentIndex = _depots.indexWhere((d) => d.depots == _selectedDepot?.depots);
      if (currentIndex < _depots.length - 1) {
        _selectDepot(_depots[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_depots.isNotEmpty) {
      _selectDepot(_depots.last);
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
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
          value: 'delete',
          child: Text('Supprimer', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Text('Importer données ...', style: TextStyle(fontSize: 12)),
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
        _controller.clear();
        break;
      case 'delete':
        if (_selectedDepot != null) {
          _deleteDepot(_selectedDepot!);
        }
        break;
      case 'import':
        debugPrint('Import données');
        break;
    }
  }

  Future<void> _deleteDepot(Depot depot) async {
    try {
      await DatabaseService().database.deleteDepot(depot.depots);
      await _loadDepots();
      if (_selectedDepot?.depots == depot.depots) {
        setState(() {
          _selectedDepot = null;
          _controller.clear();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
