import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class AddFournisseurModal extends StatefulWidget {
  final Frn? fournisseur;
  final String? nomFournisseur;

  const AddFournisseurModal({super.key, this.fournisseur, this.nomFournisseur});

  @override
  State<AddFournisseurModal> createState() => _AddFournisseurModalState();
}

class _AddFournisseurModalState extends State<AddFournisseurModal> with TabNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _rsocController = TextEditingController();
  late final FocusNode _rsocFocusNode;
  final _adrController = TextEditingController();
  final _capitalController = TextEditingController();
  final _rcsController = TextEditingController();
  final _nifController = TextEditingController();
  final _statController = TextEditingController();
  final _telController = TextEditingController();
  final _portController = TextEditingController();
  final _emailController = TextEditingController();
  final _siteController = TextEditingController();
  final _faxController = TextEditingController();
  final _telexController = TextEditingController();

  bool get _isEditing => widget.fournisseur != null;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes with tab navigation
    _rsocFocusNode = createFocusNode();

    if (_isEditing) {
      _loadFournisseurData();
    } else if (widget.nomFournisseur != null) {
      _rsocController.text = widget.nomFournisseur!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rsocFocusNode.requestFocus();
    });
  }

  void _loadFournisseurData() {
    final fournisseur = widget.fournisseur!;
    _rsocController.text = fournisseur.rsoc;
    _adrController.text = fournisseur.adr ?? '';
    _capitalController.text = fournisseur.capital?.toString() ?? '';
    _rcsController.text = fournisseur.rcs ?? '';
    _nifController.text = fournisseur.nif ?? '';
    _statController.text = fournisseur.stat ?? '';
    _telController.text = fournisseur.tel ?? '';
    _portController.text = fournisseur.port ?? '';
    _emailController.text = fournisseur.email ?? '';
    _siteController.text = fournisseur.site ?? '';
    _faxController.text = fournisseur.fax ?? '';
    _telexController.text = fournisseur.telex ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isControlPressed) {
            _saveFournisseur();
            return KeyEventResult.handled;
          }
          // Gestion de la navigation Tab/Shift+Tab
          return handleTabNavigation(event);
        },
        child: Dialog(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.height * 0.7,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildIdentificationSection(),
                            const SizedBox(height: 16),
                            _buildCoordonneeSection(),
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
          colors: [Colors.blue.shade600, Colors.blue.shade400],
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
          Icon(
            _isEditing ? Icons.edit : Icons.add_business,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Modifier Fournisseur' : 'Nouveau Fournisseur',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Identification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Raison Social', _rsocController,
                          required: true, focusNode: _rsocFocusNode),
                      const SizedBox(height: 12),
                      _buildTextAreaField('Siège Social', _adrController),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Capital', _capitalController),
                      const SizedBox(height: 12),
                      _buildLabeledField('RCS', _rcsController),
                      const SizedBox(height: 12),
                      _buildLabeledField('N.I.F', _nifController),
                      const SizedBox(height: 12),
                      _buildLabeledField('STAT', _statController),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Coordonnées',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Téléphone', _telController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Fax', _faxController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Portable', _portController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Telex', _telexController)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabeledField('Email', _emailController),
                const SizedBox(height: 12),
                _buildLabeledField('Site internet', _siteController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {bool required = false, FocusNode? focusNode}) {
    final fieldFocusNode = focusNode ?? createFocusNode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            children: required
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 12),
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            constraints: const BoxConstraints(minHeight: 18, maxHeight: 30),
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
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                }
              : null,
          onTap: () => updateFocusIndex(fieldFocusNode),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, TextEditingController controller) {
    final focusNode = createFocusNode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 12),
          maxLines: 3,
          decoration: InputDecoration(
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
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onTap: () => updateFocusIndex(focusNode),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveFournisseur,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isEditing ? Icons.save : Icons.add, size: 16),
                const SizedBox(width: 4),
                Text(
                  _isEditing ? 'Modifier' : 'Créer',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFournisseur() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = FrnsCompanion(
        rsoc: drift.Value(_rsocController.text),
        adr: drift.Value(_adrController.text.isEmpty ? null : _adrController.text),
        capital: drift.Value(double.tryParse(_capitalController.text)),
        rcs: drift.Value(_rcsController.text.isEmpty ? null : _rcsController.text),
        nif: drift.Value(_nifController.text.isEmpty ? null : _nifController.text),
        stat: drift.Value(_statController.text.isEmpty ? null : _statController.text),
        tel: drift.Value(_telController.text.isEmpty ? null : _telController.text),
        port: drift.Value(_portController.text.isEmpty ? null : _portController.text),
        email: drift.Value(_emailController.text.isEmpty ? null : _emailController.text),
        site: drift.Value(_siteController.text.isEmpty ? null : _siteController.text),
        fax: drift.Value(_faxController.text.isEmpty ? null : _faxController.text),
        telex: drift.Value(_telexController.text.isEmpty ? null : _telexController.text),
      );

      if (widget.fournisseur == null) {
        await DatabaseService().database.insertFournisseur(companion);
      } else {
        await DatabaseService().database.updateFournisseur(widget.fournisseur!.rsoc, companion);
      }

      if (mounted) {
        Navigator.of(context).pop();
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
    _capitalController.dispose();
    _rcsController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _telController.dispose();
    _portController.dispose();
    _emailController.dispose();
    _siteController.dispose();
    _faxController.dispose();
    _telexController.dispose();
    super.dispose();
  }
}
