import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class AddArticleModal extends StatefulWidget {
  final Article? article;

  const AddArticleModal({super.key, this.article});

  @override
  State<AddArticleModal> createState() => _AddArticleModalState();
}

class _AddArticleModalState extends State<AddArticleModal> with TabNavigationMixin {
  static const _fieldNames = [
    'designation',
    'u1',
    'tu2u1',
    'u2',
    'tu3u2',
    'u3',
    'depot',
    'pvu1',
    'pvu2',
    'pvu3',
    'categorie',
    'classification',
    'emb',
    'sec',
    'uniteSection',
    'creer',
    'annuler',
  ];

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  List<Depot> _depots = [];
  String? _selectedDepot;
  String? _selectedUniteSection;
  List<String> _unitesDisponibles = [];

  Timer? _debounceTimer;

  bool get _isEditMode => widget.article != null;

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _initializeControllers();
    _loadDepots();
    _focusDesignationField();
  }

  void _initializeFocusNodes() {
    // Créer tous les FocusNodes une seule fois
    for (final fieldName in _fieldNames) {
      _focusNodes[fieldName] = createFocusNode();
    }
  }

  void _initializeControllers() {
    final article = widget.article;

    for (final fieldName in _fieldNames) {
      _controllers[fieldName] = TextEditingController();
    }

    _updateControllerValues(article);
    _updateUnitesDisponibles();
  }

  void _updateControllerValues(Article? article) {
    if (article == null) {
      _controllers['categorie']!.text = 'Catégorie articles';
      _controllers['classification']!.text = 'Marchandises';
      return;
    }

    _controllers['designation']!.text = article.designation;
    _controllers['u1']!.text = article.u1 ?? '';
    _controllers['u2']!.text = article.u2 ?? '';
    _controllers['u3']!.text = article.u3 ?? '';
    _controllers['tu2u1']!.text = article.tu2u1?.toString() ?? '';
    _controllers['tu3u2']!.text = article.tu3u2?.toString() ?? '';
    _controllers['pvu1']!.text = article.pvu1?.toString() ?? '';
    _controllers['pvu2']!.text = article.pvu2?.toString() ?? '';
    _controllers['pvu3']!.text = article.pvu3?.toString() ?? '';
    _controllers['categorie']!.text = article.categorie ?? 'Catégorie articles';
    _controllers['classification']!.text = article.classification ?? 'Marchandises';
    _controllers['emb']!.text = article.emb ?? '';
    _controllers['sec']!.text = article.sec ?? '';

    _selectedDepot = article.dep;
  }

  void _focusDesignationField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes['designation']?.requestFocus();

      final designationController = _controllers['designation'];
      if (designationController != null && designationController.text.isNotEmpty) {
        designationController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: designationController.text.length,
        );
      }
    });
  }

  Future<void> _loadDepots() async {
    final depots = await DatabaseService().database.getAllDepots();

    setState(() {
      _depots = depots;
      if (_depots.isNotEmpty && _selectedDepot == null) {
        _selectedDepot = _depots.first.depots;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => handleKeyEvent(event),
        child: _buildDialogContent(),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      width: 950,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: _dialogDecoration,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildFormContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  BoxDecoration get _dialogDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: Colors.white,
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
    ],
  );

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: _headerDecoration,
      child: Row(
        children: [
          _buildHeaderIcon(),
          const SizedBox(width: 12),
          _buildHeaderTitle(),
          const Spacer(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  BoxDecoration get _headerDecoration => BoxDecoration(
    gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade700]),
    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
  );

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2, color: Colors.white, size: 22),
    );
  }

  Widget _buildHeaderTitle() {
    return Text(
      _isEditMode ? 'Modifier Article' : 'Nouvel Article',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close, color: Colors.white, size: 22),
      tooltip: 'Fermer',
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesignationField(),
            const SizedBox(height: 24),
            _buildMainContentRow(),
            const SizedBox(height: 20),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildStockSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildUnitsSection()),
        const SizedBox(width: 20),
        Expanded(child: _buildPricesSection()),
      ],
    );
  }

  Widget _buildDesignationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(icon: Icons.label, title: 'Informations générales'),
        const SizedBox(height: 12),
        buildFormField(
          controller: _controllers['designation']!,
          focusNode: _focusNodes['designation']!,
          label: 'Désignation de l\'article *',
          autofocus: true,
          validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildUnitsSection() {
    return _buildSection(
      title: 'Unités et conversions',
      icon: Icons.straighten,
      children: [
        buildFormField(
          controller: _controllers['u1']!,
          focusNode: _focusNodes['u1']!,
          label: 'Unité 1',
          onChanged: (_) => _debouncedUpdateUnites(),
        ),
        const SizedBox(height: 12),
        buildFormField(
          controller: _controllers['tu2u1']!,
          focusNode: _focusNodes['tu2u1']!,
          label: 'Taux U2/U1',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        ),
        const SizedBox(height: 12),
        buildFormField(
          controller: _controllers['u2']!,
          focusNode: _focusNodes['u2']!,
          label: 'Unité 2',
          onChanged: (_) => _debouncedUpdateUnites(),
        ),
        const SizedBox(height: 12),
        buildFormField(
          controller: _controllers['tu3u2']!,
          focusNode: _focusNodes['tu3u2']!,
          label: 'Taux U3/U2',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        ),
        const SizedBox(height: 12),
        buildFormField(
          controller: _controllers['u3']!,
          focusNode: _focusNodes['u3']!,
          label: 'Unité 3',
          onChanged: (_) => _debouncedUpdateUnites(),
        ),
        const SizedBox(height: 12),
        _buildDepotDropdown(),
      ],
    );
  }

  Widget _buildDepotDropdown() {
    return DropdownButtonFormField<String>(
      focusNode: _focusNodes['depot']!,
      initialValue: _selectedDepot,
      decoration: _dropdownDecoration(label: 'Dépôt par défaut'),
      style: _dropdownTextStyle,
      items: _depots.map((depot) {
        return DropdownMenuItem(value: depot.depots, child: Text(depot.depots));
      }).toList(),
      onChanged: (value) => setState(() => _selectedDepot = value),
    );
  }

  InputDecoration _dropdownDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w400),
      floatingLabelStyle: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  TextStyle get _dropdownTextStyle =>
      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.black87);

  Widget _buildPricesSection() {
    return _buildSection(
      title: 'Prix de vente',
      icon: Icons.payments,
      children: [
        _buildPriceField('pvu1', 'Prix Vente U1', _focusNodes['pvu1']!),
        const SizedBox(height: 12),
        _buildPriceField('pvu2', 'Prix Vente U2', _focusNodes['pvu2']!),
        const SizedBox(height: 12),
        _buildPriceField('pvu3', 'Prix Vente U3', _focusNodes['pvu3']!),
      ],
    );
  }

  Widget _buildPriceField(String controllerKey, String label, FocusNode focusNode) {
    return buildFormField(
      controller: _controllers[controllerKey]!,
      focusNode: focusNode,
      label: label,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    );
  }

  Widget _buildCategorySection() {
    return _buildSection(
      title: 'Catégorie et classification',
      icon: Icons.category,
      children: [
        Row(
          children: [
            Expanded(
              child: buildFormField(
                controller: _controllers['categorie']!,
                focusNode: _focusNodes['categorie']!,
                label: 'Catégorie',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildFormField(
                controller: _controllers['classification']!,
                focusNode: _focusNodes['classification']!,
                label: 'Classification',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildFormField(
                controller: _controllers['emb']!,
                focusNode: _focusNodes['emb']!,
                label: 'Emballage',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return _buildSection(
      title: 'Stocks de sécurité',
      icon: Icons.inventory,
      children: [
        Row(
          children: [
            Expanded(
              child: buildFormField(
                controller: _controllers['sec']!,
                focusNode: _focusNodes['sec']!,
                label: 'Section',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                focusNode: _focusNodes['uniteSection'],
                initialValue: _selectedUniteSection,
                decoration: _dropdownDecoration(label: 'Unité Section'),
                style: _dropdownTextStyle,
                items: _unitesDisponibles.map((unite) {
                  return DropdownMenuItem(value: unite, child: Text(unite));
                }).toList(),
                onChanged: (value) => setState(() => _selectedUniteSection = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: _sectionDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: title, icon: icon),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _sectionDecoration => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey.shade200),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
    ],
  );

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: _footerDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_buildCancelButton(), const SizedBox(width: 12), _buildSubmitButton()],
      ),
    );
  }

  BoxDecoration get _footerDecoration => BoxDecoration(
    color: Colors.grey.shade50,
    border: Border(top: BorderSide(color: Colors.grey.shade200)),
    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
  );

  Widget _buildCancelButton() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        focusNode: _focusNodes['annuler'],
        onPressed: () => Navigator.of(context).pop(),
        style: _cancelButtonStyle,
        icon: Icon(Icons.close, size: 18, color: Colors.grey.shade700),
        label: Text('Annuler', style: _cancelButtonTextStyle),
      ),
    );
  }

  ButtonStyle get _cancelButtonStyle => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    side: BorderSide(color: Colors.grey.shade400),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  TextStyle get _cancelButtonTextStyle =>
      TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500);

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        focusNode: _focusNodes['creer'],
        onPressed: _saveArticle,
        style: _submitButtonStyle,
        icon: Icon(_isEditMode ? Icons.check_circle : Icons.add_circle, size: 18),
        label: Text(_isEditMode ? 'Enregistrer' : 'Créer Article', style: _submitButtonTextStyle),
      ),
    );
  }

  ButtonStyle get _submitButtonStyle => ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    backgroundColor: Colors.blue.shade600,
    foregroundColor: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  TextStyle get _submitButtonTextStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = _createArticleCompanion();

      if (_isEditMode) {
        await DatabaseService().database.updateArticle(companion);
      } else {
        await DatabaseService().database.insertArticle(companion);
      }

      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  ArticlesCompanion _createArticleCompanion() {
    final cmup = _calculateCmup();

    return ArticlesCompanion(
      designation: drift.Value(_controllers['designation']!.text.trim()),
      u1: drift.Value(_controllers['u1']?.text.trim()),
      u2: drift.Value(_controllers['u2']?.text.trim()),
      u3: drift.Value(_controllers['u3']?.text.trim()),
      tu2u1: drift.Value(double.tryParse(_controllers['tu2u1']?.text ?? '')),
      tu3u2: drift.Value(double.tryParse(_controllers['tu3u2']?.text ?? '')),
      pvu1: drift.Value(double.tryParse(_controllers['pvu1']?.text ?? '')),
      pvu2: drift.Value(double.tryParse(_controllers['pvu2']?.text ?? '')),
      pvu3: drift.Value(double.tryParse(_controllers['pvu3']?.text ?? '')),
      sec: drift.Value(_controllers['sec']?.text.trim()),
      usec: drift.Value(_selectedUniteSection != null ? 1.0 : null),
      cmup: drift.Value(cmup),
      dep: drift.Value(_selectedDepot),
      action: const drift.Value('A'),
      categorie: drift.Value(_controllers['categorie']?.text.trim()),
      classification: drift.Value(_controllers['classification']?.text.trim()),
      emb: drift.Value(_controllers['emb']?.text.trim()),
    );
  }

  double _calculateCmup() {
    final pvu3 = double.tryParse(_controllers['pvu3']?.text ?? '');
    final pvu2 = double.tryParse(_controllers['pvu2']?.text ?? '');
    final pvu1 = double.tryParse(_controllers['pvu1']?.text ?? '');

    if (pvu3 != null) return pvu3;
    if (pvu2 != null) return pvu2;
    if (pvu1 != null) return pvu1;

    return 0.0;
  }

  void _showSuccessMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article enregistré avec succès'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  void _showErrorMessage(String error) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red));
  }

  void _debouncedUpdateUnites() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateUnitesDisponibles();
    });
  }

  void _updateUnitesDisponibles() {
    final unites = <String>[];

    final u1 = _controllers['u1']?.text.trim();
    final u2 = _controllers['u2']?.text.trim();
    final u3 = _controllers['u3']?.text.trim();

    if (u1?.isNotEmpty == true) unites.add(u1!);
    if (u2?.isNotEmpty == true) unites.add(u2!);
    if (u3?.isNotEmpty == true) unites.add(u3!);

    setState(() {
      _unitesDisponibles = unites;
      _updateSelectedUnite(unites);
    });
  }

  void _updateSelectedUnite(List<String> unites) {
    if (unites.isEmpty) {
      _selectedUniteSection = null;
      return;
    }

    // For new articles, select first unit by default
    if (widget.article == null || _selectedUniteSection == null) {
      _selectedUniteSection = unites.first;
      return;
    }

    // Keep current selection if still valid
    if (!unites.contains(_selectedUniteSection)) {
      _selectedUniteSection = unites.first;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    // Disposer tous les FocusNodes
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }

    super.dispose();
  }
}
