import 'package:flutter/material.dart';

class MenuData {
  // Constantes pour éviter les erreurs de frappe
  static const String fichier = 'Fichier';
  static const String parametres = 'Paramètres';
  static const String commerces = 'Commerces';
  static const String gestions = 'Gestions';
  static const String tresoreries = 'Trésoreries';
  static const String etats = 'États';
  static const String aide = '?';

  static const Map<String, List<String>> subMenus = {
    fichier: ['Profil', 'Gestion des utilisateurs', 'Clients connectés', 'Sauvegarder et Restaurer'],
    parametres: [
      'Informations sur la société',
      'Dépôts',
      'Articles',
      'Clients',
      'Fournisseurs',
      // 'Plan de comptes',
      // 'Importation des données',
      'Réinitialiser les données',
    ],
    commerces: [
      'Achats',
      'Ventes',
      'Retour de Marchandises',
      'Liste des achats',
      'Liste des ventes',
      'Mouvements Clients',
      'Approximation Stocks ...',
    ],
    gestions: [
      'Transfert de Marchandises',
      'Gestion Emballages',
      'Régularisation compte tiers',
      'Relance Clients',
      'Echéance Fournisseurs',
      'Mise à jour des valeurs de stocks',
      'Niveau des stocks (Articles à commandées)',
      'Réactualisation de la base de données',
    ],
    tresoreries: ['Encaissements', 'Décaissements', 'Comptes fournisseurs', 'Moyen de paiement'],
    etats: [
      'Journal de caisse',
      'Etats Fournisseurs',
      'Etats Clients',
      'Etats Articles',
      'Statistiques de ventes',
      'Statistiques d\'achats',
      'Marges',
    ],
    'Etats Articles': [
      'Etiquettes de prix',
      'Etat tarifaire',
      'Etat de stocks',
      'Mouvement de stocks journalières',
      'Fiche de stocks',
      'Estimation en valeur des articles (CMUP)',
    ],
    'Etats Fournisseurs': [
      'Fiche Fournisseurs',
      'Balance des comptes Fournisseurs',
      'Statistiques fournisseurs',
    ],
    'Etats Clients': [
      'Fiche Clients',
      'Echéanciers',
      'Balance des comptes Clients',
      'Fiche d\'énumération Clients',
    ],
    'Statistiques de ventes': ['C.A Par Articles', 'C.A Par Clients', 'Suivi de différence de Prix de vente'],
    'Statistiques d\'achats': ['C.A Par Articles'],
    'Marges': ['Par Articles', 'Par Clients', 'Par Clients Détaillés'],
    'Retour de Marchandises': ['Sur Ventes', 'Retours achats'],
    'Etat tarifaire': ['Sans valeur d\'achats', 'Avec valeur d\'achats', 'Importer vers Ms Excel'],
    'Echéanciers': ['Par BL', 'Par règlement'],
    'Sauvegarder et Restaurer': ['Sauvegarder la base de données', 'Restaurer la base de données'],
    'Importation des données': [
      'Importer Articles',
      'Importer Fournisseurs',
      'Importer Clients',
      'Importer Moyens de paiement',
    ],
    aide: ['À propos', 'Aides et documentations'],
  };

  static const List<IconButtonData> iconButtons = [
    IconButtonData(Icons.home, 'Dépôts'),
    IconButtonData(Icons.inventory_2, 'Articles'),
    IconButtonData(Icons.people, 'Clients'),
    IconButtonData(Icons.business, 'Fournisseurs'),
    IconButtonData(Icons.account_tree, 'Plan de comptes'),
    IconButtonData(Icons.shopping_cart, 'Achats'),
    IconButtonData(Icons.point_of_sale, 'Ventes'),
    IconButtonData(Icons.swap_horiz, 'Transferts'),
    IconButtonData(Icons.inventory, 'Inventaire'),
    IconButtonData(Icons.account_balance_wallet, 'Encaissements'),
    IconButtonData(Icons.money_off, 'Décaissements'),
    IconButtonData(Icons.balance, 'Relance Clients'),
    IconButtonData(Icons.sync_alt, 'Echéance Fournisseurs'),
    IconButtonData(Icons.shopping_basket, 'Articles à commander'),
    IconButtonData(Icons.account_balance_wallet, 'Régularisation compte tiers'),
    IconButtonData(Icons.price_change, 'Suivi de différence de Prix de vente'),
  ];

  static const Map<String, double> menuPositions = {
    fichier: 0,
    parametres: 70,
    commerces: 158,
    gestions: 248,
    tresoreries: 320,
    etats: 403,
    aide: 455,
  };

  static const Map<String, bool> hasSubMenu = {
    'Etats Articles': true,
    'Etats Fournisseurs': true,
    'Etats Clients': true,
    'Statistiques de ventes': true,
    'Statistiques d\'achats': true,
    'Marges': true,
    'Retour de Marchandises': true,
    'Etat tarifaire': true,
    'Echéanciers': true,
    'Sauvegarder et Restaurer': true,
    'Importation des données': true,
  };
}

class IconButtonData {
  final IconData icon;
  final String label;

  const IconButtonData(this.icon, this.label);
}
