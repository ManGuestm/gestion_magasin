import 'package:flutter/material.dart';

class MenuData {
  static const Map<String, List<String>> subMenus = {
    'Paramètres': [
      'Informations sur la société',
      'Immobilisations',
      'Dépôts',
      'Articles',
      'Commerciaux',
      'Clients',
      'Fournisseurs',
      'Banques',
      'Plan de comptes',
    ],
    'Commerces': [
      'Achats',
      'Ventes',
      'Retour de Marchandises',
      'Liste des achats',
      'Liste des ventes',
      'Mouvements Clients',
      'Approximation Stocks ...',
    ],
    'Gestions': [
      'Transfert de Marchandises',
      'Gestion Emballages',
      'Productions',
      'Régularisation compte tiers',
      'Régularisation compte Commerciaux',
      'Relance Clients',
      'Echenance Fournisseurs',
      'Variation des stocks',
      'Mise à jour des valeurs de stocks',
      'Niveau des stocks (Articles à commandées)',
      'Ammortissement des immobilisations',
      'Réactualisation de la abse de données',
    ],
    'Trésoreries': [
      'Encaissements',
      'Décaissements',
      'Chèques',
      'Effet à recevoir',
      'Virements Internes',
      'Opérations Caisses',
      'Opérations Banques',
      'Moyen de paiement',
    ],
    'États': [
      'Journal de caisse',
      'Journal des banques',
      'Etats Fournisseurs',
      'Etats Clients',
      'Etats Commerciaux',
      'Etats Immobilisations',
      'Etats Articles',
      'Etats Autres Comptes',
      'Statistiques de ventes',
      'Statistiques d\'achats',
      'Marges',
      'tableau de bord',
      'Bilan / Compte de Résultat'
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
    ],
    'Etats Clients': [
      'Fiche Clients',
      'Echéanciers',
      'Balance des comptes Clients',
      'Fiche d\'énumération Clients',
    ],
    'Etats Commerciaux': [
      'Fiche des commerciaux',
      'Balance des comptes des commerciaux',
    ],
    'Etats Immobilisations': [
      'Liste des Immobilisations',
      'Balance des Immobilisations',
    ],
    'Etats Autres Comptes': [
      'Grand livre des autres comptes',
      'Balance des autres comptes',
    ],
    'Statistiques de ventes': [
      'C.A Par Articles',
      'C.A Par Clients',
    ],
    'Statistiques d\'achats': [
      'C.A Par Articles',
    ],
    'Marges': [
      'Par Articles',
      'Par Clients',
      'Par Clients Détaillés',
    ],
    'Retour de Marchandises': [
      'Sur Achats',
      'Sur Ventes',
    ],
    'Etat tarifaire': [
      'Sans valeur d\'achats',
      'Avec valeur d\'achats',
      'Importer vers Ms Excel',
    ],
    'Echéanciers': [
      'Par BL',
      'Par règlement',
    ],
    'Balance des autres comptes': [
      'Charges',
      'Produits',
    ],
    '?': [
      'À propos',
      'Aides et documentations',
    ],
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
    IconButtonData(Icons.account_balance_wallet, 'Encaissements'),
    IconButtonData(Icons.money_off, 'Décaissements'),
    IconButtonData(Icons.balance, 'Relance Clients'),
    IconButtonData(Icons.sync_alt, 'Echéance Fournisseurs'),
    IconButtonData(Icons.shopping_basket, 'Articles à commander'),
  ];

  static const Map<String, double> menuPositions = {
    'Fichier': 0,
    'Paramètres': 70,
    'Commerces': 158,
    'Gestions': 248,
    'Trésoreries': 320,
    'États': 403,
    '?': 455,
  };

  static const Map<String, bool> hasSubMenu = {
    'Etats Articles': true,
    'Etats Fournisseurs': true,
    'Etats Clients': true,
    'Etats Commerciaux': true,
    'Etats Immobilisations': true,
    'Etats Autres Comptes': true,
    'Statistiques de ventes': true,
    'Statistiques d\'achats': true,
    'Marges': true,
    'Retour de Marchandises': true,
    'Etat tarifaire': true,
    'Echéanciers': true,
    'Balance des autres comptes': true,
  };
}

class IconButtonData {
  final IconData icon;
  final String label;

  const IconButtonData(this.icon, this.label);
}
