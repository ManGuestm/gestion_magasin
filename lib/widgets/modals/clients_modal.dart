import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
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
  CltData? _selectedClient;
  List<ComptecltData> _historiqueClient = [];
  final int _pageSize = 100;
  bool _isLoading = false;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _searchFocus = createFocusNode();
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
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
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
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

    final clients = await DatabaseService().database.getAllClients();
    setState(() {
      _clients = clients;
      _filteredClients = clients.take(_pageSize).toList();
      _isLoading = false;
    });
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
              tousDepots: !AuthService().hasRole('Vendeur'),
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
      _filteredClients = _clients.take(_pageSize).toList();
      _searchController.clear();
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
        tousDepots: !AuthService().hasRole('Vendeur'),
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
    final historique = await DatabaseService().database.customSelect(
      'SELECT * FROM compteclt WHERE clt = ? ORDER BY daty DESC LIMIT 50',
      variables: [Variable(rsocClient)],
    ).get();

    setState(() {
      _historiqueClient = historique
          .map((row) => ComptecltData(
                ref: row.read<String>('ref'),
                daty: row.read<DateTime?>('daty'),
                lib: row.read<String?>('lib'),
                numventes: row.read<String?>('numventes'),
                nfact: row.read<String?>('nfact'),
                refart: row.read<String?>('refart'),
                qs: row.read<double?>('qs'),
                pus: row.read<double?>('pus'),
                entres: row.read<double?>('entres'),
                sorties: row.read<double?>('sorties'),
                solde: row.read<double?>('solde'),
                clt: row.read<String?>('clt'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
