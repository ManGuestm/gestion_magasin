import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'add_banque_modal.dart';
import '../common/tab_navigation_widget.dart';

class BanquesModal extends StatefulWidget {
  const BanquesModal({super.key});

  @override
  State<BanquesModal> createState() => _BanquesModalState();
}

class _BanquesModalState extends State<BanquesModal> with TabNavigationMixin {
  List<BqData> _banques = [];
  List<BqData> _filteredBanques = [];
  final TextEditingController _searchController = TextEditingController();
  BqData? _selectedBanque;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBanques();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Container(
            width: 800,
            height: 500,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
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
      ),
    ),);
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          const Text(
            'BANQUE',
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
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBanques.length,
                itemExtent: 18,
                itemBuilder: (context, index) {
                  final banque = _filteredBanques[index];
                  final isSelected = _selectedBanque?.code == banque.code;
                  return GestureDetector(
                    onTap: () => _selectBanque(banque),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[600] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            padding: const EdgeInsets.only(left: 4),
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey, width: 1),
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              banque.code,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.centerLeft,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey, width: 1),
                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              child: Text(
                                banque.intitule ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.centerLeft,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey, width: 1),
                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              child: Text(
                                banque.nCompte ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              banque.soldes?.toStringAsFixed(2) ?? '0.00',
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
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: const Text(
              'CODE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'INTITULE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'N° COMPTE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: const Text(
              'SOLDE',
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
                onChanged: _filterBanques,
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
              onPressed: _showAllBanques,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Afficher tous',
                style: TextStyle(fontSize: 9, color: Colors.black),
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

  void _selectBanque(BqData banque) {
    setState(() {
      _selectedBanque = banque;
    });
  }

  Future<void> _loadBanques() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final banques = await DatabaseService().database.getAllBqs();
    setState(() {
      _banques = banques;
      _filteredBanques = banques;
      _isLoading = false;
    });
  }

  void _filterBanques(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanques = _banques;
      } else {
        _filteredBanques = _banques
            .where((banque) =>
                banque.code.toLowerCase().contains(query.toLowerCase()) ||
                (banque.intitule?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _showAllBanques() {
    setState(() {
      _filteredBanques = _banques;
      _searchController.clear();
    });
  }

  void _goToFirst() {
    if (_filteredBanques.isNotEmpty) {
      _selectBanque(_filteredBanques.first);
    }
  }

  void _goToPrevious() {
    if (_selectedBanque != null && _filteredBanques.isNotEmpty) {
      final currentIndex = _filteredBanques.indexWhere((b) => b.code == _selectedBanque?.code);
      if (currentIndex > 0) {
        _selectBanque(_filteredBanques[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedBanque != null && _filteredBanques.isNotEmpty) {
      final currentIndex = _filteredBanques.indexWhere((b) => b.code == _selectedBanque?.code);
      if (currentIndex < _filteredBanques.length - 1) {
        _selectBanque(_filteredBanques[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_filteredBanques.isNotEmpty) {
      _selectBanque(_filteredBanques.last);
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
        _showAddBanqueModal();
        break;
      case 'modify':
        if (_selectedBanque != null) {
          _showAddBanqueModal(banque: _selectedBanque);
        }
        break;
      case 'delete':
        if (_selectedBanque != null) {
          _deleteBanque(_selectedBanque!);
        }
        break;
    }
  }

  void _showAddBanqueModal({BqData? banque}) {
    showDialog(
      context: context,
      builder: (context) => AddBanqueModal(banque: banque),
    ).then((_) => _loadBanques());
  }

  Future<void> _deleteBanque(BqData banque) async {
    try {
      await DatabaseService().database.deleteBq(banque.code);
      await _loadBanques();
      if (_selectedBanque?.code == banque.code) {
        setState(() {
          _selectedBanque = null;
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
