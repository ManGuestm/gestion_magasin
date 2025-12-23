import 'package:flutter/material.dart';
import '../../database/database.dart';

/// Widget pour la saisie d'une ligne de vente
class VentesLineInputWidget extends StatelessWidget {
  final Article? selectedArticle;
  final String? selectedUnite;
  final String? selectedDepot;
  final TextEditingController quantiteController;
  final TextEditingController prixController;
  final TextEditingController montantController;
  final TextEditingController depotController;
  final TextEditingController uniteController;
  final FocusNode designationFocusNode;
  final FocusNode depotFocusNode;
  final FocusNode uniteFocusNode;
  final FocusNode quantiteFocusNode;
  final FocusNode prixFocusNode;
  final FocusNode ajouterFocusNode;
  final FocusNode annulerFocusNode;
  final List<Article> articles;
  final List<Depot> depots;
  final ValueChanged<Article?> onArticleSelected;
  final ValueChanged<String?> onUniteChanged;
  final ValueChanged<String?> onDepotChanged;
  final VoidCallback onAjouter;
  final VoidCallback onAnnuler;
  final bool showAddButton;
  final bool isModifyingLine;
  final String uniteAffichage;
  final double stockDisponible;

  const VentesLineInputWidget({
    super.key,
    required this.selectedArticle,
    required this.selectedUnite,
    required this.selectedDepot,
    required this.quantiteController,
    required this.prixController,
    required this.montantController,
    required this.depotController,
    required this.uniteController,
    required this.designationFocusNode,
    required this.depotFocusNode,
    required this.uniteFocusNode,
    required this.quantiteFocusNode,
    required this.prixFocusNode,
    required this.ajouterFocusNode,
    required this.annulerFocusNode,
    required this.articles,
    required this.depots,
    required this.onArticleSelected,
    required this.onUniteChanged,
    required this.onDepotChanged,
    required this.onAjouter,
    required this.onAnnuler,
    required this.showAddButton,
    required this.isModifyingLine,
    required this.uniteAffichage,
    required this.stockDisponible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Autocomplete<Article>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Article>.empty();
                    return articles.where((article) =>
                        article.designation.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (article) => article.designation,
                  onSelected: onArticleSelected,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: designationFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Désignation',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: depotController,
                  focusNode: depotFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Dépôt',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: onDepotChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: uniteController,
                  focusNode: uniteFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Unité',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    hintText: uniteAffichage,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: onUniteChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: quantiteController,
                  focusNode: quantiteFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'Stock: ${stockDisponible.toStringAsFixed(0)}',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: prixController,
                  focusNode: prixFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'P.U HT',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: montantController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          if (showAddButton) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isModifyingLine)
                  ElevatedButton.icon(
                    focusNode: annulerFocusNode,
                    onPressed: onAnnuler,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Annuler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  focusNode: ajouterFocusNode,
                  onPressed: onAjouter,
                  icon: Icon(isModifyingLine ? Icons.check : Icons.add, size: 16),
                  label: Text(isModifyingLine ? 'Modifier' : 'Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
