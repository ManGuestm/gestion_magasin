import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcut {
  final LogicalKeySet keySet;
  final VoidCallback action;
  final String description;

  KeyboardShortcut({required this.keySet, required this.action, required this.description});
}

class KeyboardService {
  static final KeyboardService _instance = KeyboardService._internal();
  factory KeyboardService() => _instance;
  KeyboardService._internal();

  final Map<LogicalKeySet, KeyboardShortcut> _shortcuts = {};

  /// Enregistre un raccourci clavier
  void registerShortcut(KeyboardShortcut shortcut) {
    _shortcuts[shortcut.keySet] = shortcut;
  }

  /// Supprime un raccourci clavier
  void unregisterShortcut(LogicalKeySet keySet) {
    _shortcuts.remove(keySet);
  }

  /// Obtient tous les raccourcis
  Map<LogicalKeySet, KeyboardShortcut> get shortcuts => Map.unmodifiable(_shortcuts);

  /// Raccourcis globaux par défaut
  static void registerDefaultShortcuts() {
    final service = KeyboardService();

    // Ctrl+S - Sauvegarder
    service.registerShortcut(
      KeyboardShortcut(
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
        action: () => debugPrint('Save shortcut'),
        description: 'Sauvegarder',
      ),
    );

    // Ctrl+N - Nouveau
    service.registerShortcut(
      KeyboardShortcut(
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
        action: () => debugPrint('New shortcut'),
        description: 'Nouveau',
      ),
    );

    // Ctrl+F - Rechercher
    service.registerShortcut(
      KeyboardShortcut(
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
        action: () => debugPrint('Find shortcut'),
        description: 'Rechercher',
      ),
    );

    // F5 - Actualiser
    service.registerShortcut(
      KeyboardShortcut(
        keySet: LogicalKeySet(LogicalKeyboardKey.f5),
        action: () => debugPrint('Refresh shortcut'),
        description: 'Actualiser',
      ),
    );

    // Escape - Fermer/Annuler
    service.registerShortcut(
      KeyboardShortcut(
        keySet: LogicalKeySet(LogicalKeyboardKey.escape),
        action: () => debugPrint('Cancel shortcut'),
        description: 'Annuler/Fermer',
      ),
    );
  }
}

/// Widget pour gérer les raccourcis clavier
class KeyboardShortcutHandler extends StatelessWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback>? shortcuts;

  const KeyboardShortcutHandler({super.key, required this.child, this.shortcuts});

  @override
  Widget build(BuildContext context) {
    final allShortcuts = <LogicalKeySet, VoidCallback>{};

    // Ajouter les raccourcis globaux
    for (final entry in KeyboardService().shortcuts.entries) {
      allShortcuts[entry.key] = entry.value.action;
    }

    // Ajouter les raccourcis locaux
    if (shortcuts != null) {
      allShortcuts.addAll(shortcuts!);
    }

    return Shortcuts(
      shortcuts: allShortcuts.map((key, value) => MapEntry(key, VoidCallbackIntent(value))),
      child: Actions(
        actions: {VoidCallbackIntent: VoidCallbackAction()},
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

/// Intent pour les callbacks
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}

/// Action pour les callbacks
class VoidCallbackAction extends Action<VoidCallbackIntent> {
  @override
  Object? invoke(VoidCallbackIntent intent) {
    intent.callback();
    return null;
  }
}

/// Widget pour afficher l'aide des raccourcis
class ShortcutHelpDialog extends StatelessWidget {
  const ShortcutHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = KeyboardService().shortcuts.values.toList();

    return AlertDialog(
      title: const Text('Raccourcis clavier'),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return ListTile(
              title: Text(shortcut.description),
              trailing: Text(_formatKeySet(shortcut.keySet), style: const TextStyle(fontFamily: 'monospace')),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
    );
  }

  String _formatKeySet(LogicalKeySet keySet) {
    final keys = keySet.keys.toList();
    final keyNames = keys.map((key) {
      if (key == LogicalKeyboardKey.control) return 'Ctrl';
      if (key == LogicalKeyboardKey.alt) return 'Alt';
      if (key == LogicalKeyboardKey.shift) return 'Shift';
      if (key == LogicalKeyboardKey.meta) return 'Win';
      return key.keyLabel.toUpperCase();
    }).toList();

    return keyNames.join(' + ');
  }

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const ShortcutHelpDialog());
  }
}
