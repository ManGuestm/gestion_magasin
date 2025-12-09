import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/client_categories.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import '../common/client_navigation_autocomplete.dart';
import '../common/tab_navigation_widget.dart';
import 'add_client_modal.dart';

class ClientsModal extends StatefulWidget {
  const ClientsModal({super.key});

  @override
  State<ClientsModal> createState() => _ClientsModalState();
}

class _ClientsModalState extends State<ClientsModal> with TabNavigationMixin {
  List<CltData> _clients = [];
  List<CltData> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode searchFocus;
  late final FocusNode _keyboardFocusNode;
  CltData? _selectedClient;
  List<ComptecltData> _historiqueClient = [];
  final int _pageSize = 100;
  bool _isLoading = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');
  String? _selectedCategoryFilter;
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes with tab navigation
    searchFocus = createFocusNode();
    _keyboardFocusNode = createFocusNode();

    _loadClients();

    // Focus automatique sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcut,
      child: PopScope(
        canPop: false,
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (AuthService().currentUser?.role == 'Administrateur' ||
                                    AuthService().currentUser?.role == 'Caisse')
                                  _buildFilterCard(),
                                const SizedBox(width: 12),
                                _buildSearchCard(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildClientsCard(),
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
            child: const Icon(Icons.people, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Clients',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Gérer et consulter vos clients',
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
        _buildHeaderButton(Icons.add, 'Nouveau', () => _showAddClientModal()),
        const SizedBox(width: 8),
        _buildHeaderButton(Icons.refresh, 'Actualiser', _loadClients),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          const Text(
            'Rechercher:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClientNavigationAutocomplete(
              clients: _clients,
              selectedClient: _selectedClient,
              onClientChanged: (client) {
                if (client != null) {
                  _selectClient(client);
                }
              },
              focusNode: searchFocus,
              hintText: 'Tapez le nom du client...',
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'Tapez le nom du client...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showAllClients,
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
    );
  }

  Widget _buildClientsCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildClientsHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredClients.length,
                itemExtent: 32,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  final isSelected = _selectedClient?.rsoc == client.rsoc;
                  return _buildClientRow(client, isSelected, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsHeader() {
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
          _buildSortableHeaderCell('STATUT', 'action', width: 100),
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

  Widget _buildClientRow(CltData client, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectClient(client),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[25]),
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildDataCell(
              client.rsoc,
              flex: 4,
              isSelected: isSelected,
              alignment: Alignment.centerLeft,
            ),
            _buildDataCell(
              _formatMontant(client.soldes ?? 0),
              flex: 2,
              isSelected: isSelected,
              alignment: Alignment.centerRight,
              isAmount: true,
              amount: client.soldes ?? 0,
            ),
            _buildStatusCell(client.action ?? 'A', isSelected),
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
          if (_selectedClient != null) ...[
            ElevatedButton.icon(
              onPressed: () => _showAddClientModal(client: _selectedClient),
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
              onPressed: () => _deleteClient(_selectedClient!),
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

  void _selectClient(CltData client) {
    setState(() {
      _selectedClient = client;
    });
    _loadHistoriqueClient(client.rsoc);
  }

  Future<void> _loadClients() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final clients = await DatabaseService().database.getAllClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('Erreur chargement clients: $e');
      setState(() {
        _clients = [];
        _isLoading = false;
      });
    }
  }

  void _showAllClients() {
    setState(() {
      final userRole = AuthService().currentUser?.role ?? '';
      if (userRole == 'Administrateur' || userRole == 'Caisse') {
        _selectedCategoryFilter = null;
      }
      _selectedClient = null;
    });
    _applyFilter();
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
    _applyFilter();
  }

  Widget _buildFilterCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          const Text(
            'Filtrer par catégorie:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategoryFilter,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              hint: const Text('Toutes les catégories', style: TextStyle(fontSize: 13)),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Toutes les catégories'),
                ),
                ...ClientCategory.values.map((category) => DropdownMenuItem(
                      value: category.label,
                      child: Text(category.label),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryFilter = value;
                  _applyFilter();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    List<CltData> filtered = _clients;

    final userRole = AuthService().currentUser?.role ?? '';

    if (userRole == 'Vendeur') {
      // Vendeur ne voit que les clients Magasin
      filtered = filtered.where((client) => client.categorie == ClientCategory.magasin.label).toList();
    } else if (userRole == 'Administrateur' || userRole == 'Caisse') {
      // Admin/Caisse peuvent filtrer par catégorie
      if (_selectedCategoryFilter != null) {
        filtered = filtered.where((client) => client.categorie == _selectedCategoryFilter).toList();
      }
    }

    // Appliquer le tri
    if (_sortColumn != null) {
      filtered.sort((a, b) {
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
      _filteredClients = filtered.take(_pageSize).toList();
    });
  }

  void _goToFirst() {
    if (_filteredClients.isNotEmpty) {
      _selectClient(_filteredClients.first);
    }
  }

  void _goToPrevious() {
    if (_selectedClient != null && _filteredClients.isNotEmpty) {
      final currentIndex = _filteredClients.indexWhere((c) => c.rsoc == _selectedClient?.rsoc);
      if (currentIndex > 0) {
        _selectClient(_filteredClients[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedClient != null && _filteredClients.isNotEmpty) {
      final currentIndex = _filteredClients.indexWhere((c) => c.rsoc == _selectedClient?.rsoc);
      if (currentIndex < _filteredClients.length - 1) {
        _selectClient(_filteredClients[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_filteredClients.isNotEmpty) {
      _selectClient(_filteredClients.last);
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final isActive = _selectedClient?.action == 'A';
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
        if (_selectedClient != null)
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
        _showAddClientModal();
        break;
      case 'modify':
        if (_selectedClient != null) {
          _showAddClientModal(client: _selectedClient);
        }
        break;
      case 'delete':
        if (_selectedClient != null) {
          _deleteClient(_selectedClient!);
        }
        break;
      case 'toggle_status':
        if (_selectedClient != null) {
          _toggleClientStatus(_selectedClient!);
        }
        break;
    }
  }

  void _showAddClientModal({CltData? client}) {
    showDialog(
      context: context,
      builder: (context) => AddClientModal(
        client: client,
        tousDepots: AuthService().currentUser?.role != 'Vendeur',
      ),
    ).then((_) => _loadClients());
  }

  Future<void> _deleteClient(CltData client) async {
    try {
      await DatabaseService().database.deleteClient(client.rsoc);
      await _loadClients();
      if (_selectedClient?.rsoc == client.rsoc) {
        setState(() {
          _selectedClient = null;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Erreur lors de la suppression: $e');
      }
    }
  }

  Future<void> _toggleClientStatus(CltData client) async {
    try {
      final newStatus = client.action == 'A' ? 'D' : 'A';
      await DatabaseService().database.customUpdate(
        'UPDATE clt SET action = ? WHERE rsoc = ?',
        variables: [Variable(newStatus), Variable(client.rsoc)],
      );
      await _loadClients();
      // Maintenir la sélection du client après la mise à jour
      final updatedClient = _clients.firstWhere((c) => c.rsoc == client.rsoc);
      _selectClient(updatedClient);
    } catch (e) {
      if (mounted) {
        debugPrint('Erreur lors du changement de statut: $e');
      }
    }
  }

  Future<void> _loadHistoriqueClient(String rsocClient) async {
    try {
      final historique = await DatabaseService().database.customSelect(
        'SELECT * FROM compteclt WHERE clt = ? ORDER BY daty DESC LIMIT 50',
        variables: [Variable(rsocClient)],
      ).get();

      setState(() {
        _historiqueClient = historique
            .map((row) {
              try {
                DateTime? daty;
                final datyStr = row.readNullable<String>('daty');
                if (datyStr != null) {
                  try {
                    daty = DateTime.parse(datyStr);
                  } catch (e) {
                    debugPrint('Erreur parsing date: $datyStr - $e');
                    daty = null;
                  }
                }

                return ComptecltData(
                  ref: row.read<String>('ref'),
                  daty: daty,
                  lib: row.readNullable<String>('lib'),
                  numventes: row.readNullable<String>('numventes'),
                  nfact: row.readNullable<String>('nfact'),
                  refart: row.readNullable<String>('refart'),
                  qs: row.readNullable<double>('qs'),
                  pus: row.readNullable<double>('pus'),
                  entres: row.readNullable<double>('entres'),
                  sorties: row.readNullable<double>('sorties'),
                  solde: row.readNullable<double>('solde'),
                  clt: row.readNullable<String>('clt'),
                  verification: row.readNullable<String>('verification'),
                );
              } catch (e) {
                debugPrint('Erreur lecture ligne historique: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<ComptecltData>()
            .toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      setState(() {
        _historiqueClient = [];
      });
    }
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
                  if (_selectedClient != null)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Solde: ${_formatMontant(_selectedClient!.soldes ?? 0)}',
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
              child: _historiqueClient.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun mouvement',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historiqueClient.length,
                      itemExtent: 18,
                      itemBuilder: (context, index) {
                        final mouvement = _historiqueClient[index];
                        return Container(
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
                                    (mouvement.sorties ?? 0) > 0 ? _formatMontant(mouvement.sorties!) : '',
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

  void _handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;

      // Ctrl+N : Créer nouveau client
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showAddClientModal();
      }
      // Ctrl+M : Modifier client sélectionné
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyM) {
        if (_selectedClient != null) {
          _showAddClientModal(client: _selectedClient);
        }
      }
      // Suppr : Supprimer client sélectionné
      else if (event.logicalKey == LogicalKeyboardKey.delete) {
        if (_selectedClient != null) {
          _deleteClient(_selectedClient!);
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
