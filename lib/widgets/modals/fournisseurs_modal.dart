import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../mixins/form_navigation_mixin.dart';
import '../../widgets/common/base_modal.dart';
import 'add_fournisseur_modal.dart';
import '../common/tab_navigation_widget.dart';

class FournisseursModal extends StatefulWidget {
  const FournisseursModal({super.key});

  @override
  State<FournisseursModal> createState() => _FournisseursModalState();
}

class _FournisseursModalState extends State<FournisseursModal> with FormNavigationMixin {
  List<Frn> _fournisseurs = [];
  List<Frn> _filteredFournisseurs = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  Frn? _selectedFournisseur;
  List<Comptefrn> _historiqueFournisseur = [];
  final int _pageSize = 100;
  bool _isLoading = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes with tab navigation
    _searchFocus = createFocusNode();

    _searchFocus = createFocusNode();
    _loadFournisseurs();
  }

  void _selectFournisseur(Frn fournisseur) {
    setState(() {
      _selectedFournisseur = fournisseur;
    });
    _loadHistoriqueFournisseur(fournisseur.rsoc);
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Fournisseurs',
      width: AppConstants.defaultModalWidth,
      height: AppConstants.defaultModalHeight,
      onNew: () => _showAddFournisseurModal(),
      onDelete: () => _selectedFournisseur != null ? _deleteFournisseur(_selectedFournisseur!) : null,
      onSearch: () => _searchFocus.requestFocus(),
      onRefresh: _loadFournisseurs,
      content: GestureDetector(
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Column(
          children: [
            _buildContent(),
            _buildHistoriqueSection(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _buildModernHeader(),
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
                          itemExtent: 24,
                          itemBuilder: (context, index) {
                            final fournisseur = _filteredFournisseurs[index];
                            final isSelected = _selectedFournisseur?.rsoc == fournisseur.rsoc;
                            return _buildModernRow(fournisseur, isSelected, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('RAISON SOCIALE', flex: 4),
          _buildHeaderCell('SOLDES', flex: 2),
          _buildHeaderCell('ACTION', width: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int? flex, double? width}) {
    Widget cell = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
  }

  Widget _buildModernRow(Frn fournisseur, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectFournisseur(fournisseur),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
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
            ),
            _buildDataCell(
              fournisseur.action ?? 'A',
              width: 80,
              isSelected: isSelected,
              alignment: Alignment.center,
            ),
          ],
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
  }) {
    Widget cell = Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.blue[800] : Colors.black87,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
            child: SizedBox(
              height: 20,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: Autocomplete<Frn>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty || textEditingValue.text == ' ') {
                      return _fournisseurs.take(100);
                    }
                    return _fournisseurs.where((fournisseur) {
                      return fournisseur.rsoc.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    }).take(100);
                  },
                  displayStringForOption: (fournisseur) => fournisseur.rsoc,
                  onSelected: (fournisseur) => _selectFournisseur(fournisseur),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                        hintText: 'Rechercher fournisseur...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                        prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey[500]),
                      ),
                      onTap: () {
                        if (controller.text.isEmpty) {
                          controller.text = ' ';
                          controller.selection = TextSelection.fromPosition(
                            const TextPosition(offset: 0),
                          );
                          Future.delayed(const Duration(milliseconds: 50), () {
                            controller.clear();
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[200]!],
              ),
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _showAllFournisseurs,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Afficher tous',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
        _filteredFournisseurs = fournisseurs.take(_pageSize).toList();
        _isLoading = false;
      });

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

  Widget _buildHistoriqueSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[500]!],
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'HISTORIQUE DE SOLDE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_selectedFournisseur != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Solde dû: ${_formatMontant(_selectedFournisseur!.soldes ?? 0)}',
                      style: const TextStyle(
                        fontSize: 10,
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

  @override
  void dispose() {
    _searchController.dispose();
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
