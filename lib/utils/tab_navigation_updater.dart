import 'dart:io';

import 'package:flutter/material.dart';

/// Utilitaire pour ajouter automatiquement la navigation Tab/Shift+Tab aux modales
class TabNavigationUpdater {
  static const String tabNavigationImport = "import '../common/tab_navigation_widget.dart';";
  static const String tabNavigationMixin = "with TabNavigationMixin";

  /// Met à jour un fichier modal pour ajouter la navigation Tab/Shift+Tab
  static Future<void> updateModalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Fichier non trouvé: $filePath');
        return;
      }

      String content = await file.readAsString();

      // Vérifier si déjà mis à jour
      if (content.contains('TabNavigationMixin')) {
        debugPrint('Fichier déjà mis à jour: $filePath');
        return;
      }

      // Ajouter l'import
      if (!content.contains(tabNavigationImport)) {
        final importIndex = content.lastIndexOf("import '");
        if (importIndex != -1) {
          final nextLineIndex = content.indexOf('\n', importIndex);
          content =
              '${content.substring(0, nextLineIndex + 1)}$tabNavigationImport\n${content.substring(nextLineIndex + 1)}';
        }
      }

      // Ajouter le mixin à la classe State
      final stateClassPattern = RegExp(r'class\s+_\w+State\s+extends\s+State<\w+>\s*{');
      final match = stateClassPattern.firstMatch(content);
      if (match != null) {
        final classDeclaration = match.group(0)!;
        final newClassDeclaration = classDeclaration
            .replaceFirst('extends State<', 'extends State<')
            .replaceFirst('{', ' $tabNavigationMixin {');
        content = content.replaceFirst(classDeclaration, newClassDeclaration);
      }

      // Ajouter la gestion des événements clavier dans build()
      final buildMethodPattern = RegExp(r'@override\s+Widget\s+build\(BuildContext\s+context\)\s*{');
      final buildMatch = buildMethodPattern.firstMatch(content);
      if (buildMatch != null) {
        // Chercher le premier return dans la méthode build
        final buildStart = buildMatch.end;
        final returnIndex = content.indexOf('return ', buildStart);
        if (returnIndex != -1) {
          final returnStatement = content.substring(returnIndex);
          final firstWidget = _extractFirstWidget(returnStatement);
          if (firstWidget != null && !firstWidget.contains('Focus(')) {
            final wrappedWidget = '''Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: $firstWidget''';
            content = content.replaceFirst(firstWidget, wrappedWidget);

            // Ajouter la fermeture du Focus widget
            final lastBrace = content.lastIndexOf('}');
            if (lastBrace != -1) {
              content = '${content.substring(0, lastBrace)}\n    );\n${content.substring(lastBrace + 1)}';
            }
          }
        }
      }

      // Remplacer les FocusNode() par createFocusNode()
      content = content.replaceAllMapped(RegExp(r'final\s+FocusNode\s+(\w+)\s*=\s*FocusNode\(\);'),
          (match) => 'late final FocusNode ${match.group(1)};');

      // Ajouter l'initialisation des focus nodes dans initState
      final initStatePattern = RegExp(r'@override\s+void\s+initState\(\)\s*{\s*super\.initState\(\);');
      final initMatch = initStatePattern.firstMatch(content);
      if (initMatch != null) {
        final focusNodePattern = RegExp(r'late\s+final\s+FocusNode\s+(\w+);');
        final focusNodes = focusNodePattern.allMatches(content);

        if (focusNodes.isNotEmpty) {
          String initCode = '\n    // Initialize focus nodes with tab navigation\n';
          for (final node in focusNodes) {
            final nodeName = node.group(1)!;
            initCode += '    $nodeName = createFocusNode();\n';
          }

          content = content.replaceFirst(initMatch.group(0)!, initMatch.group(0)! + initCode);
        }
      }

      // Ajouter onTap: () => updateFocusIndex(focusNode) aux TextFormField
      content = content.replaceAllMapped(RegExp(r'TextFormField\(\s*([^}]+)\s*focusNode:\s*(\w+),([^}]+)\)'),
          (match) {
        final beforeFocus = match.group(1) ?? '';
        final focusNodeName = match.group(2) ?? '';
        final afterFocus = match.group(3) ?? '';

        if (!afterFocus.contains('onTap:')) {
          return 'TextFormField(\n$beforeFocus'
              'focusNode: $focusNodeName,\n'
              '${afterFocus.trim()}\n'
              'onTap: () => updateFocusIndex($focusNodeName),\n'
              ')';
        }
        return match.group(0)!;
      });

      await file.writeAsString(content);
      debugPrint('Fichier mis à jour avec succès: $filePath');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de $filePath: $e');
    }
  }

  /// Extrait le premier widget du return statement
  static String? _extractFirstWidget(String returnStatement) {
    final lines = returnStatement.split('\n');
    if (lines.isEmpty) return null;

    final firstLine = lines[0].trim();
    if (firstLine.startsWith('return ')) {
      return firstLine.substring(7).trim();
    }

    return null;
  }

  /// Met à jour tous les modales dans le dossier
  static Future<void> updateAllModals() async {
    final modalsDir = Directory('c:\\Users\\rakpa\\Music\\gestion_magasin\\lib\\widgets\\modals');

    if (!await modalsDir.exists()) {
      debugPrint('Dossier modals non trouvé');
      return;
    }

    final files = await modalsDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .cast<File>()
        .toList();

    for (final file in files) {
      await updateModalFile(file.path);
    }

    debugPrint('Mise à jour terminée pour ${files.length} fichiers');
  }
}
