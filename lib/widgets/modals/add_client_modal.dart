import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/client_categories.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';

class AddClientModal extends StatefulWidget {
  final CltData? client;
  final String? nomClient;
  final bool? tousDepots;
  final String? forceCategorie;

  const AddClientModal({super.key, this.client, this.nomClient, this.tousDepots, this.forceCategorie});

  @override
  State<AddClientModal> createState() => _AddClientModalState();
}

class _AddClientModalState extends State<AddClientModal> {
  final _formKey = GlobalKey<FormState>();
  final _rsocController = TextEditingController();
  final _adrController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _nifController = TextEditingController();
  final _rcsController = TextEditingController();
  final _soldesController = TextEditingController();
  final _categorieController = TextEditingController();
  final _commercialController = TextEditingController();
  final _rsocFocusNode = FocusNode();
  String? _selectedCategorie;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _rsocController.text = widget.client!.rsoc;
      _adrController.text = widget.client!.adr ?? '';
      _telController.text = widget.client!.tel ?? '';
      _emailController.text = widget.client!.email ?? '';
      _nifController.text = widget.client!.nif ?? '';
      _rcsController.text = widget.client!.rcs ?? '';
      _soldesController.text = widget.client!.soldes?.toString() ?? '0';
      _categorieController.text = widget.client!.categorie ?? '';
      _selectedCategorie = widget.client!.categorie;
    } else {
      // Pré-remplir avec le nom fourni ou valeur par défaut
      _rsocController.text = widget.nomClient ?? '';
      // Utiliser la catégorie forcée ou déterminer selon le rôle
      _selectedCategorie = widget.forceCategorie ??
          (AuthService().hasRole('Vendeur') ? ClientCategory.magasin.label : ClientCategory.tousDepots.label);
    }

    // Initialiser le champ commercial avec le nom de l'utilisateur connecté
    _commercialController.text = AuthService().currentUser?.nom ?? '';

    // Focus automatique sur le champ Raison Social
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rsocFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            //Raccouris clavier
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              _saveClient();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.4,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minWidth: MediaQuery.of(context).size.width * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildIdentificationSection(),
                            const SizedBox(height: 8),
                            _buildCoordonneeSection(),
                            const SizedBox(height: 8),
                            _buildComptesSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.client == null ? Icons.person_add : Icons.edit,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.client == null ? 'NOUVEAU CLIENT' : 'MODIFIER CLIENT',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.blue[200]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'IDENTIFICATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Raison Social', _rsocController, required: true),
                      const SizedBox(height: 8),
                      _buildTextAreaField('Siège Social', _adrController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Capital', TextEditingController()),
                      const SizedBox(height: 8),
                      _buildLabeledField('RCS', _rcsController),
                      const SizedBox(height: 8),
                      _buildLabeledField('N.I.F', _nifController),
                      const SizedBox(height: 8),
                      _buildLabeledField('STAT', TextEditingController()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordonneeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[100]!, Colors.green[200]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.contact_phone, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'COORDONNEES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Telephone', _telController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Fax', TextEditingController())),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Portables', TextEditingController())),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Telex', TextEditingController())),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLabeledField('Email', _emailController),
                const SizedBox(height: 8),
                _buildLabeledField('Site internet', TextEditingController()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComptesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[200]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'COMPTES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildLabeledField('Commercial', _commercialController, width: 120, readOnly: true),
                    const SizedBox(width: 8),
                    _buildLabeledField('Taux Remise(%)', TextEditingController(), width: 80),
                    const SizedBox(width: 8),
                    _buildLabeledField('Plafonnement', TextEditingController(), width: 120),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategorieDropdown(),
                    const SizedBox(width: 8),
                    _buildLabeledField('Plafonnement BL', TextEditingController(), width: 120),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {bool required = false, double? width, bool readOnly = false}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: width ?? 200,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: controller == _rsocController ? _rsocFocusNode : null,
            readOnly: readOnly,
            style: TextStyle(fontSize: 12, color: readOnly ? Colors.grey[600] : Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              isDense: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              filled: true,
            ),
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 200,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorieDropdown() {
    final currentRole = AuthService().currentUserRole;
    final canSelectCategory = currentRole == 'Administrateur' || currentRole == 'Caisse';

    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text(
            'Catégorie',
            style: TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: canSelectCategory ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: canSelectCategory
              ? DropdownButtonFormField<String>(
                  initialValue: _selectedCategorie,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: ClientCategory.values
                      .map((category) => DropdownMenuItem(
                            value: category.label,
                            child: Text(category.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategorie = value;
                    });
                  },
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ClientCategory.magasin.label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _saveClient,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Valider (Entrée)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(null),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Annuler (Échap)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = CltCompanion(
        rsoc: drift.Value(_rsocController.text),
        adr: drift.Value(_adrController.text.isEmpty ? null : _adrController.text),
        tel: drift.Value(_telController.text.isEmpty ? null : _telController.text),
        email: drift.Value(_emailController.text.isEmpty ? null : _emailController.text),
        nif: drift.Value(_nifController.text.isEmpty ? null : _nifController.text),
        rcs: drift.Value(_rcsController.text.isEmpty ? null : _rcsController.text),
        soldes: drift.Value(double.tryParse(_soldesController.text) ?? 0.0),
        categorie: drift.Value(_selectedCategorie),
      );

      CltData clientData;
      if (widget.client == null) {
        await DatabaseService().database.insertClient(companion);
        // Créer l'objet client avec les données saisies
        clientData = CltData(
          rsoc: _rsocController.text,
          adr: _adrController.text.isEmpty ? null : _adrController.text,
          tel: _telController.text.isEmpty ? null : _telController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          nif: _nifController.text.isEmpty ? null : _nifController.text,
          rcs: _rcsController.text.isEmpty ? null : _rcsController.text,
          soldes: double.tryParse(_soldesController.text) ?? 0.0,
          categorie: _selectedCategorie,
        );
      } else {
        await DatabaseService().database.updateClient(widget.client!.rsoc, companion);
        clientData = widget.client!;
      }

      if (mounted) {
        Navigator.of(context).pop(clientData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _rsocController.dispose();
    _adrController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _nifController.dispose();
    _rcsController.dispose();
    _soldesController.dispose();
    _categorieController.dispose();
    _commercialController.dispose();
    _rsocFocusNode.dispose();
    super.dispose();
  }
}
