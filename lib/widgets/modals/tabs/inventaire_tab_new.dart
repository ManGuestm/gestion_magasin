import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../models/inventaire_state.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/stock_converter.dart';
import '../../common/article_navigation_autocomplete.dart';

/// Widget autonome pour l'affichage du tab Inventaire Physique (Saisie)
///
/// Responsabilités:
/// - Mode dual: Affichage (avant inventaire) / Édition (pendant inventaire)
/// - Saisie des quantités physiques (U1, U2, U3)
/// - Calcul des écarts en temps réel
/// - Filtres par dépôt et recherche article
/// - Pagination de la liste
/// - Import/Export et gestion de l'inventaire
///
/// Utilise InventaireState pour immutabilité et callbacks pour mutations.
class InventaireTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  final List<DepartData> stocks;
  final bool inventaireMode;
  final DateTime? dateInventaire;
  final String selectedDepotInventaire;
  final Map<String, Map<String, dynamic>> inventairePhysique;

  // === CALLBACKS ===
  final Function() onStartInventaire;
  final Function() onCancelInventaire;
  final Function() onSaveInventaire;
  final Function() onImportInventaire;
  final Function(String designation, Map<String, double> values) onSaisie;
  final Function(String depot) onDepotChanged;
  final Function(int page) onPageChanged;
  final Function(int?) onHoverChanged;
  final Function(Article article) onScrollToArticle;

  const InventaireTabNew({
    super.key,
    required this.state,
    required this.stocks,
    required this.inventaireMode,
    required this.dateInventaire,
    required this.selectedDepotInventaire,
    required this.inventairePhysique,
    required this.onStartInventaire,
    required this.onCancelInventaire,
    required this.onSaveInventaire,
    required this.onImportInventaire,
    required this.onSaisie,
    required this.onDepotChanged,
    required this.onPageChanged,
    required this.onHoverChanged,
    required this.onScrollToArticle,
  });

  @override
  State<InventaireTabNew> createState() => _InventaireTabNewState();
}

class _InventaireTabNewState extends State<InventaireTabNew> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key, double value) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value > 0 ? value.toString() : '');
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inventaireMode) {
      return _buildStartMode();
    }
    return _buildEditMode();
  }

  /// Mode avant le démarrage de l'inventaire
  Widget _buildStartMode() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Démarrez un inventaire pour saisir les quantités physiques',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Mode édition pendant l'inventaire
  Widget _buildEditMode() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildList()),
        _buildPagination(),
      ],
    );
  }

  /// En-tête avec contrôles d'inventaire
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Inventaire Physique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Recherche article
              SizedBox(
                width: 200,
                child: ArticleNavigationAutocomplete(
                  articles: widget.state.filteredArticles,
                  focusNode: _searchFocusNode,
                  onArticleChanged: (article) {
                    if (article != null) {
                      widget.onScrollToArticle(article);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Rechercher article...',
                    prefixIcon: Icon(Icons.search, size: 16),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              // Sélection dépôt
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      widget.selectedDepotInventaire.isNotEmpty &&
                          widget.state.depots
                              .where((d) => d != 'Tous')
                              .contains(widget.selectedDepotInventaire)
                      ? widget.selectedDepotInventaire
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Dépôt',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  items: widget.state.depots
                      .where((depot) => depot != 'Tous')
                      .map(
                        (depot) => DropdownMenuItem(
                          value: depot,
                          child: Text(depot, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDepotChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Boutons d'action
              ElevatedButton.icon(
                onPressed: widget.onSaveInventaire,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Sauvegarder'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onCancelInventaire,
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Annuler'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
          if (widget.dateInventaire != null) ...[
            const SizedBox(height: 8),
            Text(
              'Inventaire du ${AppDateUtils.formatDate(widget.dateInventaire!)} - Dépôt: ${widget.selectedDepotInventaire}',
              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  /// Liste virtualisée des articles
  Widget _buildList() {
    return _buildVirtualizedInventaireList();
  }

  /// Liste virtualisée avec en-tête et items
  Widget _buildVirtualizedInventaireList() {
    final startIndex = widget.state.inventairePage * widget.state.itemsPerPage;
    final endIndex = (startIndex + widget.state.itemsPerPage).clamp(0, widget.state.filteredArticles.length);
    final pageArticles = widget.state.filteredArticles.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: _scrollController,
      itemCount: pageArticles.length + 1, // +1 pour l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTableHeader();
        }

        final article = pageArticles[index - 1];
        return _buildInventaireListItem(article, index - 1);
      },
    );
  }

  /// En-tête du tableau
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(bottom: BorderSide(color: Colors.orange[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 3,
            child: Text('Stocks Disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              'Physique U1',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Physique U2',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Physique U3',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text('Écarts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Item de la liste d'inventaire
  Widget _buildInventaireListItem(Article article, int itemIndex) {
    // Obtenir les stocks spécifiques au dépôt sélectionné
    DepartData? depotStock;
    try {
      depotStock = widget.stocks.firstWhere(
        (s) => s.designation == article.designation && s.depots == widget.selectedDepotInventaire,
      );
    } catch (e) {
      depotStock = null;
    }

    // Stocks théoriques
    final stockU1 = depotStock?.stocksu1?.toDouble() ?? article.stocksu1?.toDouble() ?? 0.0;
    final stockU2 = depotStock?.stocksu2?.toDouble() ?? article.stocksu2?.toDouble() ?? 0.0;
    final stockU3 = depotStock?.stocksu3?.toDouble() ?? article.stocksu3?.toDouble() ?? 0.0;

    // Vérifier quelles unités sont disponibles
    final hasU1 = article.u1 != null && article.u1!.isNotEmpty;
    final hasU2 = article.u2 != null && article.u2!.isNotEmpty;
    final hasU3 = article.u3 != null && article.u3!.isNotEmpty;

    // Quantités physiques saisies
    final key = '${article.designation}_${widget.selectedDepotInventaire}';
    final physiqueU1 = widget.inventairePhysique[key]?['u1'] ?? 0;
    final physiqueU2 = widget.inventairePhysique[key]?['u2'] ?? 0;
    final physiqueU3 = widget.inventairePhysique[key]?['u3'] ?? 0;

    // Calculer écarts
    final stockTotalU3Theorique = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    final stockTotalU3Physique = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: physiqueU1,
      stockU2: physiqueU2,
      stockU3: physiqueU3,
    );

    final ecartTotalU3 = stockTotalU3Physique - stockTotalU3Theorique;

    final ecartOptimal = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: ecartTotalU3.abs(),
    );

    final ecartFormate = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: ecartOptimal['u1']!,
      stockU2: ecartOptimal['u2']!,
      stockU3: ecartOptimal['u3']!,
    );

    final isHovered = widget.state.hoveredInventaireIndex == itemIndex;
    final ecartColor = ecartTotalU3 == 0
        ? Colors.grey[700]
        : ecartTotalU3 > 0
        ? Colors.green[700]
        : Colors.red[700];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHoverChanged(itemIndex),
      onExit: (_) => widget.onHoverChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Désignation
            Expanded(flex: 3, child: Text(article.designation, style: const TextStyle(fontSize: 11))),
            // Catégorie
            Expanded(
              flex: 2,
              child: Text(article.categorie ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
            // Stocks disponibles
            Expanded(
              flex: 3,
              child: Text(
                'U1: ${stockU1.toStringAsFixed(0)} ${article.u1 ?? ''}, '
                'U2: ${stockU2.toStringAsFixed(0)} ${article.u2 ?? ''}, '
                'U3: ${stockU3.toStringAsFixed(0)} ${article.u3 ?? ''}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
            // Champs saisie U1
            if (hasU1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: _getController('${key}_u1', physiqueU1),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    onChanged: (value) {
                      final u1 = double.tryParse(value) ?? 0;
                      widget.onSaisie(article.designation, {'u1': u1, 'u2': physiqueU2, 'u3': physiqueU3});
                    },
                  ),
                ),
              )
            else
              const Expanded(
                child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
              ),
            // Champs saisie U2
            if (hasU2)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: _getController('${key}_u2', physiqueU2),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    onChanged: (value) {
                      final u2 = double.tryParse(value) ?? 0;
                      widget.onSaisie(article.designation, {'u1': physiqueU1, 'u2': u2, 'u3': physiqueU3});
                    },
                  ),
                ),
              )
            else
              const Expanded(
                child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
              ),
            // Champs saisie U3
            if (hasU3)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: _getController('${key}_u3', physiqueU3),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    onChanged: (value) {
                      final u3 = double.tryParse(value) ?? 0;
                      widget.onSaisie(article.designation, {'u1': physiqueU1, 'u2': physiqueU2, 'u3': u3});
                    },
                  ),
                ),
              )
            else
              const Expanded(
                child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
              ),
            // Écarts
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ecartFormate,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: ecartColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pagination
  Widget _buildPagination() {
    final totalPages = widget.state.totalInventairePages;

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < totalPages; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: i == widget.state.inventairePage ? null : () => widget.onPageChanged(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: i == widget.state.inventairePage ? Colors.orange : Colors.grey[300],
                  foregroundColor: i == widget.state.inventairePage ? Colors.white : Colors.black,
                ),
                child: Text('${i + 1}'),
              ),
            ),
        ],
      ),
    );
  }
}
