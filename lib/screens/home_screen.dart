import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../constants/menu_data.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/modal_loader.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/ventes_selection_modal.dart';
import 'gestion_utilisateurs_screen.dart';
import 'login_screen.dart';
import 'profil_screen.dart';

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
    // Vérifier les permissions avant d'ouvrir le modal
    if (!_hasPermissionForItem(item)) {
      _showAccessDeniedDialog(item);
      return;
    }

    try {
      final modal = await ModalLoader.loadModal(item);
      if (modal != null && mounted) {
        showDialog(context: context, builder: (context) => modal);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du modal $item: $e');
    }
  }

  static const _itemPermissions = AppConstants.defaultPermissions;

  bool _hasPermissionForItem(String item) {
    final requiredPermission = _itemPermissions[item];
    return requiredPermission == null || AuthService().canAccess(requiredPermission);
  }

  void _showAccessDeniedDialog(String item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accès refusé'),
        content: Text('Vous n\'avez pas les permissions nécessaires pour accéder à "$item".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildHeader() {
    final currentUser = AuthService().currentUser;

    return Container(
      height: 30,
      color: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.business, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              'GESTION COMMERCIALE - ${currentUser?.nom ?? 'Utilisateur'} (${currentUser?.role ?? 'Invité'})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            // Bouton de déconnexion
            InkWell(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Déconnexion',
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSubmenu(String menu) {
    if (_selectedMenu == menu) {
      _closeMenu();
      return;
    }

    _removeAllOverlays();
    setState(() => _selectedMenu = menu);

    _overlayEntry = MenuService.createSubmenuOverlay(
      menu,
      MenuService.getMenuPosition(menu),
      _handleSubmenuTap,
      onItemHover: _handleSubmenuHover,
      onMouseExit: () {
        // Delay removal to allow moving to nested menu
        Future.delayed(AppConstants.shortAnimation, () {
          if (!_isHoveringNestedMenu) {
            _nestedOverlayEntry?.remove();
            _nestedOverlayEntry = null;
          }
        });
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleSubmenuTap(String item) {
    _closeMenu();
    if (item == 'Ventes') {
      final userRole = AuthService().currentUser?.role ?? '';
      if (userRole == 'Vendeur') {
        // Vendeur va directement au modal vente magasin
        _showModal('ventes_magasin');
      } else {
        // Admin/Caisse passent par le modal de sélection
        showDialog(
          context: context,
          builder: (context) => const VentesSelectionModal(),
        );
      }
    } else if (item == 'Ventes (Tous dépôts)') {
      _showModal('ventes_tous_depots');
    } else if (item == 'Gestion des utilisateurs') {
      // Vérifier les permissions admin
      if (!AuthService().hasRole('Administrateur')) {
        _showAccessDeniedDialog(item);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GestionUtilisateursScreen()),
      );
    } else if (item == 'Profil') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfilScreen()),
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
        _nestedOverlayEntry?.remove();
        _nestedOverlayEntry = null;
        _thirdLevelOverlayEntry?.remove();
        _thirdLevelOverlayEntry = null;
      }
    }
  }

  void _showNestedSubmenu(String parentItem, double itemPosition) {
    _nestedOverlayEntry?.remove();
    _nestedOverlayEntry = null;

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
        Future.delayed(AppConstants.shortAnimation, () {
          if (!_isHoveringNestedMenu && !_isHoveringThirdLevelMenu) {
            _nestedOverlayEntry?.remove();
            _nestedOverlayEntry = null;
            _thirdLevelOverlayEntry?.remove();
            _thirdLevelOverlayEntry = null;
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
        _thirdLevelOverlayEntry?.remove();
        _thirdLevelOverlayEntry = null;
      }
    }
  }

  void _showThirdLevelSubmenu(String parentItem, double itemPosition, [double? secondLevelTopPosition]) {
    secondLevelTopPosition ??= 65;
    _thirdLevelOverlayEntry?.remove();
    _thirdLevelOverlayEntry = null;

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
        Future.delayed(AppConstants.shortAnimation, () {
          if (!_isHoveringThirdLevelMenu) {
            _thirdLevelOverlayEntry?.remove();
            _thirdLevelOverlayEntry = null;
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

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final shortcuts = {
        LogicalKeyboardKey.keyP: 'Articles',
        LogicalKeyboardKey.keyA: 'Achats',
        LogicalKeyboardKey.keyV: 'Ventes',
        LogicalKeyboardKey.keyD: 'Dépôts',
        LogicalKeyboardKey.keyC: 'Clients',
        LogicalKeyboardKey.keyF: 'Fournisseurs',
        LogicalKeyboardKey.keyT: 'Transferts',
        LogicalKeyboardKey.keyE: 'Encaissements',
        LogicalKeyboardKey.keyR: 'Relance Clients',
      };

      if (shortcuts.containsKey(event.logicalKey)) {
        _handleIconTap(shortcuts[event.logicalKey]!);
      }
    }
  }

  void _handleIconTap(String iconLabel) {
    if (iconLabel == 'Ventes') {
      final userRole = AuthService().currentUser?.role ?? '';
      if (userRole == 'Vendeur') {
        _showModal('ventes_magasin');
      } else {
        showDialog(
          context: context,
          builder: (context) => const VentesSelectionModal(),
        );
      }
    } else {
      _showModal(iconLabel);
    }
  }

  void _closeMenu() {
    _removeAllOverlays();
    setState(() {
      _selectedMenu = null;
      _isHoveringNestedMenu = false;
      _isHoveringThirdLevelMenu = false;
    });
  }

  void _removeAllOverlays() {
    _overlayEntry?.remove();
    _nestedOverlayEntry?.remove();
    _thirdLevelOverlayEntry?.remove();
    _overlayEntry = null;
    _nestedOverlayEntry = null;
    _thirdLevelOverlayEntry = null;
  }

  @override
  void dispose() {
    _removeAllOverlays();
    super.dispose();
  }
}
