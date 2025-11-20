import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/client_categories.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../mixins/form_navigation_mixin.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/base_modal.dart';
import 'add_client_modal.dart';

class ClientsModal extends StatefulWidget {
  const ClientsModal({super.key});

  @override
  State<ClientsModal> createState() => _ClientsModalState();
}

class _ClientsModalState extends State<ClientsModal> with FormNavigationMixin {
  List<CltData> _clients = [];
  List<CltData> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  final FocusNode _keyboardFocusNode = FocusNode();
  CltData? _selectedClient;
  List<ComptecltData> _historiqueClient = [];
  final int _pageSize = 100;
  bool _isLoading = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _searchFocus = createFocusNode();



    _loadClients();

    // Focus automatique sur le KeyboardListener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcut,
      child: BaseModal(
        title: 'Clients',
        width: AppConstants.defaultModalWidth,
        height: AppConstants.defaultModalHeight,
        onNew: () => _showAddClientModal(),
        onDelete: () => _selectedClient != null ? _deleteClient(_selectedClient!) : null,
        onSearch: () => _searchFocus.requestFocus(),
        onRefresh: _loadClients,
        content: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Column(
            children: [
              if (AuthService().currentUser?.role == 'Administrateur' || AuthService().currentUser?.role == 'Caisse')
                _buildFilterSection(),
              _buildContent(),
              _buildHistoriqueSection(),
              _buildButtons(),
            ],
          ),
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
              child: ListView.builder(
                itemCount: _filteredClients.length,
                itemExtent: 24,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  final isSelected = _selectedClient?.rsoc == client.rsoc;
                  return _buildModernRow(client, isSelected, index);
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

  Widget _buildModernRow(CltData client, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectClient(client),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
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
            ),
            _buildDataCell(
              client.action ?? 'A',
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
                child: Autocomplete<CltData>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty || textEditingValue.text == ' ') {
                      return _clients.take(100);
                    }
                    return _clients.where((client) {
                      return client.rsoc.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    }).take(100);
                  },
                  displayStringForOption: (client) => client.rsoc,
                  onSelected: (client) => _selectClient(client),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    // Focus automatique sur le champ de recherche
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      focusNode.requestFocus();
                    });
                    
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                        hintText: 'Rechercher client...',
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
                      onEditingComplete: () async {
                        await _verifierEtCreerClient(controller.text);
                        onEditingComplete();
                      },
                      onSubmitted: (value) async {
                        await _verifierEtCreerClient(value);
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
              onPressed: _showAllClients,
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

  Future<void> _verifierEtCreerClient(String nomClient) async {
    if (nomClient.trim().isEmpty) return;

    // Vérifier si le client existe
    final clientExiste = _clients.any((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase());

    if (!clientExiste) {
      // Afficher le modal de confirmation
      final confirmer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Client inconnu!!'),
          content: Text('Le client "$nomClient" n\'existe pas.\n\nVoulez-vous le créer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Oui'),
            ),
          ],
        ),
      );

      if (confirmer == true) {
        // Ouvrir le modal d'ajout de client avec le nom pré-rempli
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AddClientModal(
              nomClient: nomClient,
              tousDepots: AuthService().currentUser?.role != 'Vendeur',
            ),
          );
        }

        // Recharger la liste des clients
        await _loadClients();

        // Chercher le client créé et le sélectionner
        final nouveauClient = _clients
            .where((client) => client.rsoc.toLowerCase().contains(nomClient.toLowerCase()))
            .firstOrNull;

        if (nouveauClient != null) {
          _selectClient(nouveauClient);
        }
      }
    } else {
      // Client existe, le sélectionner
      final client = _clients.firstWhere(
        (client) => client.rsoc.toLowerCase() == nomClient.toLowerCase(),
      );
      _selectClient(client);
    }
  }

  void _showAllClients() {
    setState(() {
      final userRole = AuthService().currentUser?.role ?? '';
      if (userRole == 'Administrateur' || userRole == 'Caisse') {
        _selectedCategoryFilter = null;
      }
      _searchController.clear();
    });
    _applyFilter();
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Text(
            'Filtrer par catégorie:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategoryFilter,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11, color: Colors.black),
              hint: const Text('Toutes', style: TextStyle(fontSize: 11)),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Toutes'),
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
                colors: [Colors.blue[400]!, Colors.blue[500]!],
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
                if (_selectedClient != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Solde dû: ${_formatMontant(_selectedClient!.soldes ?? 0)}',
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
                                    color: (mouvement.solde ?? 0) >= 0 ? Colors.green[700] : Colors.red[700],
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
