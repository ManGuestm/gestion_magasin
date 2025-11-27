import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  List<Depot> _depots = [];
  String? _selectedDepot;
  String? _selectedUniteSection;
  List<String> _unitesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadDepots();
    _initControllers();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.article != null;

    return Dialog(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => handleKeyEvent(event),
        child: Container(
          width: 800,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Modifier Article' : 'Nouvel Article',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDesignationField(),
                        const SizedBox(height: 16),
                        _buildUnitsSection(),
                        const SizedBox(height: 16),
                        _buildPricesSection(),
                        const SizedBox(height: 16),
                        _buildCategorySection(),
                        const SizedBox(height: 16),
                        _buildStockSection(),
                      ],
                    ),
                  ),
                ),
              ),
              // Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton Annuler
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Valider/Créer
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade500, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: _saveArticle,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEdit ? Icons.check_circle_outline : Icons.add_circle_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEdit ? 'Valider' : 'Créer',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildDesignationField() {
    return buildFormField(
      controller: _controllers['designation']!,
      label: 'Désignation *',
      autofocus: true,
      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
    );
  }

  Widget _buildUnitsSection() {
    return _buildSection(
      title: 'Unités et conversions',
      icon: Icons.straighten,
      children: [
        Row(
          children: [
            Expanded(
                child: buildFormField(
                    controller: _controllers['u1']!,
                    label: 'Unité 1',
                    onChanged: (value) => _updateUnitesDisponibles())),
            const SizedBox(width: 16),
            Expanded(
                child: buildFormField(
                    controller: _controllers['tu2u1']!,
                    label: 'Taux U2/U1',
                    keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: buildFormField(
                    controller: _controllers['u2']!,
                    label: 'Unité 2',
                    onChanged: (value) => _updateUnitesDisponibles())),
            const SizedBox(width: 16),
            Expanded(
                child: buildFormField(
                    controller: _controllers['tu3u2']!,
                    label: 'Taux U3/U2',
                    keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: buildFormField(
                    controller: _controllers['u3']!,
                    label: 'Unité 3',
                    onChanged: (value) => _updateUnitesDisponibles())),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 40,
                child: DropdownButtonFormField<String>(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  initialValue: _selectedDepot,
                  decoration: const InputDecoration(
                    labelText: 'Dépôt par défaut',
                    border: OutlineInputBorder(),
                  ),
                  items: _depots.map((depot) {
                    return DropdownMenuItem(
                        value: depot.depots,
                        child: Text(
                          depot.depots,
                          style: const TextStyle(fontSize: 12.0),
                        ));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedDepot = value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricesSection() {
    return _buildSection(
      title: 'Prix de vente',
      icon: Icons.attach_money,
      children: [
        Row(
          children: [
            Expanded(
                child: buildFormField(
                    controller: _controllers['pvu1']!,
                    label: 'Prix Vente U1',
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: buildFormField(
                    controller: _controllers['pvu2']!,
                    label: 'Prix Vente U2',
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: buildFormField(
                    controller: _controllers['pvu3']!,
                    label: 'Prix Vente U3',
                    keyboardType: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return _buildSection(
      title: 'Catégorie et classification',
      icon: Icons.category,
      children: [
        Row(
          children: [
            Expanded(child: buildFormField(controller: _controllers['categorie']!, label: 'Catégorie')),
            const SizedBox(width: 16),
            Expanded(
                child: buildFormField(controller: _controllers['classification']!, label: 'Classification')),
            const SizedBox(width: 16),
            Expanded(child: buildFormField(controller: _controllers['emb']!, label: 'Emballage')),
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
            Expanded(child: buildFormField(controller: _controllers['sec']!, label: 'Section')),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedUniteSection,
                decoration: const InputDecoration(
                  labelText: 'Unité Section',
                  border: OutlineInputBorder(),
                ),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  void _initControllers() {
    final article = widget.article;
    _controllers['designation'] = TextEditingController(text: article?.designation ?? '');
    _controllers['u1'] = TextEditingController(text: article?.u1 ?? '');
    _controllers['u2'] = TextEditingController(text: article?.u2 ?? '');
    _controllers['u3'] = TextEditingController(text: article?.u3 ?? '');
    _controllers['tu2u1'] = TextEditingController(text: article?.tu2u1?.toString() ?? '');
    _controllers['tu3u2'] = TextEditingController(text: article?.tu3u2?.toString() ?? '');
    _controllers['pvu1'] = TextEditingController(text: article?.pvu1?.toString() ?? '');
    _controllers['pvu2'] = TextEditingController(text: article?.pvu2?.toString() ?? '');
    _controllers['pvu3'] = TextEditingController(text: article?.pvu3?.toString() ?? '');
    _controllers['categorie'] = TextEditingController(text: article?.categorie ?? 'Catégorie articles');
    _controllers['classification'] = TextEditingController(text: article?.classification ?? 'Marchandises');
    _controllers['emb'] = TextEditingController(text: article?.emb ?? '');
    _controllers['sec'] = TextEditingController(text: article?.sec ?? '');

    _selectedDepot = article?.dep;
    _updateUnitesDisponibles();
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

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Calculer le CMUP selon la priorité : pvu3 > pvu2 > pvu1
      double? pvu3 = double.tryParse(_controllers['pvu3']?.text ?? '');
      double? pvu2 = double.tryParse(_controllers['pvu2']?.text ?? '');
      double? pvu1 = double.tryParse(_controllers['pvu1']?.text ?? '');

      double cmup = 0.0;
      if (pvu3 != null) {
        cmup = pvu3;
      } else if (pvu2 != null) {
        cmup = pvu2;
      } else if (pvu1 != null) {
        cmup = pvu1;
      }

      final companion = ArticlesCompanion(
        designation: drift.Value(_controllers['designation']!.text.trim()),
        u1: drift.Value(_controllers['u1']?.text.trim()),
        u2: drift.Value(_controllers['u2']?.text.trim()),
        u3: drift.Value(_controllers['u3']?.text.trim()),
        tu2u1: drift.Value(double.tryParse(_controllers['tu2u1']?.text ?? '')),
        tu3u2: drift.Value(double.tryParse(_controllers['tu3u2']?.text ?? '')),
        pvu1: drift.Value(pvu1),
        pvu2: drift.Value(pvu2),
        pvu3: drift.Value(pvu3),
        sec: drift.Value(_controllers['sec']?.text.trim()),
        usec: drift.Value(_selectedUniteSection != null ? 1.0 : null),
        cmup: drift.Value(cmup),
        dep: drift.Value(_selectedDepot),
        action: const drift.Value('A'),
        categorie: drift.Value(_controllers['categorie']?.text.trim()),
        classification: drift.Value(_controllers['classification']?.text.trim()),
        emb: drift.Value(_controllers['emb']?.text.trim()),
      );

      if (widget.article == null) {
        await DatabaseService().database.insertArticle(companion);
      } else {
        await DatabaseService().database.updateArticle(companion);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      // Par défaut, sélectionner l'unité 1 si disponible
      if (unites.isNotEmpty && (widget.article == null || _selectedUniteSection == null)) {
        _selectedUniteSection = unites.first;
      }
      // Vérifier si l'unité sélectionnée est encore valide
      if (_selectedUniteSection != null && !unites.contains(_selectedUniteSection)) {
        _selectedUniteSection = unites.isNotEmpty ? unites.first : null;
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
