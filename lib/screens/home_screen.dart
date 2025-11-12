import 'package:flutter/material.dart';

import '../services/menu_service.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/achats_modal.dart';
import '../widgets/modals/articles_modal.dart';
import '../widgets/modals/banques_modal.dart';
import '../widgets/modals/clients_modal.dart';
import '../widgets/modals/company_info_modal.dart';
import '../widgets/modals/depots_modal.dart';
import '../widgets/modals/fournisseurs_modal.dart';
import '../widgets/modals/moyen_paiement_modal.dart';
import '../widgets/modals/plan_comptes_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMenu;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _nestedOverlayEntry;

  static const Map<String, Widget> _modals = {
    'Informations sur la société': CompanyInfoModal(),
    'Dépôts': DepotsModal(),
    'Articles': ArticlesModal(),
    'Clients': ClientsModal(),
    'Fournisseurs': FournisseursModal(),
    'Banques': BanquesModal(),
    'Plan de comptes': PlanComptesModal(),
    'Achats': AchatsModal(),
    'Moyen de paiement': MoyenPaiementModal(),
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
      onMouseExit: _removeNestedOverlay,
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleSubmenuTap(String item) {
    _closeMenu();
    final modal = _modals[item];
    if (modal != null) {
      showDialog(context: context, builder: (context) => modal);
    } else {
      debugPrint('Menu item tapped: $item');
    }
  }

  void _handleSubmenuHover(String item, double itemPosition) {
    const itemsWithSubmenus = {
      'Etats Articles',
      'Etats Fournisseurs',
      'Etats Clients',
      'Etats Commerciaux',
      'Etats Immobilisations',
      'Etats Autres Comptes',
      'Statistiques de ventes',
      'Statistiques d\'achats',
      'Marges',
      'Retour de Marchandises',
    };
    
    if (itemsWithSubmenus.contains(item)) {
      _showNestedSubmenu(item, itemPosition);
    } else {
      _removeNestedOverlay();
    }
  }

  void _showNestedSubmenu(String parentItem, double itemPosition) {
    _removeNestedOverlay();

    // Determine which parent menu this item belongs to
    String parentMenu = _selectedMenu ?? '';
    double baseLeftPosition = MenuService.getMenuPosition(parentMenu) + 250;

    _nestedOverlayEntry = MenuService.createNestedSubmenuOverlay(
      parentItem,
      baseLeftPosition,
      65 + itemPosition, // 65 is the base top position + item position
      _handleNestedSubmenuTap,
      onMouseExit: _removeNestedOverlay,
    );
    Overlay.of(context).insert(_nestedOverlayEntry!);
  }

  void _handleNestedSubmenuTap(String item) {
    _closeMenu();
    debugPrint('Nested menu item tapped: $item');
  }

  void _handleIconTap(String iconLabel) {
    debugPrint('Icon tapped: $iconLabel');
  }

  void _closeMenu() {
    _removeOverlay();
    _removeNestedOverlay();
    setState(() => _selectedMenu = null);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _removeNestedOverlay() {
    _nestedOverlayEntry?.remove();
    _nestedOverlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _removeNestedOverlay();
    super.dispose();
  }
}
