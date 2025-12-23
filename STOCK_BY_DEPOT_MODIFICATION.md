# Modification: Afficher Stock disponible par dépôts dans Right Sidebar

## Fichier à modifier: `lib/widgets/modals/ventes_modal.dart`

### 1. Ajouter une méthode helper pour obtenir le stock par dépôt

Ajouter cette méthode après la méthode `_getStocksToutesUnites`:

```dart
Future<String> _getStockParDepot(Article article, String depot) async {
  try {
    final stockDepart = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

    if (stockDepart == null) {
      return '0';
    }

    // Calculer le stock total en unité de base (U3) DIRECTEMENT
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockDepart.stocksu1 ?? 0.0,
      stockU2: stockDepart.stocksu2 ?? 0.0,
      stockU3: stockDepart.stocksu3 ?? 0.0,
    );

    // Convertir le stock total vers les unités optimales
    final stocksOptimaux = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: stockTotalU3,
    );

    return StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stocksOptimaux['u1']!,
      stockU2: stocksOptimaux['u2']!,
      stockU3: stocksOptimaux['u3']!,
    );
  } catch (e) {
    return '0';
  }
}
```

### 2. Modifier le Right Sidebar pour afficher les stocks par dépôt

Dans la section "Right sidebar - Article details", après l'affichage des prix d'achat (section CMUP), ajouter:

```dart
// STOCK DISPONIBLE PAR DÉPÔTS
const SizedBox(height: 12),
const Text(
  'STOCK DISPONIBLE PAR DÉPÔTS',
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
),
const SizedBox(height: 8),
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey[300]!),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'DÉPÔT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'STOCK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      // Liste des dépôts avec stocks
      ..._depots.map((depot) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  depot.depots,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Expanded(
                flex: 3,
                child: FutureBuilder<String>(
                  future: _getStockParDepot(_searchedArticle!, depot.depots),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? '...',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  ),
),
```

### 3. Emplacement exact dans le code

Chercher cette section dans le Right sidebar (après l'affichage du CMUP):

```dart
if (!_isVendeur()) ...[
  const Text(
    'PRIX D\'ACHAT',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.red,
    ),
  ),
  const SizedBox(height: 4),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Text(
      'CMUP: ${AppFunctions.formatNumber(_searchedArticle!.cmup ?? 0)}',
      style: TextStyle(
        fontSize: 12,
        color: Colors.red[700],
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  const SizedBox(height: 12),
],
```

Ajouter le nouveau code juste après cette section (après le `],`).

## Résultat attendu

Le Right Sidebar affichera maintenant:
1. Désignation de l'article
2. Prix de vente par unité
3. Conversions d'unités
4. Prix d'achat (CMUP) - si pas vendeur
5. **STOCK DISPONIBLE PAR DÉPÔTS** (NOUVEAU) - tableau avec tous les dépôts et leurs stocks respectifs
