# Patch pour ventes_modal.dart

## Modifications à apporter

Dans le fichier `lib/widgets/modals/ventes_modal.dart`, recherchez tous les appels à :

### 1. `_venteService.enregistrerVenteBrouillard`

Ajoutez le paramètre `tousDepots: widget.tousDepots,` à chaque appel.

**Avant :**
```dart
await _venteService.enregistrerVenteBrouillard(
  numVentes: numVentes,
  nFacture: nFacture,
  date: date,
  client: client,
  modePaiement: modePaiement,
  totalTTC: totalTTC,
  avance: avance,
  commercial: commercial,
  remise: remise,
  lignesVente: lignesVente,
  heure: heure,
);
```

**Après :**
```dart
await _venteService.enregistrerVenteBrouillard(
  numVentes: numVentes,
  nFacture: nFacture,
  date: date,
  client: client,
  modePaiement: modePaiement,
  totalTTC: totalTTC,
  avance: avance,
  commercial: commercial,
  remise: remise,
  lignesVente: lignesVente,
  heure: heure,
  tousDepots: widget.tousDepots,
);
```

### 2. `_venteService.enregistrerVenteDirecteJournal`

Ajoutez le paramètre `tousDepots: widget.tousDepots,` à chaque appel.

**Avant :**
```dart
await _venteService.enregistrerVenteDirecteJournal(
  numVentes: numVentes,
  nFacture: nFacture,
  date: date,
  client: client,
  modePaiement: modePaiement,
  totalTTC: totalTTC,
  avance: avance,
  commercial: commercial,
  remise: remise,
  lignesVente: lignesVente,
  heure: heure,
);
```

**Après :**
```dart
await _venteService.enregistrerVenteDirecteJournal(
  numVentes: numVentes,
  nFacture: nFacture,
  date: date,
  client: client,
  modePaiement: modePaiement,
  totalTTC: totalTTC,
  avance: avance,
  commercial: commercial,
  remise: remise,
  lignesVente: lignesVente,
  heure: heure,
  tousDepots: widget.tousDepots,
);
```

## Résumé

Le paramètre `widget.tousDepots` est déjà disponible dans le widget `VentesModal` et indique :
- `true` = Vente "Tous dépôts" → type = 'TOUS_DEPOTS'
- `false` = Vente "Magasin" → type = 'MAG'

Ce paramètre sera automatiquement inséré dans le champ `type` de la table `ventes`.
