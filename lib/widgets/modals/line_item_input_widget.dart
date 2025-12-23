import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../providers/vente_providers.dart';
import '../../utils/focus_node_manager.dart';

/// Widget pour la saisie des détails de ligne de vente
class LineItemInputWidget extends ConsumerStatefulWidget {
  final Article? selectedArticle;
  final String? selectedUnite;
  final String? selectedDepot;
  final TextEditingController quantiteController;
  final TextEditingController prixController;
  final TextEditingController montantController;
  final TextEditingController depotController;
  final TextEditingController uniteController;
  final FocusNodeManager focusNodeManager;
  final List<Depot> depots;
  final List<Article> articles;
  final VoidCallback onQuantiteChanged;
  final VoidCallback onPrixChanged;
  final VoidCallback onArticleSelected;
  final ValueChanged<String?> onUniteChanged;
  final ValueChanged<String?> onDepotChanged;
  final bool isModifyingLine;

  const LineItemInputWidget({
    super.key,
    required this.selectedArticle,
    required this.selectedUnite,
    required this.selectedDepot,
    required this.quantiteController,
    required this.prixController,
    required this.montantController,
    required this.depotController,
    required this.uniteController,
    required this.focusNodeManager,
    required this.depots,
    required this.articles,
    required this.onQuantiteChanged,
    required this.onPrixChanged,
    required this.onArticleSelected,
    required this.onUniteChanged,
    required this.onDepotChanged,
    required this.isModifyingLine,
  });

  @override
  ConsumerState<LineItemInputWidget> createState() => _LineItemInputWidgetState();
}

class _LineItemInputWidgetState extends ConsumerState<LineItemInputWidget> {
  late FocusNode _quantiteFocusNode;
  late FocusNode _prixFocusNode;

  @override
  void initState() {
    super.initState();
    _quantiteFocusNode = widget.focusNodeManager.quantite;
    _prixFocusNode = widget.focusNodeManager.prix;

    widget.quantiteController.addListener(widget.onQuantiteChanged);
    widget.prixController.addListener(widget.onPrixChanged);
  }

  @override
  void dispose() {
    widget.quantiteController.removeListener(widget.onQuantiteChanged);
    widget.prixController.removeListener(widget.onPrixChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quantité
        TextField(
          controller: widget.quantiteController,
          focusNode: _quantiteFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantité',
            hintText: 'Saisissez la quantité',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _calculateAmount();
          },
        ),
        const SizedBox(height: 12),

        // Prix unitaire
        TextField(
          controller: widget.prixController,
          focusNode: _prixFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Prix unitaire',
            hintText: 'Saisissez le prix',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _calculateAmount();
          },
        ),
        const SizedBox(height: 12),

        // Montant (lecture seule)
        TextField(
          controller: widget.montantController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Montant',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  void _calculateAmount() {
    final quantite = double.tryParse(widget.quantiteController.text) ?? 0.0;
    final prix = double.tryParse(widget.prixController.text.replaceAll(' ', '')) ?? 0.0;
    final priceService = ref.read(priceCalculationServiceProvider);

    final montant = priceService.calculateLineAmount(quantite, prix);
    widget.montantController.text = montant > 0 ? AppFunctions.formatNumber(montant) : '';
  }
}
