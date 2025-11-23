import 'dart:io';

import 'package:flutter/foundation.dart';

void main() async {
  debugPrint('Application de la navigation Tab/Shift+Tab aux modales...');

  final modalsDir = Directory('lib/widgets/modals');

  if (!await modalsDir.exists()) {
    debugPrint('Dossier modals non trouvé');
    return;
  }

  final files = await modalsDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  int updatedCount = 0;

  for (final file in files) {
    final fileName = file.path.split('\\').last;

    // Skip files already updated
    if (fileName == 'add_client_modal.dart' ||
        fileName == 'add_article_modal.dart' ||
        fileName == 'add_fournisseur_modal.dart' ||
        fileName == 'ventes_modal.dart') {
      debugPrint('Ignoré (déjà mis à jour): $fileName');
      continue;
    }

    try {
      String content = await file.readAsString();

      // Check if already updated
      if (content.contains('TabNavigationMixin')) {
        debugPrint('Déjà mis à jour: $fileName');
        continue;
      }

      // Add import
      if (!content.contains("import '../common/tab_navigation_widget.dart';")) {
        final lastImportIndex = content.lastIndexOf(RegExp(r"import '[^']*';"));
        if (lastImportIndex != -1) {
          final nextLineIndex = content.indexOf('\n', lastImportIndex);
          content =
              '${content.substring(0, nextLineIndex + 1)}import \'../common/tab_navigation_widget.dart\';\n${content.substring(nextLineIndex + 1)}';
        }
      }

      // Add mixin to State class
      final stateClassRegex = RegExp(r'class\s+_\w+State\s+extends\s+State<[^>]+>\s*{');
      final match = stateClassRegex.firstMatch(content);
      if (match != null) {
        final classDeclaration = match.group(0)!;
        final newClassDeclaration = classDeclaration.replaceFirst('> {', '> with TabNavigationMixin {');
        content = content.replaceFirst(classDeclaration, newClassDeclaration);
      }

      // Replace FocusNode() with late final FocusNode
      content = content.replaceAllMapped(RegExp(r'final\s+FocusNode\s+(\w+)\s*=\s*FocusNode\(\);'),
          (match) => 'late final FocusNode ${match.group(1)};');

      // Add focus node initialization in initState
      final initStateRegex = RegExp(r'(@override\s+)?void\s+initState\(\)\s*{\s*super\.initState\(\);');
      final initMatch = initStateRegex.firstMatch(content);
      if (initMatch != null) {
        final focusNodeRegex = RegExp(r'late\s+final\s+FocusNode\s+(\w+);');
        final focusNodes = focusNodeRegex.allMatches(content);

        if (focusNodes.isNotEmpty) {
          String initCode = '\n    // Initialize focus nodes with tab navigation\n';
          for (final node in focusNodes) {
            final nodeName = node.group(1)!;
            initCode += '    $nodeName = createFocusNode();\n';
          }

          content = content.replaceFirst(initMatch.group(0)!, initMatch.group(0)! + initCode);
        }
      }

      // Add Focus wrapper with tab navigation
      final buildMethodRegex = RegExp(
          r'@override\s+Widget\s+build\(BuildContext\s+context\)\s*{[^}]*return\s+([^;]+);',
          multiLine: true,
          dotAll: true);
      final buildMatch = buildMethodRegex.firstMatch(content);
      if (buildMatch != null) {
        final returnWidget = buildMatch.group(1)!.trim();
        if (!returnWidget.contains('Focus(') && !returnWidget.contains('KeyboardListener(')) {
          final wrappedWidget = '''Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: $returnWidget''';
          content = content.replaceFirst(returnWidget, wrappedWidget);

          // Add closing parenthesis
          final lastBrace = content.lastIndexOf('  }');
          if (lastBrace != -1) {
            content = '${content.substring(0, lastBrace)}    );\n  ${content.substring(lastBrace + 2)}';
          }
        }
      }

      // Add onTap to TextFormField
      content = content.replaceAllMapped(
          RegExp(r'TextFormField\(\s*([^}]*?)focusNode:\s*(\w+),([^}]*?)\)', multiLine: true, dotAll: true),
          (match) {
        final beforeFocus = match.group(1) ?? '';
        final focusNodeName = match.group(2) ?? '';
        final afterFocus = match.group(3) ?? '';

        if (!afterFocus.contains('onTap:')) {
          return 'TextFormField(\n${beforeFocus}focusNode: $focusNodeName,\n${afterFocus.trim()}\nonTap: () => updateFocusIndex($focusNodeName),\n)';
        }
        return match.group(0)!;
      });

      await file.writeAsString(content);
      updatedCount++;
      debugPrint('Mis à jour: $fileName');
    } catch (e) {
      debugPrint('Erreur avec $fileName: $e');
    }
  }

  debugPrint('\nTerminé! $updatedCount fichiers mis à jour sur ${files.length} fichiers trouvés.');
}
