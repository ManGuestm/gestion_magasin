import 'package:flutter/material.dart';
import '../../constants/menu_data.dart';

class IconBarWidget extends StatelessWidget {
  final Function(String) onIconTap;

  const IconBarWidget({super.key, required this.onIconTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: const Color.fromARGB(255, 230, 229, 229),
      child: Row(
        children: MenuData.iconButtons
            .map((iconData) => _buildIconButton(iconData.icon, iconData.label))
            .toList(),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () => onIconTap(label),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}