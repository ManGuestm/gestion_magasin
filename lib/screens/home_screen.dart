import 'dart:async';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../constants/app_functions.dart';
import '../constants/menu_data.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/modal_loader.dart';
import '../widgets/menu/icon_bar_widget.dart';
import '../widgets/menu/menu_bar_widget.dart';
import '../widgets/modals/ventes_jour_modal.dart';
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

  // Variables pour les statistiques
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _recentBuys = [];
  bool _isLoadingStats = true;

  // Timer pour l'actualisation automatique
  Timer? _refreshTimer;
  Timer? _realTimeTimer;
  bool _isModalOpen = false;
  DateTime _lastUpdate = DateTime.now();

  // Indicateurs temps réel
  bool _hasNewData = false;
  int updateCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _realTimeTimer?.cancel();
    _refreshTimer?.cancel();
    _removeAllOverlays();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    // Actualisation rapide toutes les 30 secondes
    _realTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isModalOpen && mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadDashboardData(silent: true);
      }
    });

    // Actualisation complète toutes les 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isModalOpen && mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadDashboardData();
      }
    });
  }

  void _pauseUpdates() {
    setState(() => _isModalOpen = true);
    _realTimeTimer?.cancel();
    _refreshTimer?.cancel();
  }

  void _resumeUpdates() {
    setState(() => _isModalOpen = false);
    // Redémarrer les timers
    _startRealTimeUpdates();
    // Actualisation immédiate après fermeture du modal
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isModalOpen) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoadingStats = true);
    }

    try {
      final db = DatabaseService().database;
      final userRole = AuthService().currentUser?.role ?? '';
      final userName = AuthService().currentUser?.nom ?? '';
      final now = DateTime.now();

      final stats = <String, dynamic>{};
      final previousStats = Map<String, dynamic>.from(_stats);

      // Statistiques communes avec cache intelligent
      final totalClients = await db.getTotalClients();
      final totalArticles = await db.getTotalArticles();

      stats['clients'] = totalClients;
      stats['articles'] = totalArticles;
      stats['lastUpdate'] = now;

      if (userRole == 'Administrateur') {
        final totalStock = await db.getTotalStockValue();
        final totalAchats = await db.getTotalAchats();
        final totalVentes = await db.getTotalVentes();
        final ventesJour = await db.getVentesToday();
        final totalFournisseurs = await db.getTotalFournisseurs();
        final ventesBrouillard = await db.getVentesBrouillardCount();

        stats['totalStock'] = totalStock;
        stats['totalAchats'] = totalAchats;
        stats['totalVentes'] = totalVentes;
        stats['ventesJour'] = ventesJour;
        stats['fournisseurs'] = totalFournisseurs;
        stats['benefices'] = await db.getBeneficesReels();
        stats['beneficesJour'] = await db.getBeneficesJour();
        stats['ventesBrouillard'] = ventesBrouillard;

        _recentSales = await db.getRecentSales(5);
        _recentBuys = await db.getRecentPurchases(5);
      } else if (userRole == 'Caisse') {
        final totalVentes = await db.getTotalVentes();
        final ventesJour = await db.getVentesToday();
        final encaissements = await db.getTotalEncaissements();
        final transactions = await db.getTotalTransactions();
        final ventesBrouillard = await db.getVentesBrouillardCount();

        stats['totalVentes'] = totalVentes;
        stats['ventesJour'] = ventesJour;
        stats['encaissements'] = encaissements;
        stats['transactions'] = transactions;
        stats['ventesBrouillard'] = ventesBrouillard;

        _recentSales = await db.getRecentSales(5);
        _recentBuys = (await db.getRecentPurchases(5));
      } else if (userRole == 'Vendeur') {
        final mesVentesJour = await db.getVentesTodayByUser(userName);
        final mesVentesMois = await db.getVentesThisMonthByUser(userName);
        final mesClients = await db.getClientsByUser(userName);

        stats['mesVentesJour'] = mesVentesJour;
        stats['mesVentesMois'] = mesVentesMois;
        stats['mesClients'] = mesClients;
        stats['commission'] = mesVentesMois * 0.05; // 5% commission
        stats['objectif'] = 75; // Exemple: 75% de l'objectif
      }

      // Détecter les changements
      _hasNewData = _detectChanges(previousStats, stats);
      if (_hasNewData) {
        updateCounter++;
      }

      setState(() {
        _stats = stats;
        _isLoadingStats = false;
        _lastUpdate = now;
      });

      // Réinitialiser l'indicateur de changement après 3 secondes
      if (_hasNewData) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _hasNewData = false);
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _showModal(String item) async {
    // Vérifier les permissions avant d'ouvrir le modal
    if (!_hasPermissionForItem(item)) {
      _showAccessDeniedDialog(item);
      return;
    }

    try {
      _pauseUpdates(); // Pause les mises à jour

      final modal = await ModalLoader.loadModal(item);
      if (modal != null && mounted) {
        await showDialog(
          context: context,
          builder: (context) => modal,
        );

        // Reprendre les mises à jour après fermeture
        _resumeUpdates();
      }
    } catch (e) {
      _resumeUpdates(); // S'assurer de reprendre même en cas d'erreur
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
              // Contenu principal
              Expanded(child: _buildDashboard()),
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
        _showModal('ventes_magasin');
      } else {
        _pauseUpdates();
        showDialog(
          context: context,
          builder: (context) => const VentesSelectionModal(),
        ).then((_) => _resumeUpdates());
      }
    } else if (item == 'Ventes (Tous dépôts)') {
      _showModal('ventes_tous_depots');
    } else if (item == 'Gestion des utilisateurs') {
      if (!AuthService().hasRole('Administrateur')) {
        _showAccessDeniedDialog(item);
        return;
      }
      _pauseUpdates();
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (context) => const GestionUtilisateursScreen()),
          )
          .then((_) => _resumeUpdates());
    } else if (item == 'Profil') {
      _pauseUpdates();
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (context) => const ProfilScreen()),
          )
          .then((_) => _resumeUpdates());
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
    _showModal(item);
  }

  void _handleKeyPress(KeyEvent event) {
    // Ne traiter les raccourcis que si aucun modal n'est ouvert
    if (event is KeyDownEvent && !_isModalOpen) {
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
        _pauseUpdates();
        showDialog(
          context: context,
          builder: (context) => const VentesSelectionModal(),
        ).then((_) => _resumeUpdates());
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

  Widget _buildDashboard() {
    final userRole = AuthService().currentUser?.role ?? '';

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tableau de Bord - $userRole',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              _buildRealTimeIndicator(),
              const Spacer(),
              _buildLastUpdateInfo(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _loadDashboardData(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser maintenant',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if ((userRole == 'Administrateur' || userRole == 'Caisse') && (_stats['ventesBrouillard'] ?? 0) > 0)
            _buildBrouillardNotification(),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(child: _buildStatsGrid(userRole)),
                ),
                const SizedBox(width: 16),
                if (userRole != 'Vendeur')
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildRecentSales(),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 1,
                          child: _buildRecentPurchases(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String userRole) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1400) {
          crossAxisCount = userRole == 'Administrateur' ? 9 : 8;
        } else if (constraints.maxWidth > 1000) {
          crossAxisCount = userRole == 'Administrateur' ? 7 : 6;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            if (userRole == 'Administrateur') ..._buildAdminStats(),
            if (userRole == 'Caisse') ..._buildCaisseStats(),
            if (userRole == 'Vendeur') ..._buildVendeurStats(),
          ],
        );
      },
    );
  }

  List<Widget> _buildAdminStats() {
    if (_isLoadingStats) {
      return List.generate(9, (index) => _buildLoadingCard());
    }

    return [
      _buildStatCard('Valeur Total Stock', '${_formatNumber(_stats['totalStock'] ?? 0)} Ar', Icons.inventory,
          Colors.blue),
      _buildStatCard('Total Achats', '${_formatNumber(_stats['totalAchats'] ?? 0)} Ar', Icons.shopping_cart,
          Colors.green),
      _buildStatCard('Total Ventes', '${_formatNumber(_stats['totalVentes'] ?? 0)} Ar', Icons.point_of_sale,
          Colors.orange),
      _buildStatCard(
          'Recettes du Jour', '${_formatNumber(_stats['ventesJour'] ?? 0)} Ar', Icons.today, Colors.purple),
      _buildStatCard('Clients Actifs', '${_stats['clients'] ?? 0}', Icons.people, Colors.teal),
      _buildStatCard('Articles', '${_stats['articles'] ?? 0}', Icons.category, Colors.indigo),
      _buildStatCard('Fournisseurs', '${_stats['fournisseurs'] ?? 0}', Icons.business, Colors.brown),
      _buildStatCard(
          'Bénéfices global', '${_formatNumber(_stats['benefices'] ?? 0)} Ar', Icons.trending_up, Colors.red),
      _buildStatCard('Bénéfice du jour', '${_formatNumber(_stats['beneficesJour'] ?? 0)} Ar',
          Icons.today_outlined, Colors.deepOrange),
      if ((_stats['ventesBrouillard'] ?? 0) > 0)
        _buildStatCard(
            'Ventes en attente', '${_stats['ventesBrouillard'] ?? 0}', Icons.pending_actions, Colors.orange),
    ];
  }

  List<Widget> _buildCaisseStats() {
    if (_isLoadingStats) {
      return List.generate(6, (index) => _buildLoadingCard());
    }

    return [
      _buildStatCard('Total Ventes', '${_formatNumber(_stats['totalVentes'] ?? 0)} Ar', Icons.point_of_sale,
          Colors.orange),
      _buildStatCard(
          'Ventes Jour', '${_formatNumber(_stats['ventesJour'] ?? 0)} Ar', Icons.today, Colors.purple),
      _buildStatCard('Encaissements', '${_formatNumber(_stats['encaissements'] ?? 0)} Ar',
          Icons.account_balance_wallet, Colors.green),
      _buildStatCard('Clients', '${_stats['clients'] ?? 0}', Icons.people, Colors.teal),
      _buildStatCard('Articles Stock', '${_stats['articles'] ?? 0}', Icons.inventory, Colors.blue),
      _buildStatCard('Transactions', '${_stats['transactions'] ?? 0}', Icons.receipt, Colors.indigo),
      if ((_stats['ventesBrouillard'] ?? 0) > 0)
        _buildStatCard(
            'Ventes en attente', '${_stats['ventesBrouillard'] ?? 0}', Icons.pending_actions, Colors.orange),
    ];
  }

  List<Widget> _buildVendeurStats() {
    if (_isLoadingStats) {
      return List.generate(6, (index) => _buildLoadingCard());
    }

    return [
      _buildStatCard(
          'Mes Ventes Jour', '${_formatNumber(_stats['mesVentesJour'] ?? 0)} Ar', Icons.today, Colors.purple),
      _buildStatCard('Mes Ventes Mois', '${_formatNumber(_stats['mesVentesMois'] ?? 0)} Ar',
          Icons.calendar_month, Colors.orange),
      _buildStatCard('Mes Clients', '${_stats['mesClients'] ?? 0}', Icons.people, Colors.teal),
      _buildStatCard('Articles Dispo', '${_stats['articles'] ?? 0}', Icons.inventory, Colors.blue),
      _buildStatCard('Objectif Mois', '${_stats['objectif'] ?? 0}%', Icons.track_changes, Colors.green),
      _buildStatCard('Commission', '${_formatNumber(_stats['commission'] ?? 0)} Ar', Icons.monetization_on,
          Colors.amber),
    ];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final hasChanged = _hasDataChanged(title);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () => _handleStatCardTap(title),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: hasChanged ? Border.all(color: Colors.blue, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: hasChanged ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                blurRadius: hasChanged ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, size: 32, color: color),
                        if (_isLoadingStats)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.3)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasChanged ? Colors.blue : color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasChanged)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (title.contains('Ventes') && !_isLoadingStats)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.green.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVentesJourModal() {
    _pauseUpdates();
    showDialog(
      context: context,
      builder: (context) => const VentesJourModal(),
    ).then((_) => _resumeUpdates());
  }

  void _handleStatCardTap(String title) {
    switch (title) {
      case 'Valeur Total Stock':
        _showModal('Etat de stocks');
        break;
      case 'Articles':
      case 'Articles Dispo':
      case 'Articles Stock':
        _showModal('Articles');
        break;
      case 'Total Achats':
        _showModal('Liste des achats');
        break;
      case 'Derniers Achats':
        _showModal('Achats');
        break;
      case 'Total Ventes':
        _showModal('Liste des ventes');
        break;
      case 'Mes Ventes Jour':
      case 'Mes Ventes Mois':
      case 'Ventes Jour':
        final userRole = AuthService().currentUser?.role ?? '';
        if (userRole == 'Vendeur') {
          _showModal('ventes_magasin');
        } else {
          _pauseUpdates();
          showDialog(
            context: context,
            builder: (context) => const VentesSelectionModal(),
          ).then((_) => _resumeUpdates());
        }
        break;
      case 'Recettes du Jour':
        _showVentesJourModal();
        break;
      case 'Clients Actifs':
      case 'Clients':
      case 'Mes Clients':
        _showModal('Clients');
        break;
      case 'Fournisseurs':
        _showModal('Fournisseurs');
        break;
      case 'Encaissements':
        _showModal('Encaissements');
        break;
      case 'Transactions':
        _showModal('Transactions');
        break;
      case 'Ventes en attente':
        _showModal('ventes_tous_depots');
        break;
      case 'Bénéfices global':
      case 'Bénéfice du jour':
      case 'Commission':
        _showModal('Commissions');
        break;
      case 'Objectif Mois':
        // Pas de modal spécifique pour les objectifs
        break;
      default:
        // Pas d'action pour les autres cartes
        break;
    }
  }

  Widget _buildRecentSales() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Dernières Ventes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _isLoadingStats
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: SingleChildScrollView(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentSales.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = _recentSales[index];
                        return ListTile(
                          onTap: () => _showVenteDetails(sale),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text('${index + 1}', style: TextStyle(color: Colors.blue[700])),
                          ),
                          title: Text(
                              'Vente N°${sale['numventes'] ?? index + 1} | Facture N° ${sale['nfact']}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Client: ${sale['client'] ?? 'Client'} - ${_formatDate(sale['date'])} | Vendu par: ${sale['commerc']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Text(
                            '${_formatNumber(sale['total'] ?? 0)} Ar',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchases() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Derniers Achats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _isLoadingStats
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: SingleChildScrollView(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentBuys.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final buy = _recentBuys[index];
                        return ListTile(
                          onTap: () => _showAchatDetails(buy),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text('${index + 1}', style: TextStyle(color: Colors.green[700])),
                          ),
                          title: Text('Achat N°${buy['numachats'] ?? index + 1} | BL N° ${buy['nfact']}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Fournisseur: ${buy['fournisseur'] ?? 'Fournisseur'} - ${_formatDateOnly(buy['date'])}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Text(
                            '${_formatNumber(buy['total'] ?? 0)} Ar',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBrouillardNotification() {
    final count = _stats['ventesBrouillard'] ?? 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 24),
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventes en attente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  '$count vente${count > 1 ? 's' : ''} en brouillard à valider',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showModal('ventes_tous_depots'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = number is String ? double.tryParse(number) ?? 0 : number;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) {
      final now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    }

    DateTime date;
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        date = DateTime.now();
      }
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      date = DateTime.now();
    }

    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(dynamic dateValue) {
    if (dateValue == null) {
      final now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    }

    DateTime date;
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        date = DateTime.now();
      }
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      date = DateTime.now();
    }

    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _showVenteDetails(Map<String, dynamic> sale) async {
    final details = await DatabaseService().database.getVenteDetails(sale['numventes']);
    final venteData = await DatabaseService().database.customSelect(
        'SELECT * FROM ventes WHERE numventes = ?',
        variables: [Variable(sale['numventes'])]).getSingleOrNull();
    final societe =
        await DatabaseService().database.getAllSoc().then((socs) => socs.isNotEmpty ? socs.first : null);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Facture N° ${sale['nfact']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 2),
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          child: const Text(
                            'FACTURE DE VENTE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SOCIÉTÉ:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  Text(
                                    societe?.rsoc ?? 'SOCIÉTÉ',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  if (societe?.activites != null)
                                    Text(societe!.activites!, style: const TextStyle(fontSize: 10)),
                                  if (societe?.adr != null)
                                    Text(societe!.adr!, style: const TextStyle(fontSize: 10)),
                                  if (societe?.rcs != null)
                                    Text('RCS: ${societe!.rcs!}', style: const TextStyle(fontSize: 9)),
                                  if (societe?.nif != null)
                                    Text('NIF: ${societe!.nif!}', style: const TextStyle(fontSize: 9)),
                                  if (societe?.stat != null)
                                    Text('STAT: ${societe!.stat!}', style: const TextStyle(fontSize: 9)),
                                  if (societe?.email != null)
                                    Text('Email: ${societe!.email!}', style: const TextStyle(fontSize: 9)),
                                  if (societe?.port != null)
                                    Text('Tél: ${societe!.port!}', style: const TextStyle(fontSize: 9)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInvoiceInfoRow('N° FACTURE:', '${sale['nfact']}'),
                                  _buildInvoiceInfoRow('N° VENTE:', '${sale['numventes']}'),
                                  _buildInvoiceInfoRow('DATE:', _formatDate(sale['date'])),
                                  _buildInvoiceInfoRow('CLIENT:', '${sale['client']}'),
                                  _buildInvoiceInfoRow('COMMERCIAL:', '${sale['commerc']}'),
                                  _buildInvoiceInfoRow(
                                      'MODE PAIEMENT:',
                                      details.isNotEmpty
                                          ? '${details[0]['modepai'] ?? 'Non spécifié'}'
                                          : 'Non spécifié'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Column(
                          children: [
                            Container(
                              color: Colors.grey[200],
                              child: Table(
                                border: const TableBorder(
                                  horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                                  verticalInside: BorderSide(color: Colors.black, width: 0.5),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.5),
                                  1: FlexColumnWidth(3),
                                  2: FlexColumnWidth(1),
                                  3: FlexColumnWidth(1),
                                  4: FlexColumnWidth(1.5),
                                  5: FlexColumnWidth(1.5),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      _buildInvoiceTableCell('N°', isHeader: true),
                                      _buildInvoiceTableCell('DÉSIGNATION', isHeader: true),
                                      _buildInvoiceTableCell('QTÉ', isHeader: true),
                                      _buildInvoiceTableCell('UNITÉ', isHeader: true),
                                      _buildInvoiceTableCell('PU', isHeader: true),
                                      _buildInvoiceTableCell('MONTANT', isHeader: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                                verticalInside: BorderSide(color: Colors.black, width: 0.5),
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(0.5),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1.5),
                                5: FlexColumnWidth(1.5),
                              },
                              children: [
                                ...details.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final item = entry.value;
                                  final montant = (item['q'] ?? 0) * (item['pu'] ?? 0);
                                  return TableRow(
                                    children: [
                                      _buildInvoiceTableCell(index.toString()),
                                      _buildInvoiceTableCell(item['designation'] ?? ''),
                                      _buildInvoiceTableCell('${item['q'] ?? 0}'),
                                      _buildInvoiceTableCell(item['unites'] ?? ''),
                                      _buildInvoiceTableCell(_formatNumber(item['pu'] ?? 0)),
                                      _buildInvoiceTableCell(_formatNumber(montant), isAmount: true),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.black)),
                                      ),
                                      child: _buildInvoiceTotalRow('TOTAL HT:',
                                          '${_formatNumber(venteData?.read<double>('totalnt') ?? 0)} Ar',
                                          isBold: true),
                                    ),
                                    _buildInvoiceTotalRow('Remise:',
                                        '${_formatNumber(venteData?.read<double>('remise') ?? 0)} %',
                                        isBold: true),
                                    if ((venteData?.read<double>('tva') ?? 0) > 0)
                                      _buildInvoiceTotalRow(
                                          'TVA:', '${_formatNumber(venteData?.read('tva') ?? 0)} Ar',
                                          isBold: true),
                                    _buildInvoiceTotalRow('TOTAL TTC:',
                                        '${_formatNumber(venteData?.read<double>('totalttc') ?? 0)} Ar',
                                        isBold: true),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Arrêté à la somme de ${AppFunctions.numberToWords((venteData?.read<double>('totalttc') ?? 0).toInt())} Ariary',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchatDetails(Map<String, dynamic> achat) async {
    final details = await DatabaseService().database.getAchatDetails(achat['numachats']);
    final achatData = await DatabaseService().database.customSelect(
        'SELECT * FROM achats WHERE numachats = ?',
        variables: [Variable(achat['numachats'])]).getSingleOrNull();

    final societe =
        await DatabaseService().database.getAllSoc().then((socs) => socs.isNotEmpty ? socs.first : null);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Bon de Livraison N° ${achat['nfact']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black, width: 2),
                            bottom: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: const Text(
                          'BON DE LIVRAISON',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SOCIÉTÉ:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                Text(
                                  societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                if (societe?.activites != null)
                                  Text(societe!.activites!, style: const TextStyle(fontSize: 10)),
                                if (societe?.adr != null)
                                  Text(societe!.adr!, style: const TextStyle(fontSize: 10)),
                                if (societe?.rcs != null)
                                  Text('RCS: ${societe!.rcs!}', style: const TextStyle(fontSize: 9)),
                                if (societe?.nif != null)
                                  Text('NIF: ${societe!.nif!}', style: const TextStyle(fontSize: 9)),
                                if (societe?.stat != null)
                                  Text('STAT: ${societe!.stat!}', style: const TextStyle(fontSize: 9)),
                                if (societe?.email != null)
                                  Text('Email: ${societe!.email!}', style: const TextStyle(fontSize: 9)),
                                if (societe?.port != null)
                                  Text('Tél: ${societe!.port!}', style: const TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInvoiceInfoRow('N° BL:', '${achat['nfact']}'),
                                _buildInvoiceInfoRow('N° ACHAT:', '${achat['numachats']}'),
                                _buildInvoiceInfoRow('DATE:', _formatDateOnly(achat['date'])),
                                _buildInvoiceInfoRow('FOURNISSEUR:', '${achat['fournisseur']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              color: Colors.grey[200],
                              child: Table(
                                border: const TableBorder(
                                  horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                                  verticalInside: BorderSide(color: Colors.black, width: 0.5),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.5),
                                  1: FlexColumnWidth(3),
                                  2: FlexColumnWidth(1),
                                  3: FlexColumnWidth(1),
                                  4: FlexColumnWidth(1.5),
                                  5: FlexColumnWidth(1.5),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      _buildInvoiceTableCell('N°', isHeader: true),
                                      _buildInvoiceTableCell('DÉSIGNATION', isHeader: true),
                                      _buildInvoiceTableCell('QTÉ', isHeader: true),
                                      _buildInvoiceTableCell('UNITÉ', isHeader: true),
                                      _buildInvoiceTableCell('PU', isHeader: true),
                                      _buildInvoiceTableCell('MONTANT', isHeader: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                                verticalInside: BorderSide(color: Colors.black, width: 0.5),
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(0.5),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1.5),
                                5: FlexColumnWidth(1.5),
                              },
                              children: [
                                ...details.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key + 1;
                                    final item = entry.value;
                                    final montant = (item['q'] ?? 0) * (item['pu'] ?? 0);
                                    return TableRow(
                                      children: [
                                        _buildInvoiceTableCell(index.toString()),
                                        _buildInvoiceTableCell(item['designation'] ?? ''),
                                        _buildInvoiceTableCell('${item['q'] ?? 0}'),
                                        _buildInvoiceTableCell(item['unites'] ?? ''),
                                        _buildInvoiceTableCell(_formatNumber(item['pu'] ?? 0)),
                                        _buildInvoiceTableCell(_formatNumber(montant), isAmount: true),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if ((achatData?.read<double>('tva') ?? 0) > 0)
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.black)),
                                ),
                                child: _buildInvoiceTotalRow('TOTAL HT:',
                                    '${_formatNumber(achatData?.read<double>('totalnt') ?? 0)} Ar',
                                    isBold: true),
                              ),
                            if ((achatData?.read<double>('tva') ?? 0) > 0)
                              _buildInvoiceTotalRow('TVA:', '${_formatNumber(achatData?.read('tva') ?? 0)} %',
                                  isBold: true),
                            _buildInvoiceTotalRow(
                                'TOTAL TTC:', '${_formatNumber(achatData?.read<double>('totalttc') ?? 0)} Ar',
                                isBold: true),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Arrêté à la somme de ${AppFunctions.numberToWords((achatData?.read<double>('totalttc') ?? 0).toInt())} Ariary',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _detectChanges(Map<String, dynamic> previous, Map<String, dynamic> current) {
    if (previous.isEmpty) return false;

    final keysToCheck = ['totalVentes', 'ventesJour', 'totalStock', 'ventesBrouillard', 'mesVentesJour'];

    for (final key in keysToCheck) {
      if (previous[key] != current[key]) {
        return true;
      }
    }
    return false;
  }

  bool _hasDataChanged(String cardTitle) {
    if (!_hasNewData) return false;

    // Mapper les titres des cartes aux clés de données
    final titleToKey = {
      'Total Ventes': 'totalVentes',
      'Recettes du Jour': 'ventesJour',
      'Ventes Jour': 'ventesJour',
      'Valeur Total Stock': 'totalStock',
      'Ventes en attente': 'ventesBrouillard',
      'Mes Ventes Jour': 'mesVentesJour',
      'Mes Ventes Mois': 'mesVentesMois',
      'Total Achats': 'totalAchats',
      'Bénéfices global': 'benefices',
      'Bénéfice du jour': 'beneficesJour',
    };

    return titleToKey.containsKey(cardTitle);
  }

  Widget _buildRealTimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isModalOpen ? Colors.orange[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isModalOpen ? Colors.orange[300]! : Colors.green[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isModalOpen ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isModalOpen ? 'En pause' : 'Temps réel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _isModalOpen ? Colors.orange[800] : Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate);

    String timeText;
    if (diff.inSeconds < 60) {
      timeText = 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      timeText = 'Il y a ${diff.inMinutes}min';
    } else {
      timeText = 'Il y a ${diff.inHours}h';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasNewData) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          timeText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: _hasNewData ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

Widget _buildInvoiceInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInvoiceTableCell(String text, {bool isHeader = false, bool isAmount = false}) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: isHeader
        ? BoxDecoration(
            color: Colors.grey[200],
          )
        : null,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: isHeader ? TextAlign.center : (isAmount ? TextAlign.right : TextAlign.left),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget _buildInvoiceTotalRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
