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
  final FocusNode _searchFocusNode = FocusNode();
  CaData? _selectedCompte;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComptes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Container(
            width: 900,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[500]!],
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_tree, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'PLAN DE COMPTES',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredComptes.length,
                      itemBuilder: (context, index) {
                        final compte = _filteredComptes[index];
                        final isSelected = _selectedCompte?.code == compte.code;
                        return InkWell(
                          onTap: () => _selectCompte(compte),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigo[50]
                                  : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                              border: Border(
                                left: isSelected
                                    ? BorderSide(color: Colors.indigo[600]!, width: 4)
                                    : BorderSide.none,
                                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    compte.code,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.indigo[700] : Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    compte.intitule ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.indigo[700] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    compte.compte ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected ? Colors.indigo[600] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${compte.soldes?.toStringAsFixed(2) ?? '0.00'} Ar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: (compte.soldes ?? 0) >= 0 ? Colors.green[700] : Colors.red[700],
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'CODE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'INTITULÉ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CLASSE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            width: 120,
            alignment: Alignment.centerRight,
            child: Text(
              'MONTANT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _filterComptes,
                decoration: InputDecoration(
                  hintText: 'Rechercher par code ou intitulé...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showAllComptes,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tout afficher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalCard('PRODUITS', totalProduits, Colors.green),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildTotalCard('CHARGES', totalCharges, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, MaterialColor color) {
    return Column(
      children: [
        Text(
          'TOTAL $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${amount.toStringAsFixed(2)} Ar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color[700],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              _buildNavButton(Icons.first_page, _goToFirst, 'Premier'),
              const SizedBox(width: 8),
              _buildNavButton(Icons.chevron_left, _goToPrevious, 'Précédent'),
              const SizedBox(width: 8),
              _buildNavButton(Icons.chevron_right, _goToNext, 'Suivant'),
              const SizedBox(width: 8),
              _buildNavButton(Icons.last_page, _goToLast, 'Dernier'),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddCompteModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: Colors.grey[700]),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
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
    _searchFocusNode.dispose();
    super.dispose();
  }
}
