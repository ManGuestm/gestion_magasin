import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = DatabaseService().database;
      final userRole = AuthService().currentUser?.role ?? '';
      final userName = AuthService().currentUser?.nom ?? '';

      final stats = <String, dynamic>{};

      // Statistiques communes
      final totalClients = await db.getTotalClients();
      final totalArticles = await db.getTotalArticles();

      stats['clients'] = totalClients;
      stats['articles'] = totalArticles;

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
        _recentBuys = await db.getRecentPurchases(5);
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

      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
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
    _showModal(item);
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
                const Spacer(),
                IconButton(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser les données',
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
    return InkWell(
      onTap: title == 'Recettes du Jour' ? _showVentesJourModal : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVentesJourModal() {
    showDialog(
      context: context,
      builder: (context) => const VentesJourModal(),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count vente${count > 1 ? 's' : ''} en brouillard en attente de validation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.orange[800]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _showModal('ventes_tous_depots'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir les ventes'),
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
          width: 500,
          height: 400,
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
              _buildDetailRow('Total TTC', '${_formatNumber(sale['total'])} Ar', isAmount: true),
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
          height: 400,
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
              _buildDetailRow('Total TTC', '${_formatNumber(achat['total'])} Ar', isAmount: true),
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

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                color: isAmount ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _removeAllOverlays();
    super.dispose();
  }
}
