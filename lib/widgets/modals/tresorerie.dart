import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/enhanced_autocomplete.dart';

class TresoreriePage extends StatefulWidget {
  const TresoreriePage({super.key});

  @override
  State<TresoreriePage> createState() => _TresoreriePageState();
}

class _TresoreriePageState extends State<TresoreriePage> {
  final DatabaseService _dbService = DatabaseService();
  List<String> _clients = [];
  List<String> _fournisseurs = [];
  List<String> _modesPaiement = [];
  bool _isDatePickerOpen = false;
  double? _soldeClient;
  double? _soldeFournisseur;

  // FocusNodes pour la navigation par tabulation
  final FocusNode _clientFocus = FocusNode();
  final FocusNode _montantClientFocus = FocusNode();
  final FocusNode _modePaiementClientFocus = FocusNode();
  final FocusNode _dateClientFocus = FocusNode();

  final FocusNode _libelleEncaissementFocus = FocusNode();
  final FocusNode _montantEncaissementFocus = FocusNode();
  final FocusNode _modePaiementEncaissementFocus = FocusNode();
  final FocusNode _dateEncaissementFocus = FocusNode();

  final FocusNode _fournisseurFocus = FocusNode();
  final FocusNode _montantFournisseurFocus = FocusNode();
  final FocusNode _modePaiementFournisseurFocus = FocusNode();
  final FocusNode _dateFournisseurFocus = FocusNode();

  final FocusNode _libelleDecaissementFocus = FocusNode();
  final FocusNode _montantDecaissementFocus = FocusNode();
  final FocusNode _modePaiementDecaissementFocus = FocusNode();
  final FocusNode _dateDecaissementFocus = FocusNode();

  // Controllers pour Versement client
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _montantClientController = TextEditingController();
  final TextEditingController _modePaiementClientController = TextEditingController(text: 'Espèces');
  DateTime _dateVersementClient = DateTime.now();

  // Controllers pour Versement fournisseur
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _montantFournisseurController = TextEditingController();
  final TextEditingController _modePaiementFournisseurController = TextEditingController(text: 'Espèces');
  DateTime _dateVersementFournisseur = DateTime.now();

  // Controllers pour Autre encaissement (gauche)
  final TextEditingController _libelleEncaissementController = TextEditingController();
  final TextEditingController _montantEncaissementController = TextEditingController();
  final TextEditingController _modePaiementEncaissementController = TextEditingController(text: 'Espèces');
  DateTime _dateEncaissement = DateTime.now();

  // Controllers pour Autre encaissement (droite)
  final TextEditingController _libelleDecaissementController = TextEditingController();
  final TextEditingController _montantDecaissementController = TextEditingController();
  final TextEditingController _modePaiementDecaissementController = TextEditingController(text: 'Espèces');
  DateTime _dateDecaissement = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _clientController.addListener(() {
      if (_clientController.text.isEmpty) {
        setState(() => _soldeClient = null);
      }
    });
    _fournisseurController.addListener(() {
      if (_fournisseurController.text.isEmpty) {
        setState(() => _soldeFournisseur = null);
      }
    });
    _dateClientFocus.addListener(() {
      if (_dateClientFocus.hasFocus && !_isDatePickerOpen) {
        _selectDate(context, _dateVersementClient, (date) => _dateVersementClient = date, _dateClientFocus);
      }
    });
    _dateEncaissementFocus.addListener(() {
      if (_dateEncaissementFocus.hasFocus && !_isDatePickerOpen) {
        _selectDate(context, _dateEncaissement, (date) => _dateEncaissement = date, _dateEncaissementFocus);
      }
    });
    _dateFournisseurFocus.addListener(() {
      if (_dateFournisseurFocus.hasFocus && !_isDatePickerOpen) {
        _selectDate(
          context,
          _dateVersementFournisseur,
          (date) => _dateVersementFournisseur = date,
          _dateFournisseurFocus,
        );
      }
    });
    _dateDecaissementFocus.addListener(() {
      if (_dateDecaissementFocus.hasFocus && !_isDatePickerOpen) {
        _selectDate(context, _dateDecaissement, (date) => _dateDecaissement = date, _dateDecaissementFocus);
      }
    });
  }

  Future<void> _loadData() async {
    final clients = await _dbService.getActiveClientsWithModeAwareness();
    final fournisseurs = await _dbService.getActiveFournisseursWithModeAwareness();
    final modesPaiement = await _dbService.getModesPaiementWithModeAwareness();
    setState(() {
      _clients = clients.map((c) => c.rsoc).toList();
      _fournisseurs = fournisseurs.map((f) => f.rsoc).toList();
      _modesPaiement = modesPaiement.where((m) => m != 'A crédit').toList();
      if (_modesPaiement.isNotEmpty) {
        _modePaiementClientController.text = _modesPaiement.first;
        _modePaiementEncaissementController.text = _modesPaiement.first;
        _modePaiementFournisseurController.text = _modesPaiement.first;
        _modePaiementDecaissementController.text = _modesPaiement.first;
      }
    });
  }

  Future<void> _encaisserClient() async {
    if (_clientController.text.isEmpty || _montantClientController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez remplir tous les champs')));
      return;
    }

    final montant = double.tryParse(_montantClientController.text) ?? 0;
    if (montant <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez saisir un montant valide')));
      return;
    }

    final ref = 'ENC${DateTime.now().millisecondsSinceEpoch}';
    final libelle = 'Reçu du client ${_clientController.text} ${_modePaiementClientController.text}';

    try {
      debugPrint('🔍 ENCAISSEMENT CLIENT - Début');
      debugPrint('Client: ${_clientController.text}');
      debugPrint('Montant: $montant');
      debugPrint('Mode paiement: ${_modePaiementClientController.text}');

      // 1. Mettre à jour le solde client
      final client = await _dbService.database.getClientByRsoc(_clientController.text);
      if (client == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: SelectableText('Client introuvable')));
        return;
      }

      final nouveauSolde = (client.soldes ?? 0.0) - montant;
      debugPrint('Ancien solde: ${client.soldes}, Nouveau solde: $nouveauSolde');

      final params1 = [nouveauSolde, _clientController.text];
      debugPrint('Params UPDATE clt: $params1 (types: ${params1.map((p) => p.runtimeType).toList()})');

      await _dbService.customStatement('UPDATE clt SET soldes = ? WHERE rsoc = ?', params1);

      // 2. Écriture compte client
      debugPrint('Insertion compteclt...');
      await _dbService.database.insererEcritureCompteClient(
        rsocClient: _clientController.text,
        date: _dateVersementClient,
        libelle: libelle,
        entrees: 0.0,
        sorties: montant,
        nouveauSolde: nouveauSolde,
        verification: 'REGLEMENT',
      );

      // 3. Encaissement selon le mode de paiement
      if (_modePaiementClientController.text == 'Espèces') {
        debugPrint('Mode: Espèces - Insertion caisse');
        final dernierMouvement = await _dbService.customSelect(
          'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
        );
        final dernierSolde = dernierMouvement.isNotEmpty
            ? (dernierMouvement[0]['soldes'] as double? ?? 0.0)
            : 0.0;
        final nouveauSoldeCaisse = dernierSolde + montant;

        final paramsCaisse = [
          ref,
          _dateVersementClient.millisecondsSinceEpoch ~/ 1000,
          libelle,
          montant,
          0.0,
          nouveauSoldeCaisse,
          'ENCAISSEMENT',
          _clientController.text,
          'REGLEMENT',
        ];
        debugPrint('Params caisse: ${paramsCaisse.map((p) => '${p.runtimeType}:$p').toList()}');

        await _dbService.customStatement(
          'INSERT INTO caisse (ref, daty, lib, credit, debit, soldes, type, clt, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          paramsCaisse,
        );
      } else {
        debugPrint('Mode: ${_modePaiementClientController.text} - Insertion banque');
        final paramsBanque = [
          ref,
          _dateVersementClient.millisecondsSinceEpoch ~/ 1000,
          libelle,
          montant,
          0.0,
          montant,
          'ENCAISSEMENT',
          _clientController.text,
          'REGLEMENT',
        ];
        debugPrint('Params banque: ${paramsBanque.map((p) => '${p.runtimeType}:$p').toList()}');

        await _dbService.customStatement(
          'INSERT INTO banque (ref, daty, lib, credit, debit, soldes, type, clt, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          paramsBanque,
        );
      }

      debugPrint('✅ Encaissement client réussi');
      setState(() {
        _clientController.clear();
        _montantClientController.clear();
        _soldeClient = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Encaissement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ ERREUR ENCAISSEMENT CLIENT: $e');
      debugPrint('Stack: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: SelectableText('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _encaisserAutre() async {
    if (_libelleEncaissementController.text.isEmpty || _montantEncaissementController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez remplir tous les champs')));
      return;
    }

    final montant = double.tryParse(_montantEncaissementController.text) ?? 0;
    if (montant <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez saisir un montant valide')));
      return;
    }

    final ref = 'ENC${DateTime.now().millisecondsSinceEpoch}';
    final libelle = '${_libelleEncaissementController.text} - ${_modePaiementEncaissementController.text}';

    try {
      // Encaissement selon le mode de paiement
      if (_modePaiementEncaissementController.text == 'Espèces') {
        final dernierMouvement = await _dbService.customSelect(
          'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
        );
        final dernierSolde = dernierMouvement.isNotEmpty
            ? (dernierMouvement[0]['soldes'] as double? ?? 0.0)
            : 0.0;
        final nouveauSolde = dernierSolde + montant;

        await _dbService.customStatement(
          'INSERT INTO caisse (ref, daty, lib, credit, debit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateEncaissement.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            nouveauSolde,
            'ENCAISSEMENT',
            'AUTRE',
          ],
        );
      } else {
        await _dbService.customStatement(
          'INSERT INTO banque (ref, daty, lib, credit, debit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateEncaissement.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            montant,
            'ENCAISSEMENT',
            'AUTRE',
          ],
        );
      }

      _libelleEncaissementController.clear();
      _montantEncaissementController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Encaissement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: SelectableText('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _decaisserFournisseur() async {
    if (_fournisseurController.text.isEmpty || _montantFournisseurController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez remplir tous les champs')));
      return;
    }

    final montant = double.tryParse(_montantFournisseurController.text) ?? 0;
    if (montant <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez saisir un montant valide')));
      return;
    }

    final ref = 'DEC${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    final libelle =
        'Règlement fournisseur ${_fournisseurController.text} ${_modePaiementFournisseurController.text}';

    try {
      // 1. Mettre à jour le solde fournisseur
      final fournisseur = await _dbService.database.getFournisseurByRsoc(_fournisseurController.text);
      if (fournisseur == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: SelectableText('Fournisseur introuvable')));
        return;
      }

      final nouveauSolde = (fournisseur.soldes ?? 0.0) - montant;
      await _dbService.customStatement('UPDATE frns SET soldes = ? WHERE rsoc = ?', [
        nouveauSolde,
        _fournisseurController.text,
      ]);

      // 2. Mettre à jour le montant réglé dans les achats
      await _dbService.customStatement(
        'UPDATE achats SET regl = COALESCE(regl, 0) + ? WHERE frns = ? AND (totalttc - COALESCE(regl, 0)) > 0',
        [montant, _fournisseurController.text],
      );

      // 3. Écriture compte fournisseur
      await _dbService.database.insertComptefrns(
        ComptefrnsCompanion(
          ref: Value(ref),
          daty: Value(_dateVersementFournisseur),
          lib: Value(libelle),
          entres: const Value(0.0),
          sortie: Value(montant),
          solde: Value(nouveauSolde),
          frns: Value(_fournisseurController.text),
          verification: const Value('REGLEMENT'),
        ),
      );

      // 4. Décaissement selon le mode de paiement
      if (_modePaiementFournisseurController.text == 'Espèces') {
        final dernierMouvement = await _dbService.customSelect(
          'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
        );
        final dernierSolde = dernierMouvement.isNotEmpty
            ? (dernierMouvement[0]['soldes'] as double? ?? 0.0)
            : 0.0;
        final nouveauSoldeCaisse = dernierSolde - montant;

        await _dbService.customStatement(
          'INSERT INTO caisse (ref, daty, lib, debit, credit, soldes, type, frns, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateVersementFournisseur.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            nouveauSoldeCaisse,
            'DECAISSEMENT',
            _fournisseurController.text,
            'REGLEMENT',
          ],
        );
      } else {
        await _dbService.customStatement(
          'INSERT INTO banque (ref, daty, lib, debit, credit, soldes, type, frns, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateVersementFournisseur.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            -montant,
            'DECAISSEMENT',
            _fournisseurController.text,
            'REGLEMENT',
          ],
        );
      }

      setState(() {
        _fournisseurController.clear();
        _montantFournisseurController.clear();
        _soldeFournisseur = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Décaissement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: SelectableText('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _decaisserAutre() async {
    if (_libelleDecaissementController.text.isEmpty || _montantDecaissementController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez remplir tous les champs')));
      return;
    }

    final montant = double.tryParse(_montantDecaissementController.text) ?? 0;
    if (montant <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: SelectableText('Veuillez saisir un montant valide')));
      return;
    }

    final ref = 'DEC${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    final libelle = '${_libelleDecaissementController.text} - ${_modePaiementDecaissementController.text}';

    try {
      // Décaissement selon le mode de paiement
      if (_modePaiementDecaissementController.text == 'Espèces') {
        final dernierMouvement = await _dbService.customSelect(
          'SELECT soldes FROM caisse ORDER BY daty DESC LIMIT 1',
        );
        final dernierSolde = dernierMouvement.isNotEmpty
            ? (dernierMouvement[0]['soldes'] as double? ?? 0.0)
            : 0.0;
        final nouveauSolde = dernierSolde - montant;

        await _dbService.customStatement(
          'INSERT INTO caisse (ref, daty, lib, debit, credit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateDecaissement.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            nouveauSolde,
            'DECAISSEMENT',
            'AUTRE',
          ],
        );
      } else {
        await _dbService.customStatement(
          'INSERT INTO banque (ref, daty, lib, debit, credit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ref,
            _dateDecaissement.millisecondsSinceEpoch ~/ 1000,
            libelle,
            montant,
            0.0,
            -montant,
            'DECAISSEMENT',
            'AUTRE',
          ],
        );
      }

      _libelleDecaissementController.clear();
      _montantDecaissementController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Décaissement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: SelectableText('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    _montantClientController.dispose();
    _modePaiementClientController.dispose();
    _fournisseurController.dispose();
    _montantFournisseurController.dispose();
    _modePaiementFournisseurController.dispose();
    _libelleEncaissementController.dispose();
    _montantEncaissementController.dispose();
    _modePaiementEncaissementController.dispose();
    _libelleDecaissementController.dispose();
    _montantDecaissementController.dispose();
    _modePaiementDecaissementController.dispose();

    _clientFocus.dispose();
    _montantClientFocus.dispose();
    _modePaiementClientFocus.dispose();
    _dateClientFocus.dispose();
    _libelleEncaissementFocus.dispose();
    _montantEncaissementFocus.dispose();
    _modePaiementEncaissementFocus.dispose();
    _dateEncaissementFocus.dispose();
    _fournisseurFocus.dispose();
    _montantFournisseurFocus.dispose();
    _modePaiementFournisseurFocus.dispose();
    _dateFournisseurFocus.dispose();
    _libelleDecaissementFocus.dispose();
    _montantDecaissementFocus.dispose();
    _modePaiementDecaissementFocus.dispose();
    _dateDecaissementFocus.dispose();

    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime currentDate,
    Function(DateTime) onDateSelected,
    FocusNode? currentFocus,
  ) async {
    _isDatePickerOpen = true;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    _isDatePickerOpen = false;
    if (picked != null && picked != currentDate) {
      setState(() {
        onDateSelected(picked);
      });
    }
    currentFocus?.unfocus();
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    required VoidCallback onPressed,
    required String buttonText,
    required Color buttonColor,
    required IconData buttonIcon,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: buttonColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(buttonIcon, color: buttonColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(buttonIcon, size: 16),
                  label: Text(buttonText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: buttonColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
    FocusNode? focusNode,
    bool isAutocomplete = false,
    List<String>? autocompleteOptions,
    FocusNode? nextFocus,
    FocusNode? previousFocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: isAutocomplete && autocompleteOptions != null
              ? EnhancedAutocomplete<String>(
                  options: autocompleteOptions,
                  displayStringForOption: (option) => option,
                  onSelected: (value) async {
                    controller.text = value;
                    if (label == 'Client') {
                      final client = await _dbService.database.getClientByRsoc(value);
                      setState(() => _soldeClient = client?.soldes);
                    } else if (label == 'Fournisseur') {
                      final frns = await _dbService.database.getFournisseurByRsoc(value);
                      setState(() => _soldeFournisseur = frns?.soldes);
                    }
                  },
                  controller: controller,
                  focusNode: focusNode,
                  onTabPressed: () => nextFocus?.requestFocus(),
                  onShiftTabPressed: () => previousFocus?.requestFocus(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 16),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5E4C9F), width: 2),
                    ),
                  ),
                )
              : TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  inputFormatters: keyboardType == TextInputType.number
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                      : null,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 16),
                    suffixText: suffix,
                    suffixStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5E4C9F), width: 2),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: items.contains(value) ? value : null,
            focusNode: focusNode,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: Colors.black),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5E4C9F), width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Focus(
          focusNode: focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              _selectDate(context, date, onDateSelected, focusNode);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            onTap: () => _selectDate(context, date, onDateSelected, focusNode),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focusNode?.hasFocus == true ? const Color(0xFF5E4C9F) : Colors.grey.shade300,
                  width: focusNode?.hasFocus == true ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 12),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5E4C9F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance, color: Color(0xFF5E4C9F), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Trésorerie',
              style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            label: const Text("Fermer"),
            icon: const Icon(Icons.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSectionHeader('ENCAISSEMENT', Icons.arrow_downward, Colors.green.shade600),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCard(
                            title: 'Versement client',
                            buttonText: 'Encaisser',
                            buttonColor: Colors.green.shade600,
                            buttonIcon: Icons.check_circle,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Client',
                                      controller: _clientController,
                                      icon: Icons.person_outline,
                                      focusNode: _clientFocus,
                                      isAutocomplete: true,
                                      autocompleteOptions: _clients,
                                      nextFocus: _montantClientFocus,
                                    ),
                                    if (_soldeClient != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Solde dû: ${AppFunctions.formatNumber(_soldeClient!)} Ar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _soldeClient! > 0
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: _buildTextField(
                                  label: 'Montant',
                                  controller: _montantClientController,
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  suffix: 'Ar',
                                  focusNode: _montantClientFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: _buildDropdownField(
                                  label: 'Mode de paiement',
                                  value: _modePaiementClientController.text,
                                  items: _modesPaiement,
                                  onChanged: (val) =>
                                      setState(() => _modePaiementClientController.text = val ?? ''),
                                  icon: Icons.payment,
                                  focusNode: _modePaiementClientFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(4),
                                child: _buildDateField(
                                  label: 'Date de paiement',
                                  date: _dateVersementClient,
                                  onDateSelected: (date) => _dateVersementClient = date,
                                  focusNode: _dateClientFocus,
                                ),
                              ),
                            ],
                            onPressed: _encaisserClient,
                          ),
                        ),
                        const SizedBox(width: 42),
                        Expanded(
                          child: _buildCard(
                            title: 'Autre encaissement',
                            buttonText: 'Encaisser',
                            buttonColor: Colors.green.shade600,
                            buttonIcon: Icons.check_circle,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(5),
                                child: _buildTextField(
                                  label: 'Libellé',
                                  controller: _libelleEncaissementController,
                                  icon: Icons.description_outlined,
                                  focusNode: _libelleEncaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(6),
                                child: _buildTextField(
                                  label: 'Montant',
                                  controller: _montantEncaissementController,
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  suffix: 'Ar',
                                  focusNode: _montantEncaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(7),
                                child: _buildDropdownField(
                                  label: 'Mode de paiement',
                                  value: _modePaiementEncaissementController.text,
                                  items: _modesPaiement,
                                  onChanged: (val) =>
                                      setState(() => _modePaiementEncaissementController.text = val ?? ''),
                                  icon: Icons.payment,
                                  focusNode: _modePaiementEncaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(8),
                                child: _buildDateField(
                                  label: 'Date d\'encaissement',
                                  date: _dateEncaissement,
                                  onDateSelected: (date) => _dateEncaissement = date,
                                  focusNode: _dateEncaissementFocus,
                                ),
                              ),
                            ],
                            onPressed: _encaisserAutre,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(flex: 1, child: Container()),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSectionHeader('DÉCAISSEMENT', Icons.arrow_upward, Colors.red.shade600),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCard(
                            title: 'Paiement Fournisseur',
                            buttonText: 'Décaisser',
                            buttonColor: Colors.red.shade600,
                            buttonIcon: Icons.remove_circle,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(9),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      label: 'Fournisseur',
                                      controller: _fournisseurController,
                                      icon: Icons.business,
                                      focusNode: _fournisseurFocus,
                                      isAutocomplete: true,
                                      autocompleteOptions: _fournisseurs,
                                      nextFocus: _montantFournisseurFocus,
                                      previousFocus: _dateEncaissementFocus,
                                    ),
                                    if (_soldeFournisseur != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Solde dû: ${AppFunctions.formatNumber(_soldeFournisseur!)} Ar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _soldeFournisseur! > 0
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(10),
                                child: _buildTextField(
                                  label: 'Montant',
                                  controller: _montantFournisseurController,
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  suffix: 'Ar',
                                  focusNode: _montantFournisseurFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(11),
                                child: _buildDropdownField(
                                  label: 'Mode de paiement',
                                  value: _modePaiementFournisseurController.text,
                                  items: _modesPaiement,
                                  onChanged: (val) =>
                                      setState(() => _modePaiementFournisseurController.text = val ?? ''),
                                  icon: Icons.payment,
                                  focusNode: _modePaiementFournisseurFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(12),
                                child: _buildDateField(
                                  label: 'Date de paiement',
                                  date: _dateVersementFournisseur,
                                  onDateSelected: (date) => _dateVersementFournisseur = date,
                                  focusNode: _dateFournisseurFocus,
                                ),
                              ),
                            ],
                            onPressed: _decaisserFournisseur,
                          ),
                        ),
                        const SizedBox(width: 42),
                        Expanded(
                          child: _buildCard(
                            title: 'Autre décaissement',
                            buttonText: 'Décaisser',
                            buttonColor: Colors.red.shade600,
                            buttonIcon: Icons.remove_circle,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(13),
                                child: _buildTextField(
                                  label: 'Libellé',
                                  controller: _libelleDecaissementController,
                                  icon: Icons.description_outlined,
                                  focusNode: _libelleDecaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(14),
                                child: _buildTextField(
                                  label: 'Montant',
                                  controller: _montantDecaissementController,
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  suffix: 'Ar',
                                  focusNode: _montantDecaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(15),
                                child: _buildDropdownField(
                                  label: 'Mode de paiement',
                                  value: _modePaiementDecaissementController.text,
                                  items: _modesPaiement,
                                  onChanged: (val) =>
                                      setState(() => _modePaiementDecaissementController.text = val ?? ''),
                                  icon: Icons.payment,
                                  focusNode: _modePaiementDecaissementFocus,
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(16),
                                child: _buildDateField(
                                  label: 'Date de décaissement',
                                  date: _dateDecaissement,
                                  onDateSelected: (date) => _dateDecaissement = date,
                                  focusNode: _dateDecaissementFocus,
                                ),
                              ),
                            ],
                            onPressed: _decaisserAutre,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
