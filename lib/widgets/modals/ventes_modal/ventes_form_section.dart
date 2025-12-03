import 'package:flutter/material.dart';
import '../../../database/database.dart';
import '../../common/article_navigation_autocomplete.dart';
import '../../common/enhanced_autocomplete.dart';
import 'ventes_controller.dart';

class VentesFormSection extends StatelessWidget {
  final VentesController controller;
  final bool tousDepots;

  const VentesFormSection({
    super.key,
    required this.controller,
    required this.tousDepots,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top section with status and basic info
        _buildTopSection(context),
        // Article selection section
        _buildArticleSelectionSection(context),
      ],
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E6FA),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              // Enregistrement status
              _buildStatusDropdown(),
              const SizedBox(width: 16),
              // Basic info fields
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildInfoField('N° ventes', controller.numVentesController, 80),
                    _buildInfoField('Date', controller.dateController, 100),
                    _buildInfoField('N° Facture/ BL', controller.nFactureController, 80),
                    _buildInfoField('Heure', controller.heureController, 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Client field
          _buildClientField(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          color: controller.selectedVerification == 'JOURNAL'
              ? Colors.green
              : Colors.orange,
          child: const Text(
            'Enregistrement',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 120,
          height: 25,
          child: DropdownButtonFormField<String>(
            initialValue: controller.selectedVerification,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            items: const [
              DropdownMenuItem(
                value: 'BROUILLARD',
                child: Text('Brouillard', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'JOURNAL',
                child: Text('Journal', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: controller.isExistingPurchase
                ? null
                : (value) {
                    // Gérer le changement
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, double width) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        SizedBox(
          width: width,
          height: 25,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              fillColor: Color(0xFFF5F5F5),
              filled: true,
            ),
            readOnly: true,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildClientField() {
    return Row(
      children: [
        const Text('Clients', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 25,
            child: EnhancedAutocomplete<CltData>(
              options: controller.clients,
              displayStringForOption: (client) => client.rsoc,
              onSelected: (client) {
                // Gérer la sélection du client
              },
              controller: controller.clientController,
              focusNode: controller.clientFocusNode,
              hintText: 'Rechercher un client...',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              onSubmitted: (value) async {
                // Gérer la soumission
              },
              onTabPressed: () {
                controller.designationFocusNode.requestFocus();
              },
              onShiftTabPressed: () => controller.clientFocusNode.requestFocus(),
              enabled: controller.selectedVerification != 'JOURNAL',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleSelectionSection(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E6FA),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Désignation Articles
          _buildDesignationField(),
          const SizedBox(width: 8),
          // Dépôts (si tous dépôts)
          if (tousDepots) ...[
            _buildDepotField(),
            const SizedBox(width: 8),
          ],
          // Unités
          _buildUniteField(),
          const SizedBox(width: 8),
          // Quantités
          _buildQuantiteField(),
          const SizedBox(width: 8),
          // Prix
          _buildPrixField(),
          // Boutons Ajouter/Annuler
          if (controller.isClientSelected && controller.selectedArticle != null) ...[
            const SizedBox(width: 8),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignationField() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Désignation Articles', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 25,
            child: ArticleNavigationAutocomplete(
              articles: controller.articles,
              initialArticle: _getLastAddedArticle(),
              selectedArticle: controller.selectedArticle,
              onArticleChanged: (article) {
                // Gérer le changement d'article
              },
              focusNode: controller.designationFocusNode,
              hintText: controller.isClientSelected
                  ? 'Rechercher un article... (← → pour naviguer)'
                  : 'Sélectionnez d\'abord un client',
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                fillColor: controller.isClientSelected ? null : Colors.grey[200],
                filled: !controller.isClientSelected,
              ),
              style: TextStyle(
                fontSize: 12,
                color: controller.isClientSelected ? Colors.black : Colors.grey,
              ),
              onTabPressed: () => tousDepots
                  ? controller.depotFocusNode.requestFocus()
                  : controller.uniteFocusNode.requestFocus(),
              onShiftTabPressed: () => controller.clientFocusNode.requestFocus(),
              enabled: controller.isClientSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepotField() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dépôts', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 25,
            child: EnhancedAutocomplete<String>(
              options: controller.depots.map((depot) => depot.depots).toList(),
              displayStringForOption: (depot) => depot,
              controller: controller.depotController,
              focusNode: controller.depotFocusNode,
              onSelected: (depot) {
                // Gérer la sélection du dépôt
              },
              hintText: 'Dépôt...',
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                fillColor: controller.isClientSelected ? null : Colors.grey[200],
                filled: !controller.isClientSelected,
              ),
              style: TextStyle(
                fontSize: 11,
                color: controller.isClientSelected ? Colors.black : Colors.grey,
              ),
              enabled: controller.isClientSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniteField() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unités', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 25,
            child: EnhancedAutocomplete<String>(
              options: controller.selectedArticle != null
                  ? _getUnitsForSelectedArticle()
                  : [''],
              displayStringForOption: (unit) => unit,
              controller: controller.uniteController,
              onSelected: (unit) {
                // Gérer la sélection de l'unité
              },
              focusNode: controller.uniteFocusNode,
              hintText: 'Unité...',
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                fillColor: controller.isClientSelected ? null : Colors.grey[200],
                filled: !controller.isClientSelected,
              ),
              style: TextStyle(
                fontSize: 12,
                color: controller.isClientSelected ? Colors.black : Colors.grey,
              ),
              enabled: controller.isClientSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantiteField() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quantités', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 25,
            child: TextField(
              controller: controller.quantiteController,
              focusNode: controller.quantiteFocusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                fillColor: controller.isClientSelected ? null : Colors.grey[200],
                filled: !controller.isClientSelected,
              ),
              style: TextStyle(
                fontSize: 12,
                color: controller.isClientSelected ? Colors.black : Colors.grey,
              ),
              readOnly: controller.selectedVerification == 'JOURNAL' || !controller.isClientSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrixField() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('P.U HT', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 25,
            child: TextField(
              controller: controller.prixController,
              focusNode: controller.prixFocusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                fillColor: controller.isClientSelected ? null : Colors.grey[200],
                filled: !controller.isClientSelected,
              ),
              style: TextStyle(
                fontSize: 12,
                color: controller.isClientSelected ? Colors.black : Colors.grey,
              ),
              readOnly: controller.selectedVerification == 'JOURNAL' || !controller.isClientSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            // AJOUTER/MODIFIER BUTTON
            ElevatedButton(
              focusNode: controller.ajouterFocusNode,
              onPressed: controller.isClientSelected ? controller.ajouterLigne : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isClientSelected ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 35),
              ),
              child: Text(
                controller.isModifyingLine ? 'Modifier' : 'Ajouter',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            // ANNULER BUTTON
            ElevatedButton(
              focusNode: controller.annulerFocusNode,
              onPressed: controller.isClientSelected
                  ? (controller.isModifyingLine
                      ? _annulerModificationLigne
                      : _resetArticleForm)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isClientSelected ? Colors.orange : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 35),
              ),
              child: const Text(
                'Annuler',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Méthodes auxiliaires
  Article? _getLastAddedArticle() {
    if (controller.lignesVente.isEmpty) return null;
    final lastDesignation = controller.lignesVente.last['designation'] as String?;
    if (lastDesignation == null) return null;
    return controller.articles
        .where((a) => a.designation == lastDesignation)
        .firstOrNull;
  }

  List<String> _getUnitsForSelectedArticle() {
    if (controller.selectedArticle == null) return [''];
    
    final article = controller.selectedArticle!;
    final units = <String>[];
    if (article.u1?.isNotEmpty == true) units.add(article.u1!);
    if (article.u2?.isNotEmpty == true) units.add(article.u2!);
    if (article.u3?.isNotEmpty == true) units.add(article.u3!);
    
    return units;
  }

  void _annulerModificationLigne() {
    // Implémenter l'annulation de modification
  }

  void _resetArticleForm() {
    // Réinitialiser le formulaire d'article
  }
}