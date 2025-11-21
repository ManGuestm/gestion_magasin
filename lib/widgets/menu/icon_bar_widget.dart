import 'package:flutter/material.dart';

import '../../constants/menu_data.dart';

class IconBarWidget extends StatelessWidget {
  final Function(String) onIconTap;

  const IconBarWidget({super.key, required this.onIconTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 4.0,
        runSpacing: 4.0,
        children: MenuData.iconButtons
            .map((iconData) => _buildIconButton(context, iconData.icon, iconData.label))
            .toList(),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onIconTap(label),
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 60,
            minWidth: 88,
            maxHeight: 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
