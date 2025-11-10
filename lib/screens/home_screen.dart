import 'package:flutter/material.dart';

import '../services/menu_service.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/company_info_modal.dart';

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
