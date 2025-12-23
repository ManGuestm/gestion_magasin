# Refactorisation du Modal Ventes

## 📋 Objectif
Réduire la complexité du fichier `ventes_modal.dart` (7000+ lignes) en utilisant des services métier et des widgets enfants réutilisables.

## 🏗️ Architecture Refactorisée

### Services Métier Créés

#### 1. **VenteStockService** (`services/vente_stock_service.dart`)
Gère toute la logique liée au stock :
- Vérification du stock disponible
- Calcul du stock par unité
- Prix d'achat (CMUP) et prix de vente
- Validation des unités
- Formatage de l'affichage

#### 2. **VenteClientService** (`services/vente_client_service.dart`)
Gère toute la logique liée aux clients :
- Filtrage des clients par rôle (MAG/Tous dépôts)
- Calcul du solde client
- Création de nouveaux clients
- Validation du mode crédit

### Widgets Enfants Créés

#### 1. **VentesHeaderWidget** (`widgets/modals/ventes_header_widget.dart`)
Affiche l'en-tête de la vente :
- N° Vente
- Date
- N° Facture/BL
- Heure

#### 2. **VentesLineInputWidget** (`widgets/modals/ventes_line_input_widget.dart`)
Formulaire de saisie d'une ligne de vente :
- Désignation (autocomplete)
- Dépôt
- Unité
- Quantité
- Prix unitaire
- Montant
- Boutons Ajouter/Modifier/Annuler

#### 3. **VentesListWidget** (`widgets/modals/ventes_list_widget.dart`)
Liste des ventes dans la sidebar gauche :
- Affichage des ventes par statut
- Recherche
- Sélection

#### 4. **VentesActionsWidget** (`widgets/modals/ventes_actions_widget.dart`)
Boutons d'action :
- Nouvelle vente
- Enregistrer
- Valider vers journal
- Contre-passer
- Imprimer facture/BL
- Aperçu

#### 5. **SummaryTotalsWidget** (déjà existant)
Affiche les totaux :
- Total HT
- Remise
- Total TTC
- Avance
- Reste à payer
- Nouveau solde client

#### 6. **SalesLinesListWidget** (déjà existant)
Affiche la liste des lignes de vente avec actions

## 📊 Réduction de Complexité

### Avant
- **1 fichier** : `ventes_modal.dart` (7000+ lignes)
- Logique métier mélangée avec l'UI
- Difficile à maintenir et tester

### Après
- **1 fichier principal** : `ventes_modal_refactored.dart` (~500 lignes)
- **2 services métier** : `vente_stock_service.dart`, `vente_client_service.dart`
- **6 widgets enfants** : Composants réutilisables
- **Séparation claire** : UI / Logique métier / Services

## 🔄 Migration

### Étape 1 : Tester la nouvelle version
```dart
// Dans votre code, remplacer :
VentesModal(tousDepots: false)

// Par :
VentesModalRefactored(tousDepots: false)
```

### Étape 2 : Compléter les méthodes
Les méthodes suivantes sont à compléter dans `ventes_modal_refactored.dart` :
- `_getVentesAvecStatut()` - Récupération des ventes
- `_chargerVenteExistante()` - Chargement d'une vente
- `_validerVente()` - Validation
- `_validerBrouillardVersJournal()` - Validation brouillard
- `_contrePasserVente()` - Contre-passation
- `_imprimerFacture()` / `_imprimerBL()` - Impression
- `_apercuFacture()` / `_apercuBL()` - Aperçu

### Étape 3 : Supprimer l'ancien fichier
Une fois la migration terminée et testée, supprimer `ventes_modal.dart`

## 🎯 Avantages

1. **Maintenabilité** : Code organisé et facile à comprendre
2. **Réutilisabilité** : Widgets et services réutilisables
3. **Testabilité** : Services métier testables unitairement
4. **Performance** : Widgets optimisés avec const constructors
5. **Lisibilité** : Fichiers courts et focalisés

## 📝 Services Existants Utilisés

- `VenteService` : Logique métier des ventes
- `PriceCalculationService` : Calculs de prix
- `AuthService` : Authentification
- `DatabaseService` : Accès base de données

## 🔧 Prochaines Étapes

1. Compléter les méthodes manquantes dans `ventes_modal_refactored.dart`
2. Migrer la logique PDF vers `DocumentGenerationService`
3. Ajouter des tests unitaires pour les services
4. Documenter les widgets avec des exemples
5. Optimiser les performances avec Riverpod si nécessaire

## 📚 Documentation

- Services : Voir commentaires dans chaque fichier service
- Widgets : Voir commentaires dans chaque fichier widget
- Architecture : Voir `ARCHITECTURE.md` du projet
