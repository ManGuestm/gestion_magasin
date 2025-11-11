import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'add_plan_compte_modal.dart';

class PlanComptesModal extends StatefulWidget {
  const PlanComptesModal({super.key});

  @override
  State<PlanComptesModal> createState() => _PlanComptesModalState();
}

class _PlanComptesModalState extends State<PlanComptesModal> {
  List<CaData> _comptes = [];
  List<CaData> _filteredComptes = [];
  final TextEditingController _searchController = TextEditingController();
  CaData? _selectedCompte;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComptes();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
                _buildFooter(),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
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
            'PLAN DE COMPTES',
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
                itemCount: _filteredComptes.length,
                itemExtent: 18,
                itemBuilder: (context, index) {
                  final compte = _filteredComptes[index];
                  final isSelected = _selectedCompte?.code == compte.code;
                  return GestureDetector(
                    onTap: () => _selectCompte(compte),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[600] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            padding: const EdgeInsets.only(left: 4),
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey, width: 1),
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              compte.code,
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
                                compte.intitule ?? '',
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
                                compte.compte ?? '',
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
                              compte.soldes?.toStringAsFixed(2) ?? '0.00',
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
            width: 80,
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
                'CLASSE',
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
              'MONTANT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    double totalProduits =
        _filteredComptes.where((c) => c.compte == 'Produits').fold(0.0, (sum, c) => sum + (c.soldes ?? 0.0));

    double totalCharges =
        _filteredComptes.where((c) => c.compte == 'Charges').fold(0.0, (sum, c) => sum + (c.soldes ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          Text(
            'TOTAL DES PRODUITS:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          const SizedBox(width: 20),
          Text(
            totalProduits.toStringAsFixed(2),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          const SizedBox(width: 40),
          Text(
            'TOTAL DES CHARGES:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          const SizedBox(width: 20),
          Text(
            totalCharges.toStringAsFixed(2),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
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
                onChanged: _filterComptes,
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
              onPressed: _showAllComptes,
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

  void _selectCompte(CaData compte) {
    setState(() {
      _selectedCompte = compte;
    });
  }

  Future<void> _loadComptes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final comptes = await DatabaseService().database.getAllCas();
    setState(() {
      _comptes = comptes;
      _filteredComptes = comptes;
      _isLoading = false;
    });
  }

  void _filterComptes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredComptes = _comptes;
      } else {
        _filteredComptes = _comptes
            .where((compte) =>
                compte.code.toLowerCase().contains(query.toLowerCase()) ||
                (compte.intitule?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _showAllComptes() {
    setState(() {
      _filteredComptes = _comptes;
      _searchController.clear();
    });
  }

  void _goToFirst() {
    if (_filteredComptes.isNotEmpty) {
      _selectCompte(_filteredComptes.first);
    }
  }

  void _goToPrevious() {
    if (_selectedCompte != null && _filteredComptes.isNotEmpty) {
      final currentIndex = _filteredComptes.indexWhere((c) => c.code == _selectedCompte?.code);
      if (currentIndex > 0) {
        _selectCompte(_filteredComptes[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedCompte != null && _filteredComptes.isNotEmpty) {
      final currentIndex = _filteredComptes.indexWhere((c) => c.code == _selectedCompte?.code);
      if (currentIndex < _filteredComptes.length - 1) {
        _selectCompte(_filteredComptes[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_filteredComptes.isNotEmpty) {
      _selectCompte(_filteredComptes.last);
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
        _showAddCompteModal();
        break;
      case 'modify':
        if (_selectedCompte != null) {
          _showAddCompteModal(compte: _selectedCompte);
        }
        break;
      case 'delete':
        if (_selectedCompte != null) {
          _deleteCompte(_selectedCompte!);
        }
        break;
    }
  }

  void _showAddCompteModal({CaData? compte}) {
    showDialog(
      context: context,
      builder: (context) => AddPlanCompteModal(compte: compte),
    ).then((_) => _loadComptes());
  }

  Future<void> _deleteCompte(CaData compte) async {
    try {
      await DatabaseService().database.deleteCa(compte.code);
      await _loadComptes();
      if (_selectedCompte?.code == compte.code) {
        setState(() {
          _selectedCompte = null;
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
