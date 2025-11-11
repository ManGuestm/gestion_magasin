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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: GestureDetector(
        onTap: () {
          _removeOverlay();
          setState(() {
            _selectedMenu = null;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            MenuBarWidget(onMenuTap: _showSubmenu),
            IconBarWidget(onIconTap: _handleIconTap),
            Expanded(
              child: Container(
                color: Colors.grey[200],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 30,
      color: Colors.grey[300],
      child: const Row(
        children: [
          Padding(
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
        ],
      ),
    );
  }

  void _showSubmenu(String menu) {
    if (_selectedMenu == menu) {
      _removeOverlay();
      setState(() {
        _selectedMenu = null;
      });
      return;
    }

    _removeOverlay();
    setState(() {
      _selectedMenu = menu;
    });

    double leftPosition = MenuService.getMenuPosition(menu);
    _overlayEntry = MenuService.createSubmenuOverlay(
      menu,
      leftPosition,
      _handleSubmenuTap,
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleSubmenuTap(String item) {
    _removeOverlay();
    setState(() {
      _selectedMenu = null;
    });

    if (item == 'Informations sur la société') {
      _showCompanyInfoModal();
    } else if (item == 'Dépôts') {
      _showDepotsModal();
    } else if (item == 'Articles') {
      _showArticlesModal();
    } else if (item == 'Clients') {
      _showClientsModal();
    } else if (item == 'Fournisseurs') {
      _showFournisseursModal();
    } else if (item == 'Banques') {
      _showBanquesModal();
    } else if (item == 'Plan de comptes') {
      _showPlanComptesModal();
    } else if (item == 'Achats') {
      _showAchatsModal();
    } else if (item == 'Moyen de paiement') {
      _showMoyenPaiementModal();
    }
    // Ajouter d'autres actions ici
  }

  void _handleIconTap(String iconLabel) {
    // Gérer les clics sur les icônes
    debugPrint('Icon tapped: $iconLabel');
  }

  void _showCompanyInfoModal() {
    showDialog(
      context: context,
      builder: (context) => const CompanyInfoModal(),
    );
  }

  void _showDepotsModal() {
    showDialog(
      context: context,
      builder: (context) => const DepotsModal(),
    );
  }

  void _showArticlesModal() {
    showDialog(
      context: context,
      builder: (context) => const ArticlesModal(),
    );
  }

  void _showClientsModal() {
    showDialog(
      context: context,
      builder: (context) => const ClientsModal(),
    );
  }

  void _showFournisseursModal() {
    showDialog(
      context: context,
      builder: (context) => const FournisseursModal(),
    );
  }

  void _showBanquesModal() {
    showDialog(
      context: context,
      builder: (context) => const BanquesModal(),
    );
  }

  void _showPlanComptesModal() {
    showDialog(
      context: context,
      builder: (context) => const PlanComptesModal(),
    );
  }

  void _showAchatsModal() {
    showDialog(
      context: context,
      builder: (context) => const AchatsModal(),
    );
  }

  void _showMoyenPaiementModal() {
    showDialog(
      context: context,
      builder: (context) => const MoyenPaiementModal(),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}
