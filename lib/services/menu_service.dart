import 'package:flutter/material.dart';
import '../constants/menu_data.dart';
import 'auth_service.dart';

class MenuService {
  static OverlayEntry createSubmenuOverlay(
    String menuTitle,
    double leftPosition,
    Function(String) onItemTap, {
    List<String>? customItems,
    Function(String, double)? onItemHover,
    VoidCallback? onMouseExit,
  }) {
    final allItems = customItems ?? MenuData.subMenus[menuTitle] ?? [];
    final items = _filterMenuItemsByRole(allItems);
    
    return OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: 65,
        child: MouseRegion(
          onExit: (_) => onMouseExit?.call(),
          child: GestureDetector(
            onTap: () {},
            child: Material(
              elevation: 4,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((entry) => 
                    _buildSubmenuItem(entry.value, onItemTap, onItemHover, entry.key)
                  ).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSubmenuItem(String title, Function(String) onTap, [Function(String, double)? onHover, int? index]) {
    final hasSubMenu = MenuData.hasSubMenu[title] ?? false;
    const itemHeight = 32.0;
    
    return MouseRegion(
      onEnter: (_) => onHover != null && index != null ? onHover(title, index * itemHeight) : null,
      child: GestureDetector(
        onTap: () => onTap(title),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (hasSubMenu)
                const Icon(
                  Icons.arrow_right,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static OverlayEntry createNestedSubmenuOverlay(
    String parentItem,
    double leftPosition,
    double topPosition,
    Function(String) onItemTap, {
    Function(String, double)? onItemHover,
    VoidCallback? onMouseExit,
    VoidCallback? onMouseEnter,
  }) {
    final items = MenuData.subMenus[parentItem] ?? [];
    
    return OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: topPosition,
        child: MouseRegion(
          onEnter: (_) => onMouseEnter?.call(),
          onExit: (_) => onMouseExit?.call(),
          child: GestureDetector(
            onTap: () {},
            child: Material(
              elevation: 4,
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((entry) => 
                    _buildSubmenuItem(entry.value, onItemTap, onItemHover, entry.key)
                  ).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double getMenuPosition(String menu) {
    return MenuData.menuPositions[menu] ?? 0;
  }

  static List<String> _filterMenuItemsByRole(List<String> items) {
    final authService = AuthService();
    final userRole = authService.currentUserRole;

    // Éléments réservés aux administrateurs
    const adminOnlyItems = [
      'Sauvegarder et Restaurer',
      'Importation des données',
      'Réinitialiser les données',
      'Mise à jour des valeurs de stocks',
    ];

    // Si l'utilisateur n'est pas administrateur, filtrer les éléments réservés
    if (userRole != 'Administrateur') {
      items = items.where((item) => !adminOnlyItems.contains(item)).toList();
    }

    // Si l'utilisateur est vendeur, filtrer les éléments restreints supplémentaires
    if (userRole == 'Vendeur') {
      const restrictedItems = [
        'Ventes (Tous dépôts)',
        'Encaissements',
        'Décaissements',
        'Suivi différence prix',
        'Journal de caisse',
        'Journal des banques',
        'Comptes fournisseurs',
        'Achats',
        'Fournisseurs',
        'Liste des achats',
        'Retours achats',
      ];
      items = items.where((item) => !restrictedItems.contains(item)).toList();
    }

    return items;
  }
}