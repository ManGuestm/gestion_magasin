# Logique de Conversion Automatique des Stocks

## Vue d'ensemble

Cette documentation décrit l'implémentation de la logique de conversion automatique des stocks selon vos spécifications. Le système gère automatiquement la conversion entre différentes unités de mesure pour optimiser l'affichage et les calculs de stock.

## Principe de fonctionnement

### Configuration des articles

Chaque article peut avoir jusqu'à 3 unités de mesure :
- **u1** : Unité la plus grande (ex: Ctn - Carton)
- **u2** : Unité intermédiaire (ex: Grs - Gros)  
- **u3** : Unité la plus petite (ex: Pcs - Pièces)

Les facteurs de conversion sont définis par :
- **tu2u1** : Nombre d'unités u2 dans 1 unité u1 (ex: 50 Grs = 1 Ctn)
- **tu3u2** : Nombre d'unités u3 dans 1 unité u2 (ex: 10 Pcs = 1 Grs)

### Exemples de configuration

#### Good Look Maintso
```
u1 = "Ctn", u2 = "Grs", u3 = "Pcs"
tu2u1 = 50 (1 Ctn = 50 Grs)
tu3u2 = 10 (1 Grs = 10 Pcs)
```

#### Gauffrette
```
u1 = "Ctn", u2 = "Pqt", u3 = null
tu2u1 = 2 (1 Ctn = 2 Pqt)
tu3u2 = null
```

## Fonctionnalités implémentées

### 1. Conversion automatique des stocks (`convertirStockOptimal`)

Convertit automatiquement les excédents vers les unités supérieures :

**Exemple Good Look Maintso :**
- Stock brut : 48 Ctn, 230 Grs, 13 Pcs
- Conversion : 230 Grs = 4×50 + 30 = 4 Ctn + 30 Grs
- Conversion : 13 Pcs = 1×10 + 3 = 1 Grs + 3 Pcs
- **Résultat final : 52 Ctn / 31 Grs / 3 Pcs**

**Exemple Gauffrette :**
- Stock brut : 12 Ctn, 33 Pqt
- Conversion : 33 Pqt = 16×2 + 1 = 16 Ctn + 1 Pqt
- **Résultat final : 28 Ctn / 1 Pqt**

### 2. Conversion des achats (`convertirQuantiteAchat`)

Convertit une quantité d'achat vers les unités optimales :

```dart
// Achat de 230 Grs
final conversion = StockConverter.convertirQuantiteAchat(
  article: article,
  uniteAchat: 'Grs',
  quantiteAchat: 230.0,
);
// Résultat : 4 Ctn + 30 Grs + 0 Pcs
```

### 3. Formatage d'affichage (`formaterAffichageStock`)

Formate l'affichage selon le modèle demandé :

```dart
final affichage = StockConverter.formaterAffichageStock(
  article: article,
  stockU1: 52.0,
  stockU2: 31.0,
  stockU3: 3.0,
);
// Résultat : "52 Ctn / 31 Grs / 3 Pcs"
```

### 4. Calcul du stock total (`calculerStockTotalU3`)

Calcule le stock total en unité de base (u3) :

```dart
final stockTotal = StockConverter.calculerStockTotalU3(
  article: article,
  stockU1: 52.0,
  stockU2: 31.0,
  stockU3: 3.0,
);
// Résultat : 26313 Pcs (52×50×10 + 31×10 + 3)
```

### 5. Vérification de stock suffisant (`verifierStockSuffisant`)

Vérifie si le stock est suffisant pour une vente :

```dart
final suffisant = StockConverter.verifierStockSuffisant(
  article: article,
  stockU1: 52.0,
  stockU2: 31.0,
  stockU3: 3.0,
  uniteVente: 'Ctn',
  quantiteVente: 1.0,
);
// Résultat : true
```

### 6. Décomposition pour vente (`decomposerVentePourDeduction`)

Décompose une vente pour déduction intelligente du stock :

```dart
final decomposition = StockConverter.decomposerVentePourDeduction(
  article: article,
  stockU1: 52.0,
  stockU2: 31.0,
  stockU3: 3.0,
  uniteVente: 'Grs',
  quantiteVente: 100.0,
);
// Résultat : quantités à déduire de chaque unité
```

## Intégration dans l'application

### 1. Modal Articles (`articles_modal.dart`)

- Affichage automatique des stocks avec conversion
- Utilisation de `formaterAffichageStock` pour l'affichage uniforme

### 2. Modal Achats (`achats_modal.dart`)

- Conversion automatique des achats lors de l'enregistrement
- Mise à jour des stocks avec `convertirStockOptimal`
- Calcul automatique du CMUP avec les nouvelles quantités

### 3. Modal Ventes (`ventes_modal.dart`)

- Vérification de stock avec `verifierStockSuffisant`
- Déduction intelligente avec `decomposerVentePourDeduction`
- Affichage du stock disponible avec conversion

### 4. Base de données (`database.dart`)

- Méthode `_mettreAJourStocksVente` mise à jour pour utiliser la conversion
- Enregistrement des ventes avec gestion automatique des stocks

## Avantages de cette implémentation

1. **Cohérence** : Tous les modules utilisent la même logique de conversion
2. **Automatisation** : Plus besoin de calculs manuels de conversion
3. **Flexibilité** : Support de 2 ou 3 unités selon l'article
4. **Précision** : Évite les erreurs de calcul manuel
5. **Maintenabilité** : Logique centralisée dans `StockConverter`

## Utilisation

### Pour ajouter la logique à un nouveau module :

1. Importer `StockConverter` :
```dart
import '../../utils/stock_converter.dart';
```

2. Utiliser les méthodes selon le besoin :
```dart
// Pour l'affichage
final affichage = StockConverter.formaterAffichageStock(...);

// Pour les achats
final conversion = StockConverter.convertirQuantiteAchat(...);

// Pour les ventes
final suffisant = StockConverter.verifierStockSuffisant(...);
```

## Tests et démonstration

Un modal de démonstration est disponible dans `stock_conversion_demo_modal.dart` pour tester la logique avec différents paramètres.

Des exemples d'utilisation sont fournis dans `stock_converter_example.dart` pour comprendre le fonctionnement.