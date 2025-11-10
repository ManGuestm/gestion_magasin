import 'package:flutter/material.dart';
import '../constants/menu_data.dart';

class MenuService {
  static OverlayEntry createSubmenuOverlay(
    String menuTitle,
    double leftPosition,
    Function(String) onItemTap,
  ) {
    final items = MenuData.subMenus[menuTitle] ?? [];
    
    return OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: 65,
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
                children: items.map((item) => _buildSubmenuItem(item, onItemTap)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSubmenuItem(String title, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  static double getMenuPosition(String menu) {
    return MenuData.menuPositions[menu] ?? 0;
  }
}