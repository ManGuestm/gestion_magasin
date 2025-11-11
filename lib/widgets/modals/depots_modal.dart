import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class DepotsModal extends StatefulWidget {
  const DepotsModal({super.key});

  @override
  State<DepotsModal> createState() => _DepotsModalState();
}

class _DepotsModalState extends State<DepotsModal> {
  List<Depot> _depots = [];
  List<Depot> _filteredDepots = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Depot? _selectedDepot;

  @override
  void initState() {
    super.initState();
    _loadDepots();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: GestureDetector(
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          width: 500,
          height: 400,
          child: Column(
            children: [
              _buildHeader(),
              _buildTitle(),
              _buildContent(),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Row(
        children: [
          const Text(
            'DEPOTS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[300],
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: const Text(
        'DEPOTS',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          children: [
            Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    child: Icon(Icons.arrow_right, size: 16),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        isDense: true,
                      ),
                      onFieldSubmitted: (_) => _addDepot(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredDepots.length,
                itemBuilder: (context, index) {
                  final depot = _filteredDepots[index];
                  final isSelected = _selectedDepot?.depots == depot.depots;
                  return GestureDetector(
                    onTap: () => _selectDepot(depot),
                    child: Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: isSelected
                                ? const Icon(Icons.arrow_right, size: 16, color: Colors.white)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              depot.depots,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.black,
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

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildNavButton(Icons.first_page, _goToFirst),
          _buildNavButton(Icons.chevron_left, _goToPrevious),
          _buildNavButton(Icons.chevron_right, _goToNext),
          _buildNavButton(Icons.last_page, _goToLast),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                color: Colors.white,
              ),
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  isDense: true,
                ),
                onChanged: _filterDepots,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 20,
            // width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: _searchDepots,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Afficher tous',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Container(
          //   height: 24,
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[300],
          //     border: Border.all(color: Colors.grey[600]!),
          //   ),
          //   child: TextButton(
          //     onPressed: () => Navigator.of(context).pop(),
          //     style: TextButton.styleFrom(
          //       padding: EdgeInsets.zero,
          //       minimumSize: Size.zero,
          //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     ),
          //     child: const Text(
          //       'Fermer',
          //       style: TextStyle(fontSize: 12, color: Colors.black),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.grey[200],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
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
    super.dispose();
  }
}
