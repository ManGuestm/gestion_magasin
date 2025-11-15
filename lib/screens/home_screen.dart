import 'package:flutter/material.dart';

import '../constants/menu_data.dart';
import '../services/menu_service.dart';
import '../services/modal_loader.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/ventes_selection_modal.dart';

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

  Future<void> _showModal(String item) async {
    try {
      final modal = await ModalLoader.loadModal(item);
      if (modal != null && mounted) {
        showDialog(context: context, builder: (context) => modal);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du modal $item: $e');
    }
  }

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
            Spacer(),
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
      _showModal(item);
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
    _showModal(item);
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
      _showModal(iconLabel);
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
