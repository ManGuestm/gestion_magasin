import 'package:flutter/material.dart';

import '../../mixins/form_navigation_mixin.dart';
import '../../services/stock_management_service.dart';
import '../common/base_modal.dart';

class MouvementStockModal extends StatefulWidget {
  final String? refArticle;
  final TypeMouvement? typeMouvement;

  const MouvementStockModal({
    super.key,
    this.refArticle,
    this.typeMouvement,
  });

  @override
  State<MouvementStockModal> createState() => _MouvementStockModalState();
}

class _MouvementStockModalState extends State<MouvementStockModal> with FormNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _refArticleController = TextEditingController();
  final _depotController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _numeroDocController = TextEditingController();
  final _clientController = TextEditingController();
  final _fournisseurController = TextEditingController();
  final _libelleController = TextEditingController();

  TypeMouvement _typeMouvement = TypeMouvement.entree;
  String _uniteEntree = 'U1';
  String _uniteSortie = 'U1';

  @override
  void initState() {
    super.initState();
    if (widget.refArticle != null) {
      _refArticleController.text = widget.refArticle!;
    }
    if (widget.typeMouvement != null) {
      _typeMouvement = widget.typeMouvement!;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusFirstField();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Mouvement de Stock',
      width: 600,
      height: 500,
      onSave: _enregistrerMouvement,
      content: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTypeMouvement(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildFormField(
                      controller: _refArticleController,
                      label: 'Référence Article',
                      autofocus: true,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildFormField(
                      controller: _depotController,
                      label: 'Dépôt',
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildFormField(
                      controller: _quantiteController,
                      label: 'Quantité',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildFormField(
                      controller: _prixController,
                      label: 'Prix Unitaire',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildFormField(
                controller: _numeroDocController,
                label: 'N° Document',
              ),
              const SizedBox(height: 16),
              if (_typeMouvement == TypeMouvement.sortie)
                buildFormField(
                  controller: _clientController,
                  label: 'Client',
                ),
              if (_typeMouvement == TypeMouvement.entree)
                buildFormField(
                  controller: _fournisseurController,
                  label: 'Fournisseur',
                ),
              const SizedBox(height: 16),
              buildFormField(
                controller: _libelleController,
                label: 'Libellé',
              ),
              const SizedBox(height: 16),
              _buildUnites(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeMouvement() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type de mouvement:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: TypeMouvement.values.map((type) {
              return GestureDetector(
                onTap: () => setState(() => _typeMouvement = type),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeMouvement == type ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_getTypeLabel(type)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnites() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _uniteEntree,
            decoration: const InputDecoration(
              labelText: 'Unité Entrée',
              border: OutlineInputBorder(),
            ),
            items: ['U1', 'U2', 'U3'].map((unite) {
              return DropdownMenuItem(value: unite, child: Text(unite));
            }).toList(),
            onChanged: (value) => setState(() => _uniteEntree = value!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _uniteSortie,
            decoration: const InputDecoration(
              labelText: 'Unité Sortie',
              border: OutlineInputBorder(),
            ),
            items: ['U1', 'U2', 'U3'].map((unite) {
              return DropdownMenuItem(value: unite, child: Text(unite));
            }).toList(),
            onChanged: (value) => setState(() => _uniteSortie = value!),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(TypeMouvement type) {
    switch (type) {
      case TypeMouvement.entree:
        return 'Entrée';
      case TypeMouvement.sortie:
        return 'Sortie';
      case TypeMouvement.transfert:
        return 'Transfert';
      case TypeMouvement.inventaire:
        return 'Inventaire';
    }
  }

  Future<void> _enregistrerMouvement() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final mouvement = StockMovement(
        refArticle: _refArticleController.text,
        depot: _depotController.text,
        type: _typeMouvement,
        quantite: double.parse(_quantiteController.text),
        prixUnitaire: double.parse(_prixController.text),
        numeroDocument: _numeroDocController.text.isEmpty ? null : _numeroDocController.text,
        client: _clientController.text.isEmpty ? null : _clientController.text,
        fournisseur: _fournisseurController.text.isEmpty ? null : _fournisseurController.text,
        libelle: _libelleController.text.isEmpty ? null : _libelleController.text,
        uniteEntree: _uniteEntree,
        uniteSortie: _uniteSortie,
      );

      await StockManagementService().enregistrerMouvement(mouvement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mouvement enregistré avec succès'),
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

  @override
  void dispose() {
    _refArticleController.dispose();
    _depotController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _numeroDocController.dispose();
    _clientController.dispose();
    _fournisseurController.dispose();
    _libelleController.dispose();
    super.dispose();
  }
}