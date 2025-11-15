import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class AddArticleModal extends StatefulWidget {
  final Article? article;

  const AddArticleModal({super.key, this.article});

  @override
  State<AddArticleModal> createState() => _AddArticleModalState();
}

class _AddArticleModalState extends State<AddArticleModal> {
  final Map<String, TextEditingController> _controllers = {};
  List<Depot> _depots = [];
  String? _selectedDepot;

  @override
  void initState() {
    super.initState();
    _loadDepots();
    _initControllers();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.article != null;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          width: 450,
          height: 500,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isEdit),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDesignationField(),
                      const SizedBox(height: 12),
                      _buildUnitsSection(),
                      const SizedBox(height: 12),
                      _buildPricesSection(),
                      const SizedBox(height: 12),
                      _buildCategorySection(),
                      const SizedBox(height: 12),
                      _buildStockSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildButtons(isEdit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        isEdit ? 'MODIFIER ...' : 'CREER ...',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDesignationField() {
    return _buildField('designation', 'Désignation', required: true);
  }

  Widget _buildUnitsSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildField('u1', 'Unité 1')),
              const SizedBox(width: 8),
              Expanded(child: _buildField('tu2u1', 'Taux Unité 2 / Unité 1')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildField('u2', 'Unité 2')),
              const SizedBox(width: 8),
              Expanded(child: _buildField('tu3u2', 'Taux Unité 3 / Unité 2')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildField('u3', 'Unité 3')),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dépôts', style: TextStyle(fontSize: 11, color: Colors.red)),
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[600]!),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDepot,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 11, color: Colors.black),
                          items: _depots.map((depot) {
                            return DropdownMenuItem<String>(
                              value: depot.depots,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(depot.depots),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDepot = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricesSection() {
    return Row(
      children: [
        Expanded(child: _buildField('pvu1', 'Prix de vente pour Unité 1')),
        const SizedBox(width: 8),
        Expanded(child: _buildField('pvu2', 'Prix de vente pour Unité 2')),
        const SizedBox(width: 8),
        Expanded(child: _buildField('pvu3', 'Prix de vente pour Unité 3')),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Row(
      children: [
        Expanded(child: _buildField('categorie', 'Catégorie', defaultValue: 'Catégorie articles')),
        const SizedBox(width: 8),
        Expanded(child: _buildField('classification', 'Classification', defaultValue: 'Marchandises')),
        const SizedBox(width: 8),
        Expanded(child: _buildField('emb', 'Emballage')),
      ],
    );
  }

  Widget _buildStockSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stocks de sécurité', style: TextStyle(fontSize: 11, color: Colors.red)),
              _buildField('sec', '', showLabel: false),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unité', style: TextStyle(fontSize: 11)),
              _buildField('usec', '', showLabel: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String key, String label,
      {bool required = false, String? defaultValue, bool showLabel = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: required ? Colors.red : Colors.black,
            ),
          ),
        Container(
          height: 22,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: _controllers[key],
            style: const TextStyle(fontSize: 11),
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

  Widget _buildButtons(bool isEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: TextButton(
            onPressed: _saveArticle,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isEdit ? 'Valider' : 'Valider',
              style: const TextStyle(fontSize: 12, color: Colors.black),
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
              'Annuler',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
        ),
      ],
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
    _controllers['usec'] = TextEditingController(text: article?.usec?.toString() ?? '');

    _selectedDepot = article?.dep;
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
    if (_controllers['designation']?.text.trim().isEmpty ?? true) {
      return;
    }

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
        usec: drift.Value(double.tryParse(_controllers['usec']?.text ?? '')),
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

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
