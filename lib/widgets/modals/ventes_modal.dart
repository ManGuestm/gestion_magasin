import 'package:flutter/material.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../common/enhanced_autocomplete.dart';
import 'ventes_modal/ventes_controller.dart';
import 'ventes_modal/ventes_form_section.dart';
import 'ventes_modal/ventes_sidebar.dart';
import 'ventes_modal/ventes_summary_section.dart';
import 'ventes_modal/ventes_table_section.dart';

class VentesModal extends StatefulWidget {
  final bool tousDepots;

  const VentesModal({super.key, required this.tousDepots});

  @override
  State<VentesModal> createState() => _VentesModalState();
}

class _VentesModalState extends State<VentesModal> {
  final VentesController _controller = VentesController();

  @override
  void initState() {
    super.initState();
    _controller.initialize(widget.tousDepots);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _controller.handleKeyboardShortcut(event);
          return KeyEventResult.ignored;
        },
        child: Dialog(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minWidth: MediaQuery.of(context).size.width * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.99,
          ),
          backgroundColor: Colors.grey[100],
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                color: Colors.grey[100],
              ),
              child: Column(
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: 35,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                Text(
                                  'VENTES (${widget.tousDepots ? 'Tous dépôts' : 'Dépôt MAG'})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_controller.isExistingPurchase &&
                                    _controller.statutVenteActuelle != null) ...[
                                  const SizedBox(width: 16),
                                  FutureBuilder<bool>(
                                    future: _controller.isVenteContrePassee(),
                                    builder: (context, snapshot) {
                                      final isContrePassee = snapshot.data ?? false;
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: _controller.statutVenteActuelle == StatutVente.brouillard
                                              ? Colors.orange
                                              : (isContrePassee ? Colors.red : Colors.green),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        child: Text(
                                          _controller.statutVenteActuelle == StatutVente.brouillard
                                              ? 'BROUILLARD'
                                              : (isContrePassee ? 'CP' : 'JOURNALÉ'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // Main content with sidebar
                  Expanded(
                    child: Row(
                      children: [
                        // Left sidebar - Sales list
                        VentesSidebar(
                          controller: _controller,
                          isVendeur: _controller.isVendeur(),
                          tousDepots: widget.tousDepots,
                        ),

                        // Center Content - Main form
                        Expanded(
                          child: Column(
                            children: [
                              // Top section - Form
                              VentesFormSection(
                                controller: _controller,
                                tousDepots: widget.tousDepots,
                              ),

                              // Articles table section
                              Expanded(
                                child: VentesTableSection(
                                  controller: _controller,
                                  tousDepots: widget.tousDepots,
                                ),
                              ),

                              // Bottom section - Summary
                              VentesSummarySection(
                                controller: _controller,
                                tousDepots: widget.tousDepots,
                              ),

                              // Action buttons section
                              _buildActionButtons(),
                            ],
                          ),
                        ),

                        // Right sidebar - Article details
                        ValueListenableBuilder<bool>(
                          valueListenable: _controller.isRightSidebarCollapsedNotifier,
                          builder: (context, isCollapsed, _) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isCollapsed ? 40 : 280,
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.grey, width: 1)),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  // Header with toggle button
                                  Container(
                                    height: 35,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      border: const Border(
                                        bottom: BorderSide(color: Colors.grey, width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (!isCollapsed) ...[
                                          const Expanded(
                                            child: Text(
                                              'Détails Article',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                        IconButton(
                                          onPressed: _controller.toggleRightSidebar,
                                          icon: Icon(
                                            isCollapsed ? Icons.chevron_left : Icons.chevron_right,
                                            size: 16,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Content
                                  if (!isCollapsed)
                                    Expanded(
                                      child: _buildRightSidebarContent(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightSidebarContent() {
    return Column(
      children: [
        // Search field
        Container(
          padding: const EdgeInsets.all(8),
          child: EnhancedAutocomplete<Article>(
            options: _controller.articles,
            displayStringForOption: (article) => article.designation,
            onSelected: (article) {
              _controller.setSearchedArticle(article);
            },
            hintText: 'Nom de l\'article...',
            controller: _controller.searchArticleController,
            focusNode: _controller.searchArticleFocusNode,
            decoration: const InputDecoration(
              labelText: 'Rechercher article',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Article details
        Expanded(
          child: _controller.searchedArticle == null
              ? const Center(
                  child: Text(
                    'Saisissez le nom d\'un article\npour voir ses détails',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: _buildArticleDetails(),
                ),
        ),
      ],
    );
  }

  Widget _buildArticleDetails() {
    final article = _controller.searchedArticle!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Article name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            article.designation,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        // Prix de vente
        const Text(
          'PRIX DE VENTE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        _buildPriceRow(article.u1, article.pvu1),
        _buildPriceRow(article.u2, article.pvu2),
        _buildPriceRow(article.u3, article.pvu3),
        const SizedBox(height: 12),
        // Conversions
        const Text(
          'CONVERSIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        _buildConversionRow(article.u1, article.u2, article.tu2u1),
        _buildConversionRow(article.u2, article.u3, article.tu3u2),
        const SizedBox(height: 12),
        // Prix d'achat
        const Text(
          'PRIX D\'ACHAT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Text(
            'CMUP: ${AppFunctions.formatNumber(article.cmup ?? 0)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String? unite, double? prix) {
    if (unite == null || unite.isEmpty || prix == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: _controller.selectedUnite == unite ? Colors.green[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: _controller.selectedUnite == unite ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '1 $unite:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: _controller.selectedUnite == unite ? FontWeight.w500 : FontWeight.normal,
              color: _controller.selectedUnite == unite ? Colors.green[700] : Colors.black87,
            ),
          ),
          Text(
            "${AppFunctions.formatNumber(prix)} Ar",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _controller.selectedUnite == unite ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRow(String? u1, String? u2, double? taux) {
    if (taux == null || taux == 0 || u1 == null || u1.isEmpty || u2 == null || u2.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '1 ($u1) :',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
            ),
          ),
          Text(
            "$taux $u2",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFB6C1),
      ),
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        children: [
          // Bouton Nouvelle vente
          if (_controller.isExistingPurchase) ...[
            Tooltip(
              message: 'Créer nouveau (Ctrl+N)',
              child: ElevatedButton(
                onPressed: _controller.creerNouvelleVente,
                style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                child: const Text('Créer (Ctrl+N)', style: TextStyle(fontSize: 12)),
              ),
            ),
            if (_controller.peutValiderBrouillard()) ...[
              Tooltip(
                message: 'Valider la vente (F3)',
                child: ElevatedButton(
                  onPressed: _controller.validerBrouillardVersJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                  ),
                  child: const Text('Valider la vente(F3)', style: TextStyle(fontSize: 12)),
                ),
              ),
              // Bouton Contre-passer vente brouillard
              Tooltip(
                message: 'Contre-passer vente brouillard',
                child: ElevatedButton(
                  onPressed: _controller.contrePasserVenteBrouillard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                  ),
                  child: const Text('Supprimer Brouillard', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
          // Bouton Importation
          if (!_controller.isExistingPurchase)
            Tooltip(
              message: 'Importer lignes d\'achat',
              child: ElevatedButton(
                onPressed: _controller.importerLignesVente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text('Importer', style: TextStyle(fontSize: 12)),
              ),
            ),
          if (!_controller.peutValiderBrouillard()) ...[
            // Bouton Contre passer
            if (_controller.isExistingPurchase) ...[
              FutureBuilder<bool>(
                future: _controller.isVenteContrePassee(),
                builder: (context, snapshot) {
                  final isContrePassee = snapshot.data ?? false;
                  return Tooltip(
                    message: isContrePassee ? 'Vente déjà contre-passée' : 'Contre-passer (Ctrl+D)',
                    child: ElevatedButton(
                      onPressed: isContrePassee ? null : _controller.contrePasserVente,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 30),
                        backgroundColor: isContrePassee ? Colors.grey : null,
                      ),
                      child: const Text('Contre Passer (Ctrl+D)', style: TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ],
          ],
          // Bouton Modifier/Enregistrer
          Tooltip(
            message: _controller.isExistingPurchase ? 'Modifier (Ctrl+S)' : 'Enregistrer (Ctrl+S)',
            child: ElevatedButton(
              onPressed: _controller.selectedVerification == 'JOURNAL'
                  ? null
                  : (_controller.isExistingPurchase ? _controller.modifierVente : _controller.validerVente),
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.isExistingPurchase ? Colors.blue : Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 30),
              ),
              child: Text(
                _controller.isExistingPurchase ? 'Modifier (Ctrl+S)' : 'Enregistrer (Ctrl+S)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // Popup menu format papier d'impression
          PopupMenuButton<String>(
            style: ButtonStyle(
              padding: WidgetStateProperty.fromMap({
                WidgetState.hovered: const EdgeInsets.all(0),
                WidgetState.focused: const EdgeInsets.all(0),
                WidgetState.pressed: const EdgeInsets.all(0),
              }),
            ),
            menuPadding: const EdgeInsets.all(2),
            initialValue: _controller.selectedFormat,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'A4',
                child: Text('Format A4', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'A5',
                child: Text('Format A5', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'A6',
                child: Text('Format A6', style: TextStyle(fontSize: 12)),
              ),
            ],
            onSelected: (value) {
              if (value == 'facture') {
                _controller.apercuFacture();
              } else if (value == 'bl') {
                _controller.apercuBL();
              } else {
                _controller.setSelectedFormat(value);
              }
            },
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 60,
                minHeight: 18,
                maxHeight: 30,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.print, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _controller.selectedFormat,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          // Boutons d'impression et aperçu
          ..._buildPrintButtons(),
          // Bouton de fermeture
          Tooltip(
            message: 'Fermer (Echap)',
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
              child: const Text('Fermer', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrintButtons() {
    return [
      FutureBuilder<bool>(
        future: _controller.isVenteContrePassee(),
        builder: (context, snapshot) {
          final isContrePassee = snapshot.data ?? false;
          return Tooltip(
            message: 'Imprimer Facture (Ctrl+P)',
            child: ElevatedButton(
              onPressed: isContrePassee ? null : _controller.imprimerFacture,
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.selectedVerification != 'JOURNAL' ? Colors.grey : Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Imprimer Facture (Ctrl+P)', style: TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
      FutureBuilder<bool>(
        future: _controller.isVenteContrePassee(),
        builder: (context, snapshot) {
          final isContrePassee = snapshot.data ?? false;
          return Tooltip(
            message: 'Aperçu Facture',
            child: ElevatedButton(
              onPressed: isContrePassee ? null : _controller.apercuFacture,
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.selectedVerification != 'JOURNAL' ? Colors.grey : Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Aperçu Facture', style: TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
      FutureBuilder<bool>(
        future: _controller.isVenteContrePassee(),
        builder: (context, snapshot) {
          final isContrePassee = snapshot.data ?? false;
          return Tooltip(
            message: 'Imprimer Bon de Livraison (Ctrl+Shift+P)',
            child: ElevatedButton(
              onPressed: isContrePassee ? null : _controller.imprimerBL,
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.selectedVerification != 'JOURNAL' ? Colors.grey : Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Imprimer BL (Ctrl+Shift+P)', style: TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
      FutureBuilder<bool>(
        future: _controller.isVenteContrePassee(),
        builder: (context, snapshot) {
          final isContrePassee = snapshot.data ?? false;
          return Tooltip(
            message: 'Aperçu Bon de Livraison',
            child: ElevatedButton(
              onPressed: isContrePassee ? null : _controller.apercuBL,
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.selectedVerification != 'JOURNAL' ? Colors.grey : Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Aperçu BL', style: TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
    ];
  }
}
