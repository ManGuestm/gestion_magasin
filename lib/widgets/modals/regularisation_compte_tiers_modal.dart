import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/enhanced_autocomplete.dart';

class RegularisationCompteTiersModal extends StatefulWidget {
  final VoidCallback? onPaymentSuccess;

  const RegularisationCompteTiersModal({
    super.key,
    this.onPaymentSuccess,
  });

  @override
  State<RegularisationCompteTiersModal> createState() => _RegularisationCompteTiersModalState();
}

class _RegularisationCompteTiersModalState extends State<RegularisationCompteTiersModal>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  // Client data
  List<CltData> _clients = [];
  List<ComptecltData> _clientMovements = [];
  CltData? _selectedClient;

  // Supplier data
  List<Frn> _suppliers = [];
  List<Comptefrn> _supplierMovements = [];
  Frn? _selectedSupplier;

  // Payment data
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();
  late final FocusNode _clientFocusNode;
  late final FocusNode _supplierFocusNode;
  late final FocusNode _amountFocusNode;
  late final FocusNode _paymentMethodFocusNode;
  late final FocusNode _dateFocusNode;
  late final FocusNode _referenceFocusNode;
  late final FocusNode _noteFocusNode;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'Espèces';
  double _clientBalance = 0.0;
  double _supplierBalance = 0.0;

  bool _isLoading = false;
  double totalDue = 0.0;

  List<String> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes with tab navigation
    _clientFocusNode = createFocusNode();
    _supplierFocusNode = createFocusNode();
    _amountFocusNode = createFocusNode();
    _paymentMethodFocusNode = createFocusNode();
    _dateFocusNode = createFocusNode();
    _referenceFocusNode = createFocusNode();
    _noteFocusNode = createFocusNode();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clientFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    _clientController.dispose();
    _supplierController.dispose();
    _paymentMethodController.dispose();
    _clientFocusNode.dispose();
    _supplierFocusNode.dispose();
    _amountFocusNode.dispose();
    _paymentMethodFocusNode.dispose();
    _dateFocusNode.dispose();
    _referenceFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  FocusNode createFocusNode() {
    return FocusNode();
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clientFocusNode.requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _supplierFocusNode.requestFocus();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _databaseService.database.getAllClients();
      final suppliers = await _databaseService.database.getAllFournisseurs();

      final paymentModes = await _databaseService.database.select(_databaseService.database.mp).get();

      setState(() {
        _clients = clients;
        _suppliers = suppliers;
        _paymentMethods = paymentModes.map((mp) => mp.mp).toList();
        if (_paymentMethods.isNotEmpty) {
          _paymentMethod = _paymentMethods.first;
        }
        _isLoading = false;
      });

      _paymentMethodController.text = _paymentMethod;
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadClientMovements(String clientCode) async {
    try {
      final movements = await _databaseService.database
          .getAllCompteclts()
          .then((all) => all.where((m) => m.clt == clientCode).toList());

      // Récupérer le solde réel du client depuis la table clt
      final client = await _databaseService.database.getClientByRsoc(clientCode);
      final realBalance = client?.soldes ?? 0.0;

      setState(() {
        _clientMovements = movements;
        _clientBalance = realBalance;
        totalDue = realBalance;
        _amountController.text = _formatAmount(realBalance);
      });
    } catch (e) {
      _showError('Erreur lors du chargement des mouvements: $e');
    }
  }

  Future<void> _loadSupplierMovements(String supplierCode) async {
    try {
      final movements = await _databaseService.database
          .getAllComptefrns()
          .then((all) => all.where((m) => m.frns == supplierCode).toList());

      // Récupérer le solde réel du fournisseur depuis la table frns
      final supplier = await _databaseService.database.getFournisseurByRsoc(supplierCode);
      final realBalance = supplier?.soldes ?? 0.0;

      setState(() {
        _supplierMovements = movements;
        _supplierBalance = realBalance;
        totalDue = realBalance;
        _amountController.text = _formatAmount(realBalance);
      });
    } catch (e) {
      _showError('Erreur lors du chargement des mouvements: $e');
    }
  }

  Future<void> _processPayment() async {
    if (_tabController.index == 0 && _selectedClient == null) {
      _showError('Veuillez sélectionner un client');
      return;
    }
    if (_tabController.index == 1 && _selectedSupplier == null) {
      _showError('Veuillez sélectionner un fournisseur');
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount <= 0) {
      _showError('Veuillez saisir un montant valide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_tabController.index == 0) {
        // Client payment - Encaissement
        await _processClientPayment(amount);
      } else {
        // Supplier payment - Décaissement
        await _processSupplierPayment(amount);
      }

      _showSuccess('Règlement enregistré avec succès');
      widget.onPaymentSuccess?.call();
      _resetForm();
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processClientPayment(double amount) async {
    final ref = 'ENC${DateTime.now().millisecondsSinceEpoch}';
    final libelle =
        'Règlement client ${_selectedClient!.rsoc} $_paymentMethod - ${_referenceController.text}';

    // 1. Mettre à jour le solde client
    final nouveauSolde = _clientBalance - amount;
    await _databaseService.database
        .customStatement('UPDATE clt SET soldes = ? WHERE rsoc = ?', [nouveauSolde, _selectedClient!.rsoc]);

    // 2. Écriture compte client
    await _databaseService.database.insererEcritureCompteClient(
      rsocClient: _selectedClient!.rsoc,
      date: _paymentDate,
      libelle: libelle,
      entrees: 0.0,
      sorties: amount,
      nouveauSolde: nouveauSolde,
      verification: 'REGLEMENT',
    );

    // 3. Encaissement selon le mode de paiement
    if (_paymentMethod == 'Espèces') {
      // Récupérer le dernier solde de caisse
      final dernierMouvement = await _databaseService.database
          .customSelect(
            'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
          )
          .getSingleOrNull();

      final dernierSolde = dernierMouvement?.data['soldes'] as double? ?? 0.0;
      final nouveauSolde = dernierSolde + amount;

      await _databaseService.database.customStatement(
          'INSERT INTO caisse (ref, daty, lib, credit, debit, soldes, type, clt, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _paymentDate.millisecondsSinceEpoch,
            libelle,
            amount,
            0.0,
            nouveauSolde,
            'ENCAISSEMENT',
            _selectedClient!.rsoc,
            'REGLEMENT'
          ]);
    } else {
      await _databaseService.database.customStatement(
          'INSERT INTO banque (ref, daty, lib, credit, debit, soldes, type, clt, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _paymentDate.millisecondsSinceEpoch,
            libelle,
            amount,
            0.0,
            amount,
            'ENCAISSEMENT',
            _selectedClient!.rsoc,
            'REGLEMENT'
          ]);
    }
  }

  Future<void> _processSupplierPayment(double amount) async {
    final ref = 'DEC${DateTime.now().millisecondsSinceEpoch}';
    final libelle =
        'Règlement fournisseur ${_selectedClient!.rsoc} $_paymentMethod - ${_referenceController.text}';

    // 1. Mettre à jour le solde fournisseur
    final nouveauSolde = _supplierBalance - amount;
    await _databaseService.database.customStatement(
        'UPDATE frns SET soldes = ? WHERE rsoc = ?', [nouveauSolde, _selectedSupplier!.rsoc]);

    // 2. Mettre à jour le montant réglé dans les achats
    await _databaseService.database.customStatement(
        'UPDATE achats SET regl = COALESCE(regl, 0) + ? WHERE frns = ? AND (totalttc - COALESCE(regl, 0)) > 0',
        [amount, _selectedSupplier!.rsoc]);

    // 3. Écriture compte fournisseur
    await _databaseService.database.insertComptefrns(ComptefrnsCompanion(
      ref: Value(ref),
      daty: Value(_paymentDate),
      lib: Value(libelle),
      entres: const Value(0.0),
      sortie: Value(amount),
      solde: Value(nouveauSolde),
      frns: Value(_selectedSupplier!.rsoc),
      verification: const Value('REGLEMENT'),
    ));

    // 4. Décaissement selon le mode de paiement
    if (_paymentMethod == 'Espèces') {
      // Récupérer le dernier solde de caisse
      final dernierMouvement = await _databaseService.database
          .customSelect(
            'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
          )
          .getSingleOrNull();

      final dernierSolde = dernierMouvement?.data['soldes'] as double? ?? 0.0;
      final nouveauSolde = dernierSolde - amount;

      await _databaseService.database.customStatement(
          'INSERT INTO caisse (ref, daty, lib, debit, credit, soldes, type, frns, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _paymentDate.millisecondsSinceEpoch,
            libelle,
            amount,
            0.0,
            nouveauSolde,
            'DECAISSEMENT',
            _selectedSupplier!.rsoc,
            'REGLEMENT'
          ]);
    } else {
      await _databaseService.database.customStatement(
          'INSERT INTO banque (ref, daty, lib, debit, credit, soldes, type, frns, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _paymentDate.millisecondsSinceEpoch,
            libelle,
            amount,
            0.0,
            -amount,
            'DECAISSEMENT',
            _selectedSupplier!.rsoc,
            'REGLEMENT'
          ]);
    }
  }

  void _resetForm() {
    _amountController.clear();
    _referenceController.clear();
    _noteController.clear();
    _clientController.clear();
    _supplierController.clear();
    _paymentMethodController.text = _paymentMethods.isNotEmpty ? _paymentMethods.first : '';
    setState(() {
      _selectedClient = null;
      _selectedSupplier = null;
      _clientMovements.clear();
      _supplierMovements.clear();
      totalDue = 0.0;
      _clientBalance = 0.0;
      _supplierBalance = 0.0;
      _paymentDate = DateTime.now();
      _paymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods.first : '';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0', 'fr_FR').format(amount).replaceAll(',', ' ');
  }

  double _parseAmount(String text) {
    try {
      return double.parse(text.replaceAll(',', '.').replaceAll(' ', ''));
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f3) {
          _processPayment();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.95,
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClientTab(),
                    _buildSupplierTab(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
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
          colors: [Colors.purple[600]!, Colors.purple[500]!],
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
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'RÉGULARISATION COMPTE TIERS',
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.purple[600],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.purple[600],
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(
            icon: Icon(Icons.person),
            text: 'RÈGLEMENT CLIENTS',
          ),
          Tab(
            icon: Icon(Icons.business),
            text: 'RÈGLEMENT FOURNISSEURS',
          ),
        ],
      ),
    );
  }

  Widget _buildClientTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildClientSelectionPanel(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildPaymentPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildSupplierSelectionPanel(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildPaymentPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelectionPanel() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sélection Client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                EnhancedAutocomplete<CltData>(
                  controller: _clientController,
                  focusNode: _clientFocusNode,
                  options: _clients,
                  displayStringForOption: (client) => client.rsoc,
                  onSelected: (client) {
                    setState(() => _selectedClient = client);
                    _loadClientMovements(client.rsoc);
                  },
                  onTabPressed: () => _amountFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Client',
                    prefixIcon: Icon(Icons.person, color: Colors.purple[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (_selectedClient != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _clientBalance > 0 ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _clientBalance > 0 ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Solde dû:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatAmount(_clientBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _clientBalance > 0 ? Colors.red[700] : Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_clientMovements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mouvements en cours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _clientMovements
                    .map((m) => _buildMovementTile(
                          m.nfact ?? '',
                          m.daty,
                          (m.sorties ?? 0.0) > 0 ? -(m.sorties ?? 0.0) : (m.entres ?? 0.0),
                          m.lib ?? '',
                        ))
                    .toList(),
              ),
            ),
          ] else if (_selectedClient != null)
            const Expanded(
              child: Center(
                child: Text(
                  'Aucun mouvement en cours',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierSelectionPanel() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sélection Fournisseur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                EnhancedAutocomplete<Frn>(
                  controller: _supplierController,
                  focusNode: _supplierFocusNode,
                  options: _suppliers,
                  displayStringForOption: (supplier) => supplier.rsoc,
                  onSelected: (supplier) {
                    setState(() => _selectedSupplier = supplier);
                    _loadSupplierMovements(supplier.rsoc);
                  },
                  onTabPressed: () => _amountFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Fournisseur',
                    prefixIcon: Icon(Icons.business, color: Colors.purple[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (_selectedSupplier != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _supplierBalance > 0 ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _supplierBalance > 0 ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Solde dû:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatAmount(_supplierBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _supplierBalance > 0 ? Colors.red[700] : Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_supplierMovements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mouvements en cours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _supplierMovements
                    .map((m) => _buildMovementTile(
                          m.nfact ?? '',
                          m.daty,
                          (m.sortie ?? 0.0) > 0 ? -(m.sortie ?? 0.0) : (m.entres ?? 0.0),
                          m.lib ?? '',
                        ))
                    .toList(),
              ),
            ),
          ] else if (_selectedSupplier != null)
            const Expanded(
              child: Center(
                child: Text(
                  'Aucun mouvement en cours',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(String reference, DateTime? date, double amount, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amount > 0 ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: amount > 0 ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reference,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _formatAmount(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: amount > 0 ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ],
          ),
          if (date != null)
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentPanel() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Règlement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      label: 'Montant',
                      icon: Icons.euro,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      onFieldSubmitted: (_) => _paymentMethodFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    Focus(
                      focusNode: _paymentMethodFocusNode,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          _paymentMethodController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _paymentMethodController.text.length,
                          );
                        }
                      },
                      child: EnhancedAutocomplete<String>(
                        controller: _paymentMethodController,
                        options: _paymentMethods,
                        displayStringForOption: (method) => method,
                        onSelected: (method) {
                          setState(() => _paymentMethod = method);
                        },
                        onTabPressed: () => _dateFocusNode.requestFocus(),
                        decoration: InputDecoration(
                          labelText: 'Mode de paiement',
                          prefixIcon: Icon(Icons.credit_card, color: Colors.purple[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple[600]!, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _referenceController,
                      focusNode: _referenceFocusNode,
                      label: 'Référence',
                      icon: Icons.receipt,
                      onFieldSubmitted: (_) => _noteFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      label: 'Note',
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'ENREGISTRER LE RÈGLEMENT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.purple[600]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDateField() {
    return Focus(
      focusNode: _dateFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          _referenceFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _paymentDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            setState(() => _paymentDate = date);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de paiement',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.purple[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(_paymentDate),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Régularisation des comptes clients et fournisseurs',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          TextButton(
            onPressed: _resetForm,
            child: Text(
              'Réinitialiser',
              style: TextStyle(
                color: Colors.purple[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
