import 'package:flutter/material.dart';

class AppConstants {
  // Couleurs
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  // Tailles
  static const double defaultPadding = 8.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultIconSize = 16.0;

  // Tailles de modal
  static const double defaultModalWidth = 900.0;
  static const double defaultModalHeight = 600.0;

  // Tailles de table
  static const double tableHeaderHeight = 25.0;
  static const double tableRowHeight = 18.0;

  // Polices
  static const double smallFontSize = 11.0;
  static const double defaultFontSize = 12.0;
  static const double largeFontSize = 14.0;

  // Durées d'animation
  static const Duration shortAnimation = Duration(milliseconds: 100);
  static const Duration mediumAnimation = Duration(milliseconds: 300);

  // Pagination
  static const int defaultPageSize = 100;
  static const int maxCacheSize = 10;

  // Messages
  static const String loadingMessage = 'Chargement...';
  static const String noDataMessage = 'Aucune donnée';
  static const String errorMessage = 'Une erreur est survenue';

  // Permissions par défaut
  static const Map<String, String> defaultPermissions = {
    'Ventes': 'ventes',
    'Achats': 'achats',
    'Clients': 'clients',
    'Fournisseurs': 'fournisseurs',
    'Caisse': 'caisse',
    'Banque': 'banque',
    'Articles': 'articles_view',
    'Stocks': 'stocks_view',
    'Encaissements': 'encaissements',
    'Décaissements': 'decaissements',
    'Suivi différence prix': 'suivi_prix',
    'Liste des ventes': 'liste_ventes',
    'Retour sur Ventes': 'retour_ventes',
    'Retour sur achats': 'retour_achats',
    'Information sur la société': 'info_societe',
    'Réinitialiser les données': 'reset_data',
  };

  // Raccourcis clavier
  static const Map<String, String> keyboardShortcuts = {
    'save': 'Ctrl+S',
    'cancel': 'Escape',
    'new': 'Ctrl+N',
    'delete': 'Delete',
    'search': 'Ctrl+F',
    'refresh': 'F5',
    'print': 'Ctrl+P',
  };
}
