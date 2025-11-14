import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'add_client_modal.dart';

class ClientsModal extends StatefulWidget {
  const ClientsModal({super.key});

  @override
  State<ClientsModal> createState() => _ClientsModalState();
}

class _ClientsModalState extends State<ClientsModal> {
  List<CltData> _clients = [];
  List<CltData> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  CltData? _selectedClient;
  final int _pageSize = 100;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
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
                _buildEmballagesSection(),
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
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Clients',
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
          border: Border.all(color: Colors.grey),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredClients.length,
                itemExtent: 18,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  final isSelected = _selectedClient?.rsoc == client.rsoc;
                  return GestureDetector(
                    onTap: () => _selectClient(client),
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
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey, width: 1),
                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              child: Text(
                                client.rsoc,
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
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey, width: 1),
                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              child: Text(
                                client.soldes?.toStringAsFixed(2) ?? '.00',
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
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              client.action ?? 'A',
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
            child: SizedBox(
              height: 20,
              child: Autocomplete<CltData>(
                optionsBuilder: (textEditingValue) {
                  // Toujours afficher tous les clients (limité à 100 pour performance)
                  if (textEditingValue.text.isEmpty || textEditingValue.text == ' ') {
                    return _clients.take(100);
                  }
                  return _clients.where((client) {
                    return client.rsoc.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  }).take(100);
                },
                displayStringForOption: (client) => client.rsoc,
                onSelected: (client) {
                  _selectClient(client);
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onTap: () {
                      // Afficher automatiquement la liste quand on clique
                      if (controller.text.isEmpty) {
                        controller.text = ' '; // Espace pour déclencher les options
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Cliquer pour voir les clients...',
                      hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 11),
                  );
                },
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
              onPressed: _showAllClients,
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

  void _selectClient(CltData client) {
    setState(() {
      _selectedClient = client;
    });
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
            builder: (context) => AddClientModal(nomClient: nomClient),
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
      builder: (context) => AddClientModal(client: client),
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

  Widget _buildEmballagesSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        children: [
          Container(
            height: 20,
            width: double.infinity,
            color: Colors.red[400],
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 4),
            child: const Text(
              'EMBALLAGES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange[300],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'DESIGNATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'QUANTITES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
