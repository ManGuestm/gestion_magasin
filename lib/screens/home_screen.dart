import 'dart:async';

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
        _recentBuys = (await db.getRecentPurchases(5)).where((buy) => buy['contre'] == 1).toList();
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
        _recentBuys = (await db.getRecentPurchases(5)).where((buy) => buy['contre'] != '1').toList();
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
      child: SingleChildScrollView(
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
            if ((userRole == 'Administrateur' || userRole == 'Caisse') &&
                (_stats['ventesBrouillard'] ?? 0) > 0)
              _buildBrouillardNotification(),
            const SizedBox(height: 20),
            _buildStatsGrid(userRole),
            const SizedBox(height: 20),
            if (userRole != 'Vendeur')
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 100.0,
                children: [
                  Expanded(child: _buildRecentSales()),
                  Expanded(child: _buildRecentPurchases()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(String userRole) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1400) {
          crossAxisCount = userRole == 'Administrateur' ? 7 : 6;
        } else if (constraints.maxWidth > 1000) {
          crossAxisCount = userRole == 'Administrateur' ? 5 : 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
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
        onTap: title == 'Recettes du Jour' ? _showVentesJourModal : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
              : ListView.separated(
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
                      title: Text('Vente N°${sale['numventes'] ?? index + 1} | Facture N° ${sale['nfact']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Client: ${sale['client'] ?? 'Client'} - ${_formatDate(sale['date'])} | Vendu par: ${sale['commerc']}',
                          style: const TextStyle(color: Colors.grey)),
                      trailing: Text(
                        '${_formatNumber(sale['total'] ?? 0)} Ar',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    );
                  },
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
              : ListView.separated(
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
                      title: Text('Achat N°${buy['numachats'] ?? index + 1} | Facture N° ${buy['nfact']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Fournisseur: ${buy['fournisseur'] ?? 'Fournisseur'} - ${_formatDateOnly(buy['date'])}',
                          style: const TextStyle(color: Colors.grey)),
                      trailing: Text(
                        '${_formatNumber(buy['total'] ?? 0)} Ar',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    );
                  },
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

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails Vente N°${sale['numventes']}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('N° Vente', '${sale['numventes']}'),
              _buildDetailRow('N° Facture', '${sale['nfact']}'),
              _buildDetailRow('Client', '${sale['client']}'),
              _buildDetailRow('Commercial', '${sale['commerc']}'),
              _buildDetailRow('Date', _formatDate(sale['date'])),
              _buildDetailRow('Mode Paiement', '${sale['modepai'] ?? 'Non spécifié'}'),
              const Divider(),
              const Text('Articles vendus:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                        ),
                      ),
                      child: Text(
                        "Désignation",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                        ),
                      ),
                      child: Text(
                        "Quantités",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                          right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                        ),
                      ),
                      child: Text(
                        "P.U",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final item = details[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: index.isEven ? Colors.white : Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                  ),
                                ),
                                child: Text(item['designation'] ?? '', style: const TextStyle(fontSize: 12))),
                          ),
                          Expanded(
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                  ),
                                ),
                                child: Text('${item['q']} ${item['unites']}',
                                    style: const TextStyle(fontSize: 12))),
                          ),
                          Expanded(
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    top: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    left: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                    right: BorderSide(color: Colors.grey[400]!, width: 0.25),
                                  ),
                                ),
                                child: Text('${_formatNumber(item['pu'])} Ar',
                                    style: const TextStyle(fontSize: 12))),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              _buildDetailRow(
                'Total TTC',
                '${_formatNumber(sale['total'])} Ar',
                isAmount: true,
                isTotalTTC: true,
              ),
              SizedBox(height: 24),
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                child: Text(
                  "Arrêté à la somme de ${AppFunctions.numberToWords(sale['total'].toInt())} Ariary",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAchatDetails(Map<String, dynamic> achat) async {
    final details = await DatabaseService().database.getAchatDetails(achat['numachats']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails Achat N°${achat['numachats']}'),
        content: SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('N° Achat', '${achat['numachats']}'),
              _buildDetailRow('N° Facture', '${achat['nfact']}'),
              _buildDetailRow('Fournisseur', '${achat['fournisseur']}'),
              _buildDetailRow('Date', _formatDateOnly(achat['date'])),
              const Divider(),
              const Text('Articles achetés:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final item = details[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item['designation'] ?? '', style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child:
                                Text('${item['q']} ${item['unites']}', style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child:
                                Text('${_formatNumber(item['pu'])} Ar', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              _buildDetailRow('Total TTC', '${_formatNumber(achat['total'])} Ar',
                  isAmount: true, isTotalTTC: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false, bool isTotalTTC = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: isTotalTTC ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isTotalTTC) Spacer(),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: isAmount ? EdgeInsets.symmetric(horizontal: 16, vertical: 4) : null,
              alignment: isAmount ? Alignment.center : null,
              decoration: isAmount
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                        top: BorderSide(color: Colors.grey[400]!, width: 0.5),
                        left: BorderSide(color: Colors.grey[400]!, width: 0.5),
                        right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                      ),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                  color: isAmount ? Colors.green : null,
                ),
              ),
            ),
          ),
        ],
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
