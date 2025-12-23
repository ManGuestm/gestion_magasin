# Guide: Afficher Stock disponible par dépôts dans Right Sidebar - Article Details

## Fichier: `lib/widgets/modals/ventes_modal.dart`

### Étape 1: Ajouter la méthode helper (après la ligne ~1400, après `_getStocksToutesUnites`)

```dart
Future<String> _getStockParDepot(Article article, String depot) async {
  try {
    final stockDepart = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

    if (stockDepart == null) {
      return '0';
    }

    // Calculer le stock total en unité de base (U3)
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockDepart.stocksu1 ?? 0.0,
      stockU2: stockDepart.stocksu2 ?? 0.0,
      stockU3: stockDepart.stocksu3 ?? 0.0,
    );

    // Convertir vers les unités optimales
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

### Étape 2: Trouver le Right Sidebar dans le build method

Cherchez cette section (vers la fin du fichier, dans le build method):
```dart
// Right sidebar - Article details
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  width: _isRightSidebarCollapsed ? 40 : 280,
```

### Étape 3: Dans le Right Sidebar, après l'affichage du CMUP

Cherchez cette section dans le Right Sidebar:
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
  // ... code CMUP ...
  const SizedBox(height: 12),
],
```

### Étape 4: Ajouter le nouveau widget JUSTE APRÈS le `],` ci-dessus

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

## Résultat

Le Right Sidebar affichera maintenant pour chaque article recherché:
1. Désignation
2. Prix de vente par unité
3. Conversions d'unités
4. Prix d'achat (CMUP) - si pas vendeur
5. **STOCK DISPONIBLE PAR DÉPÔTS** ← NOUVEAU
   - Tableau avec tous les dépôts
   - Stock disponible pour chaque dépôt
   - Formatage automatique des unités

## Note importante

Le widget utilise `_searchedArticle` qui est l'article actuellement recherché dans le champ de recherche du Right Sidebar (Ctrl+F).
