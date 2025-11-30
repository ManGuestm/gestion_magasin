import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class JournalCaisseModal extends StatefulWidget {
  const JournalCaisseModal({super.key});

  @override
  State<JournalCaisseModal> createState() => _JournalCaisseModalState();
}

class _JournalCaisseModalState extends State<JournalCaisseModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _mouvements = [];
  bool _isLoading = true;
  int? _selectedRowIndex;
  final FocusNode _keyboardFocusNode = FocusNode();
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  // Filtrage avancé
  bool _showAdvancedFilters = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _libelleFilter = '';
  double? _debitMin;
  double? _debitMax;
  double? _creditMin;
  double? _creditMax;

  final TextEditingController _libelleController = TextEditingController();
  final TextEditingController _debitMinController = TextEditingController();
  final TextEditingController _debitMaxController = TextEditingController();
  final TextEditingController _creditMinController = TextEditingController();
  final TextEditingController _creditMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMouvements();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  Future<void> _loadMouvements() async {
    try {
      final mouvements = await _databaseService.database.getAllCaisses();
      setState(() {
        _mouvements = mouvements
          ..sort((a, b) => (a.daty ?? DateTime.now()).compareTo(b.daty ?? DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<CaisseData> get _filteredMouvements {
    List<CaisseData> filtered = List.from(_mouvements);

    // Filtrage par recherche simple
    if (_searchText.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              (m.lib?.toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
              (m.daty?.toString().contains(_searchText) ?? false))
          .toList();
    }

    // Filtrage avancé
    if (_dateDebut != null) {
      filtered = filtered
          .where((m) => m.daty != null && m.daty!.isAfter(_dateDebut!.subtract(const Duration(days: 1))))
          .toList();
    }

    if (_dateFin != null) {
      filtered = filtered
          .where((m) => m.daty != null && m.daty!.isBefore(_dateFin!.add(const Duration(days: 1))))
          .toList();
    }

    if (_libelleFilter.isNotEmpty) {
      filtered = filtered
          .where((m) => m.lib?.toLowerCase().contains(_libelleFilter.toLowerCase()) ?? false)
          .toList();
    }

    if (_debitMin != null) {
      filtered = filtered.where((m) => (m.debit ?? 0) >= _debitMin!).toList();
    }

    if (_debitMax != null) {
      filtered = filtered.where((m) => (m.debit ?? 0) <= _debitMax!).toList();
    }

    if (_creditMin != null) {
      filtered = filtered.where((m) => (m.credit ?? 0) >= _creditMin!).toList();
    }

    if (_creditMax != null) {
      filtered = filtered.where((m) => (m.credit ?? 0) <= _creditMax!).toList();
    }

    // Trier par date décroissante pour l'affichage
    filtered.sort((a, b) => (b.daty ?? DateTime.now()).compareTo(a.daty ?? DateTime.now()));
    return filtered;
  }

  double get _totalDebit {
    return _filteredMouvements.fold(0.0, (sum, m) => sum + (m.debit ?? 0));
  }

  double get _totalCredit {
    return _filteredMouvements.fold(0.0, (sum, m) => sum + (m.credit ?? 0));
  }

  double get _soldeActuel {
    if (_mouvements.isEmpty) return 0;
    // Prendre le solde du mouvement le plus récent chronologiquement
    final mouvementsOrdonnes = List<CaisseData>.from(_mouvements)
      ..sort((a, b) => (a.daty ?? DateTime.now()).compareTo(b.daty ?? DateTime.now()));
    return mouvementsOrdonnes.last.soldes ?? 0;
  }

  void _handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        _loadMouvements();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMouvements = _filteredMouvements;

    return PopScope(
      canPop: false,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKeyboardShortcut,
        child: Dialog(
          backgroundColor: Colors.grey[100],
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header avec titre et bouton fermer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Journal de caisse',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filteredMouvements.length} mouvements',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        tooltip: 'Fermer (Échap)',
                      ),
                    ],
                  ),
                ),

                // Barre de recherche et actions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher dans les mouvements...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAdvancedFilters = !_showAdvancedFilters;
                          });
                        },
                        icon:
                            Icon(_showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list, size: 18),
                        label: const Text('Filtres'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showAdvancedFilters ? Colors.orange : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Actualiser (F5)',
                        child: ElevatedButton.icon(
                          onPressed: _loadMouvements,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Actualiser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Panneau de filtres avancés
                if (_showAdvancedFilters) _buildAdvancedFilters(),

                // Résumé des totaux
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Débits',
                          NumberUtils.formatNumber(_totalDebit),
                          Colors.red,
                          Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Crédits',
                          NumberUtils.formatNumber(_totalCredit),
                          Colors.green,
                          Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Solde Actuel',
                          NumberUtils.formatNumber(_soldeActuel),
                          _soldeActuel >= 0 ? Colors.green : Colors.red,
                          Icons.account_balance,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tableau des mouvements
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Chargement des mouvements...'),
                            ],
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // En-tête du tableau
                              Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade600, Colors.blue.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildHeaderCell('Date', flex: 2),
                                    _buildHeaderCell('Libellé', flex: 4),
                                    _buildHeaderCell('Débit', flex: 2),
                                    _buildHeaderCell('Crédit', flex: 2),
                                    _buildHeaderCell('Solde', flex: 2),
                                  ],
                                ),
                              ),
                              // Contenu du tableau
                              Expanded(
                                child: filteredMouvements.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchText.isEmpty
                                                  ? 'Aucun mouvement de caisse'
                                                  : 'Aucun résultat pour "$_searchText"',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (_searchText.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              TextButton(
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchText = '';
                                                  });
                                                },
                                                child: const Text('Effacer la recherche'),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredMouvements.length,
                                        itemBuilder: (context, index) {
                                          final mouvement = filteredMouvements[index];
                                          final isSelected = _selectedRowIndex == index;

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedRowIndex = isSelected ? null : index;
                                              });
                                            },
                                            child: Container(
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.blue.shade50
                                                    : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade200,
                                                    width: 0.5,
                                                  ),
                                                  left: isSelected
                                                      ? BorderSide(color: Colors.blue.shade400, width: 3)
                                                      : BorderSide.none,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildDataCell(
                                                    mouvement.daty != null
                                                        ? app_date.AppDateUtils.formatDate(mouvement.daty!)
                                                        : 'N/A',
                                                    flex: 2,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  _buildDataCell(
                                                    mouvement.lib ?? 'N/A',
                                                    flex: 4,
                                                    style: const TextStyle(fontSize: 12),
                                                    alignment: Alignment.centerLeft,
                                                  ),
                                                  _buildDataCell(
                                                    (mouvement.debit ?? 0) > 0
                                                        ? NumberUtils.formatNumber(mouvement.debit!)
                                                        : '-',
                                                    flex: 2,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: (mouvement.debit ?? 0) > 0
                                                          ? Colors.red.shade700
                                                          : Colors.grey,
                                                      fontWeight: (mouvement.debit ?? 0) > 0
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  _buildDataCell(
                                                    (mouvement.credit ?? 0) > 0
                                                        ? NumberUtils.formatNumber(mouvement.credit!)
                                                        : '-',
                                                    flex: 2,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: (mouvement.credit ?? 0) > 0
                                                          ? Colors.green.shade700
                                                          : Colors.grey,
                                                      fontWeight: (mouvement.credit ?? 0) > 0
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  _buildDataCell(
                                                    NumberUtils.formatNumber(mouvement.soldes ?? 0),
                                                    flex: 2,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: (mouvement.soldes ?? 0) >= 0
                                                          ? Colors.green.shade800
                                                          : Colors.red.shade800,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    int flex = 1,
    TextStyle? style,
    Alignment alignment = Alignment.center,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: alignment,
        child: Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Plage de dates
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Période', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _dateDebut != null
                                    ? '${_dateDebut!.day.toString().padLeft(2, '0')}/${_dateDebut!.month.toString().padLeft(2, '0')}/${_dateDebut!.year}'
                                    : 'Date début',
                                style: TextStyle(
                                  color: _dateDebut != null ? Colors.black : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _dateFin != null
                                    ? '${_dateFin!.day.toString().padLeft(2, '0')}/${_dateFin!.month.toString().padLeft(2, '0')}/${_dateFin!.year}'
                                    : 'Date fin',
                                style: TextStyle(
                                  color: _dateFin != null ? Colors.black : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Libellé
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Libellé', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _libelleController,
                      decoration: const InputDecoration(
                        hintText: 'Filtrer par libellé',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        setState(() {
                          _libelleFilter = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Débit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Débit', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _debitMinController,
                            decoration: const InputDecoration(
                              hintText: 'Min',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _debitMin = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _debitMaxController,
                            decoration: const InputDecoration(
                              hintText: 'Max',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _debitMax = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Crédit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crédit', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _creditMinController,
                            decoration: const InputDecoration(
                              hintText: 'Min',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _creditMin = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _creditMaxController,
                            decoration: const InputDecoration(
                              hintText: 'Max',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _creditMax = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Bouton effacer
              Column(
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Effacer', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _dateDebut = null;
      _dateFin = null;
      _libelleFilter = '';
      _debitMin = null;
      _debitMax = null;
      _creditMin = null;
      _creditMax = null;
    });

    _libelleController.clear();
    _debitMinController.clear();
    _debitMaxController.clear();
    _creditMinController.clear();
    _creditMaxController.clear();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _searchController.dispose();
    _libelleController.dispose();
    _debitMinController.dispose();
    _debitMaxController.dispose();
    _creditMinController.dispose();
    _creditMaxController.dispose();
    super.dispose();
  }
}
