import 'package:flutter/material.dart';

import '../constants/menu_data.dart';
import '../services/menu_service.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/achats_modal.dart';
import '../widgets/modals/approximation_stocks_modal.dart';
import '../widgets/modals/articles_modal.dart';
import '../widgets/modals/banques_modal.dart';
import '../widgets/modals/clients_modal.dart';
import '../widgets/modals/company_info_modal.dart';
import '../widgets/modals/depots_modal.dart';
import '../widgets/modals/fournisseurs_modal.dart';
import '../widgets/modals/comptes_fournisseurs_modal.dart';
import '../widgets/modals/retours_achats_modal.dart';
import '../widgets/modals/statistiques_fournisseurs_modal.dart';
import '../widgets/modals/liste_achats_modal.dart';
import '../widgets/modals/liste_ventes_modal.dart';
import '../widgets/modals/mouvements_clients_modal.dart';
import '../widgets/modals/moyen_paiement_modal.dart';
import '../widgets/modals/plan_comptes_modal.dart';

import '../widgets/modals/sur_ventes_modal.dart';

import '../widgets/modals/ventes_selection_modal.dart';
import '../widgets/modals/transfert_marchandises_modal.dart';
import '../widgets/modals/gestion_emballages_modal.dart';
import '../widgets/modals/productions_modal.dart';
import '../widgets/modals/regularisation_compte_tiers_modal.dart';
import '../widgets/modals/encaissements_modal.dart';
import '../widgets/modals/decaissements_modal.dart';
import '../widgets/modals/journal_caisse_modal.dart';
import '../widgets/modals/cheques_modal.dart';
import '../widgets/modals/journal_banques_modal.dart';
import '../widgets/modals/etats_fournisseurs_modal.dart';
import '../widgets/modals/etats_clients_modal.dart';
import '../widgets/modals/etats_articles_modal.dart';
import '../widgets/modals/regularisation_compte_commerciaux_modal.dart';
import '../widgets/modals/relance_clients_modal.dart';
import '../widgets/modals/echance_fournisseurs_modal.dart';
import '../widgets/modals/variation_stocks_modal.dart';
import '../widgets/modals/mise_a_jour_valeurs_stocks_modal.dart';
import '../widgets/modals/niveau_stocks_modal.dart';
import '../widgets/modals/amortissement_immobilisations_modal.dart';
import '../widgets/modals/reactualisation_base_donnees_modal.dart';
import '../widgets/modals/effet_a_recevoir_modal.dart';
import '../widgets/modals/virements_internes_modal.dart';
import '../widgets/modals/operations_caisses_modal.dart';
import '../widgets/modals/operations_banques_modal.dart';
import '../widgets/modals/etats_commerciaux_modal.dart';
import '../widgets/modals/etats_immobilisations_modal.dart';
import '../widgets/modals/etats_autres_comptes_modal.dart';
import '../widgets/modals/statistiques_ventes_modal.dart';
import '../widgets/modals/statistiques_achats_modal.dart';
import '../widgets/modals/marges_modal.dart';
import '../widgets/modals/tableau_bord_modal.dart';
import '../widgets/modals/bilan_compte_resultat_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMenu;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _nestedOverlayEntry;
  OverlayEntry? _thirdLevelOverlayEntry;
  bool _isHoveringNestedMenu = false;
  bool _isHoveringThirdLevelMenu = false;

  static const Map<String, Widget> _modals = {
    'Informations sur la société': CompanyInfoModal(),
    'Dépôts': DepotsModal(),
    'Articles': ArticlesModal(),
    'Clients': ClientsModal(),
    'Fournisseurs': FournisseursModal(),
    'Banques': BanquesModal(),
    'Plan de comptes': PlanComptesModal(),
    'Achats': AchatsModal(),

    'Sur Ventes': SurVentesModal(),
    'Retours achats': RetoursAchatsModal(),
    'Comptes fournisseurs': ComptesFournisseursModal(),

    'Liste des achats': ListeAchatsModal(),
    'Liste des ventes': ListeVentesModal(),
    'Mouvements Clients': MouvementsClientsModal(),
    'Approximation Stocks ...': ApproximationStocksModal(),
    'Moyen de paiement': MoyenPaiementModal(),
    'Transfert de Marchandises': TransfertMarchandisesModal(),
    'Gestion Emballages': GestionEmballagesModal(),
    'Productions': ProductionsModal(),
    'Régularisation compte tiers': RegularisationCompteTiersModal(),
    'Encaissements': EncaissementsModal(),
    'Décaissements': DecaissementsModal(),
    'Journal de caisse': JournalCaisseModal(),
    'Chèques': ChequesModal(),
    'Journal des banques': JournalBanquesModal(),
    'Etats Fournisseurs': EtatsFournisseursModal(),
    'Etats Clients': EtatsClientsModal(),
    'Etats Articles': EtatsArticlesModal(),
    'Régularisation compte Commerciaux': RegularisationCompteCommerciauxModal(),
    'Relance Clients': RelanceClientsModal(),
    'Echéance Fournisseurs': EchanceFournisseursModal(),
    'Variation des stocks': VariationStocksModal(),
    'Mise à jour des valeurs de stocks': MiseAJourValeursStocksModal(),
    'Niveau des stocks (Articles à commandées)': NiveauStocksModal(),
    'Amortissement des immobilisations': AmortissementImmobilisationsModal(),
    'Réactualisation de la base de données': ReactualisationBaseDonneesModal(),
    'Effet à recevoir': EffetARecevoirModal(),
    'Virements Internes': VirementsInternesModal(),
    'Opérations Caisses': OperationsCaissesModal(),
    'Opérations Banques': OperationsBanquesModal(),
    'Etats Commerciaux': EtatsCommerciauxModal(),
    'Etats Immobilisations': EtatsImmobilisationsModal(),
    'Etats Autres Comptes': EtatsAutresComptesModal(),
    'Statistiques de ventes': StatistiquesVentesModal(),
    'Statistiques d\'achats': StatistiquesAchatsModal(),
    'Marges': MargesModal(),
    'tableau de bord': TableauBordModal(),
    'Bilan / Compte de Résultat': BilanCompteResultatModal(),
    'Gestion fournisseurs': FournisseursModal(),
    'Statistiques fournisseurs': StatistiquesFournisseursModal(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: GestureDetector(
        onTap: _closeMenu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            MenuBarWidget(onMenuTap: _showSubmenu),
            IconBarWidget(onIconTap: _handleIconTap),
            Expanded(child: Container(color: Colors.grey[200])),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 30,
      color: Colors.grey[300],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'GESTION COMMERCIALE DES GROSSISTES PPN - Administrateurs',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmenu(String menu) {
    if (_selectedMenu == menu) {
      _closeMenu();
      return;
    }

    _removeOverlay();
    setState(() => _selectedMenu = menu);

    _overlayEntry = MenuService.createSubmenuOverlay(
      menu,
      MenuService.getMenuPosition(menu),
      _handleSubmenuTap,
      onItemHover: _handleSubmenuHover,
      onMouseExit: () {
        // Delay removal to allow moving to nested menu
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringNestedMenu) {
            _removeNestedOverlay();
          }
        });
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleSubmenuTap(String item) {
    _closeMenu();
    if (item == 'Ventes') {
      showDialog(
        context: context,
        builder: (context) => const VentesSelectionModal(),
      );
    } else {
      final modal = _modals[item];
      if (modal != null) {
        showDialog(context: context, builder: (context) => modal);
      } else {
        debugPrint('Menu item tapped: $item');
      }
    }
  }

  void _handleSubmenuHover(String item, double itemPosition) {
    if (MenuData.hasSubMenu[item] == true) {
      _showNestedSubmenu(item, itemPosition);
    } else {
      if (!_isHoveringNestedMenu) {
        _removeNestedOverlay();
        _removeThirdLevelOverlay();
      }
    }
  }

  void _showNestedSubmenu(String parentItem, double itemPosition) {
    _removeNestedOverlay();

    String parentMenu = _selectedMenu ?? '';
    double baseLeftPosition = MenuService.getMenuPosition(parentMenu) + 250;
    double topPosition = 65 + itemPosition;

    _nestedOverlayEntry = MenuService.createNestedSubmenuOverlay(
      parentItem,
      baseLeftPosition,
      topPosition,
      _handleNestedSubmenuTap,
      onItemHover: (item, nestedItemPosition) =>
          _handleNestedSubmenuHover(item, nestedItemPosition, topPosition),
      onMouseEnter: () {
        _isHoveringNestedMenu = true;
      },
      onMouseExit: () {
        _isHoveringNestedMenu = false;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringNestedMenu && !_isHoveringThirdLevelMenu) {
            _removeNestedOverlay();
            _removeThirdLevelOverlay();
          }
        });
      },
    );
    Overlay.of(context).insert(_nestedOverlayEntry!);
  }

  void _handleNestedSubmenuTap(String item) {
    _closeMenu();
    final modal = _modals[item];
    if (modal != null) {
      showDialog(context: context, builder: (context) => modal);
    } else {
      debugPrint('Nested menu item tapped: $item');
    }
  }

  void _handleNestedSubmenuHover(String item, double itemPosition, [double? secondLevelTopPosition]) {
    secondLevelTopPosition ??= 65;
    if (MenuData.hasSubMenu[item] == true) {
      _showThirdLevelSubmenu(item, itemPosition, secondLevelTopPosition);
    } else {
      if (!_isHoveringThirdLevelMenu) {
        _removeThirdLevelOverlay();
      }
    }
  }

  void _showThirdLevelSubmenu(String parentItem, double itemPosition, [double? secondLevelTopPosition]) {
    secondLevelTopPosition ??= 65;
    _removeThirdLevelOverlay();

    String parentMenu = _selectedMenu ?? '';
    double firstLevelPosition = MenuService.getMenuPosition(parentMenu);
    double secondLevelPosition = firstLevelPosition + 250;
    double thirdLevelPosition = secondLevelPosition + 280;
    double topPosition = secondLevelTopPosition + itemPosition;

    _thirdLevelOverlayEntry = MenuService.createNestedSubmenuOverlay(
      parentItem,
      thirdLevelPosition,
      topPosition,
      _handleThirdLevelSubmenuTap,
      onMouseEnter: () {
        _isHoveringThirdLevelMenu = true;
      },
      onMouseExit: () {
        _isHoveringThirdLevelMenu = false;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringThirdLevelMenu) {
            _removeThirdLevelOverlay();
          }
        });
      },
    );
    Overlay.of(context).insert(_thirdLevelOverlayEntry!);
  }

  void _handleThirdLevelSubmenuTap(String item) {
    _closeMenu();
    debugPrint('Third level menu item tapped: $item');
  }

  void _handleIconTap(String iconLabel) {
    if (iconLabel == 'Ventes') {
      showDialog(
        context: context,
        builder: (context) => const VentesSelectionModal(),
      );
    } else {
      final modal = _modals[iconLabel];
      if (modal != null) {
        showDialog(context: context, builder: (context) => modal);
      } else {
        debugPrint('No modal found for: $iconLabel');
      }
    }
  }

  void _closeMenu() {
    _removeOverlay();
    _removeNestedOverlay();
    _removeThirdLevelOverlay();
    setState(() {
      _selectedMenu = null;
      _isHoveringNestedMenu = false;
      _isHoveringThirdLevelMenu = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _removeNestedOverlay() {
    _nestedOverlayEntry?.remove();
    _nestedOverlayEntry = null;
  }

  void _removeThirdLevelOverlay() {
    _thirdLevelOverlayEntry?.remove();
    _thirdLevelOverlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _removeNestedOverlay();
    _removeThirdLevelOverlay();
    super.dispose();
  }
}
