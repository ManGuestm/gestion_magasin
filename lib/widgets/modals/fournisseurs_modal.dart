import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'add_fournisseur_modal.dart';

class FournisseursModal extends StatefulWidget {
  const FournisseursModal({super.key});

  @override
  State<FournisseursModal> createState() => _FournisseursModalState();
}

class _FournisseursModalState extends State<FournisseursModal> {
  List<Frn> _fournisseurs = [];
  List<Frn> _filteredFournisseurs = [];
  final TextEditingController _searchController = TextEditingController();
  Frn? _selectedFournisseur;
  final int _pageSize = 100;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: GestureDetector(
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Container(
          width: 900,
          height: 600,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildHeader(),
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
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'FOURNISSEURS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredFournisseurs.length,
                itemExtent: 18,
                itemBuilder: (context, index) {
                  final fournisseur = _filteredFournisseurs[index];
                  final isSelected = _selectedFournisseur?.rsoc == fournisseur.rsoc;
                  return GestureDetector(
                    onTap: () => _selectFournisseur(fournisseur),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.only(left: 4),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey[400]!, width: 1),
                                  bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                                ),
                              ),
                              child: Text(
                                fournisseur.rsoc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey[400]!, width: 1),
                                  bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                                ),
                              ),
                              child: Text(
                                fournisseur.soldes?.toStringAsFixed(2) ?? '.00',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                              ),
                            ),
                            child: Text(
                              fournisseur.action ?? 'A',
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

  Widget _buildTableHeader() {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.orange[300],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey[400]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                ),
              ),
              child: const Text(
                'RAISON SOCIALE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey[400]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                ),
              ),
              child: const Text(
                'SOLDES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
            ),
            child: const Text(
              'ACTION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
                onChanged: _filterFournisseurs,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: _showAllFournisseurs,
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

  void _selectFournisseur(Frn fournisseur) {
    setState(() {
      _selectedFournisseur = fournisseur;
    });
  }

  Future<void> _loadFournisseurs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final fournisseurs = await DatabaseService().database.getAllFournisseurs();
    setState(() {
      _fournisseurs = fournisseurs;
      _filteredFournisseurs = fournisseurs.take(_pageSize).toList();
      _isLoading = false;
    });
  }

  void _filterFournisseurs(String query) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
