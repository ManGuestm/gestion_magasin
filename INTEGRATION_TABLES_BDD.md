# Intégration des Tables de Base de Données

## Modifications Apportées

### 1. Modal de Mouvement de Stock (`mouvement_stock_modal.dart`)
- **Avant** : Utilisait des méthodes Drift ORM basiques
- **Après** : Utilise les requêtes SQL directes pour manipuler les tables `stocks`, `depart` et `articles`
- **Améliorations** :
  - Chargement des dépôts depuis la table `depots`
  - Chargement des unités depuis la table `articles`
  - Mise à jour correcte des stocks par dépôt (table `depart`)
  - Création de mouvements dans la table `stocks`

### 2. Service de Gestion des Stocks (`stock_management_service.dart`)
- **Nouvelles fonctionnalités** :
  - Gestion complète des mouvements de stock (entrées, sorties, transferts, inventaires)
  - Calcul automatique du CMUP (Coût Moyen Unitaire Pondéré)
  - Mise à jour synchronisée des tables `stocks`, `depart` et `articles`
  - Historique complet des mouvements
- **Tables utilisées** :
  - `stocks` : Enregistrement de tous les mouvements
  - `depart` : Stocks par dépôt et par article
  - `articles` : Stocks globaux et CMUP

### 3. Service des Achats (`achat_service.dart`)
- **Fonctionnalités** :
  - Enregistrement complet des achats avec détails
  - Mise à jour automatique des stocks et CMUP
  - Gestion des soldes fournisseurs
  - Statistiques d'achats
- **Tables utilisées** :
  - `achats` : Achats principaux
  - `detachats` : Détails des achats
  - `stocks` : Mouvements d'entrée
  - `depart` : Stocks par dépôt
  - `articles` : Stocks globaux et CMUP
  - `frns` : Mise à jour soldes fournisseurs
  - `comptefrns` : Mouvements de compte fournisseur

### 4. Service de Trésorerie (`tresorerie_service.dart`)
- **Fonctionnalités** :
  - Gestion des opérations de caisse et banque
  - Gestion des chèques
  - Virements internes
  - Journaux de trésorerie
- **Tables utilisées** :
  - `caisse` : Opérations de caisse
  - `banque` : Opérations bancaires
  - `chequier` : Gestion des chèques
  - `bq` : Configuration des banques

### 5. Service des Ventes (`vente_service.dart`)
- **Améliorations** :
  - Utilisation de requêtes SQL directes
  - Mise à jour correcte des stocks multi-unités
  - Gestion des comptes clients
- **Tables utilisées** :
  - `ventes` : Ventes principales
  - `detventes` : Détails des ventes
  - `stocks` : Mouvements de sortie
  - `depart` : Stocks par dépôt
  - `articles` : Stocks globaux
  - `clt` : Soldes clients
  - `compteclt` : Mouvements de compte client

### 6. Service de Rapports et Statistiques (`rapport_statistiques_service.dart`)
- **Fonctionnalités complètes** :
  - Statistiques de ventes et achats
  - Top des articles et clients
  - Évolution mensuelle
  - États des stocks par dépôt
  - Calcul des marges
  - Soldes clients et fournisseurs
  - Commissions commerciaux
  - Mouvements de stock détaillés
  - Tableau de bord général

## Tables de Base de Données Utilisées

### Tables Principales
- **articles** : Gestion des produits avec unités multiples et CMUP
- **clt** : Clients avec soldes et conditions commerciales
- **frns** : Fournisseurs avec soldes
- **depots** : Dépôts de stockage
- **com** : Commerciaux

### Tables Transactionnelles
- **ventes** / **detventes** : Ventes et détails
- **achats** / **detachats** : Achats et détails
- **stocks** : Tous les mouvements de stock
- **depart** : Stocks par dépôt et par article

### Tables de Trésorerie
- **caisse** : Opérations de caisse
- **banque** : Opérations bancaires
- **bq** : Configuration des banques
- **chequier** : Gestion des chèques

### Tables de Comptes
- **compteclt** : Mouvements de comptes clients
- **comptefrns** : Mouvements de comptes fournisseurs
- **comptecom** : Commissions commerciaux

### Tables de Configuration
- **soc** : Informations société
- **users** : Utilisateurs du système
- **mp** : Modes de paiement

## Avantages de l'Intégration

### 1. Cohérence des Données
- Synchronisation automatique entre toutes les tables
- Intégrité référentielle respectée
- Calculs automatiques (CMUP, soldes, stocks)

### 2. Performance
- Requêtes SQL optimisées
- Utilisation d'index sur les clés primaires
- Transactions pour garantir la cohérence

### 3. Fonctionnalités Avancées
- Gestion multi-dépôts
- Unités de mesure multiples avec conversions
- Calcul automatique des marges
- Historique complet des mouvements

### 4. Rapports Complets
- Statistiques en temps réel
- Analyses de performance
- Suivi des soldes et échéances
- Tableaux de bord détaillés

## Utilisation

Tous les services sont des singletons et peuvent être utilisés directement :

```dart
// Mouvement de stock
final stockService = StockManagementService();
await stockService.enregistrerMouvement(mouvement);

// Achat
final achatService = AchatService();
await achatService.enregistrerAchatComplet(achat: achat, lignesAchat: lignes);

// Trésorerie
final tresorerieService = TresorerieService();
await tresorerieService.enregistrerOperationCaisse(libelle: 'Vente', montant: 1000, type: 'ENTREE');

// Rapports
final rapportService = RapportStatistiquesService();
final stats = await rapportService.getStatistiquesVentes(debut, fin);
```

Cette intégration garantit une utilisation optimale de toutes les tables de la base de données selon le schéma défini, avec une cohérence parfaite des données et des performances optimisées.