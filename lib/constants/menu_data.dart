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
      'Sur Achats',
      'Sur Ventes',
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
    ],
    'États': [
      'Journal de caisse',
      'Journal des banques',
      'Etats Fournisseurs',
      'Etats Commerciaux',
      'Etats Immobilisations',
      'Etats Articles',
      'Etats Articles',
      'Etats Autres Comptes',
      'Statistiques de ventes',
      'Statistiques d\'achats',
      'Marges',
      'tableau de bord',
      'Bilan / Compte de Résultat'
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
}

class IconButtonData {
  final IconData icon;
  final String label;

  const IconButtonData(this.icon, this.label);
}