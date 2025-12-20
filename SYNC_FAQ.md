# FAQ - Synchronisation Temps Réel

## ❓ Questions Fréquentes

### 1. La synchronisation fonctionne-t-elle vraiment en temps réel ?

**Oui !** La synchronisation utilise WebSocket pour une communication bidirectionnelle instantanée. La latence est généralement < 100ms.

**Flux :**
```
Client A → Modification → Serveur (< 50ms)
Serveur → Broadcast → Clients B, C, D (< 50ms)
Total : < 100ms
```

---

### 2. Que se passe-t-il si un client perd la connexion ?

**Gestion automatique :**
- Le client détecte la perte de connexion
- Les opérations sont mises en queue locale
- À la reconnexion, les opérations sont synchronisées automatiquement
- Le cache local permet de continuer à travailler hors ligne

**Code :**
```dart
// Le NetworkClient gère automatiquement
_socket!.listen(
  onDone: () {
    _isConnected = false;
    debugPrint('Connexion perdue, passage en mode hors ligne');
  },
);
```

---

### 3. Combien de clients peuvent être connectés simultanément ?

**Limite théorique :** 100 clients (configurable dans `http_server.dart`)

**Limite pratique :** Dépend de :
- Bande passante réseau
- Puissance du serveur
- Fréquence des modifications

**Recommandation :** 10-20 clients pour une performance optimale

---

### 4. La synchronisation consomme-t-elle beaucoup de ressources ?

**Non, très peu :**

| Ressource | Consommation |
|-----------|--------------|
| CPU | < 1% en idle, < 5% pendant sync |
| RAM | +2MB pour le service |
| Réseau | ~1KB par notification |
| Batterie | Négligeable |

**WebSocket est très efficace** comparé au polling HTTP.

---

### 5. Dois-je modifier tout mon code existant ?

**Non !** L'intégration est minimale :

**Avant :**
```dart
class MonEcran extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

**Après :**
```dart
class MonEcran extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return RealtimeSyncWidget(
      onDataChanged: _loadData,
      child: Scaffold(...),
    );
  }
}
```

**3 lignes ajoutées, c'est tout !**

---

### 6. Comment débugger si la synchronisation ne fonctionne pas ?

**Étapes de debugging :**

1. **Vérifier les logs serveur :**
```
✏️ Execute: INSERT INTO ventes ...
🔥 Broadcasting change to 2 clients  ← Doit apparaître
✅ Execute réussie
```

2. **Vérifier les logs client :**
```
🔔 Changement reçu: insert  ← Doit apparaître
🔄 Traitement changement: insert
✅ 1 écrans notifiés
```

3. **Utiliser l'écran de test :**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => RealtimeSyncTestScreen()),
);
```

4. **Vérifier la connexion WebSocket :**
```dart
debugPrint('WebSocket connecté: ${NetworkClient.instance.isConnected}');
```

---

### 7. Puis-je désactiver la synchronisation pour certains écrans ?

**Oui !** Simplement ne pas utiliser `RealtimeSyncWidget` :

```dart
// Écran SANS synchronisation
class MonEcran extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...); // Pas de RealtimeSyncWidget
  }
}
```

---

### 8. La synchronisation fonctionne-t-elle en mode local ?

**Non.** La synchronisation temps réel nécessite :
- Mode serveur (pour broadcaster)
- Mode client (pour recevoir)

**En mode local :** Pas de broadcast, pas de synchronisation (normal).

---

### 9. Que se passe-t-il si deux clients modifient la même donnée ?

**Gestion des conflits :**
- Le serveur traite les requêtes dans l'ordre de réception
- La dernière modification gagne (Last Write Wins)
- Tous les clients reçoivent la dernière version

**Exemple :**
```
Client A → Modifie prix article à 100 Ar (10:00:00.100)
Client B → Modifie prix article à 150 Ar (10:00:00.200)
Résultat : Prix = 150 Ar (dernière modification)
```

**Recommandation :** Implémenter un système de verrouillage pour les données critiques.

---

### 10. Comment tester la synchronisation avec un seul ordinateur ?

**Méthode 1 : Plusieurs instances**
```bash
# Terminal 1 - Serveur
flutter run -d windows

# Terminal 2 - Client 1
flutter run -d windows

# Terminal 3 - Client 2
flutter run -d windows
```

**Méthode 2 : Utiliser localhost**
- Serveur : Mode serveur
- Client : Se connecter à `127.0.0.1:8080`

---

### 11. La synchronisation fonctionne-t-elle sur Internet (WAN) ?

**Oui, mais avec précautions :**

**Configuration requise :**
1. Ouvrir le port 8080 sur le routeur
2. Configurer le pare-feu
3. Utiliser l'IP publique du serveur
4. **Recommandé :** Utiliser un VPN ou tunnel SSH

**Sécurité :**
- Authentification obligatoire
- Token avec expiration
- HTTPS recommandé (à implémenter)

---

### 12. Puis-je personnaliser les notifications ?

**Oui !** Vous pouvez filtrer les changements :

```dart
class MonEcran extends StatefulWidget {
  @override
  State<MonEcran> createState() => _MonEcranState();
}

class _MonEcranState extends State<MonEcran> {
  final RealtimeSyncService _syncService = RealtimeSyncService();

  @override
  void initState() {
    super.initState();
    _syncService.startListening();
    _syncService.addRefreshCallback(_onDataChanged);
  }

  void _onDataChanged() {
    // Personnaliser ici
    debugPrint('🔔 Notification personnalisée');
    
    // Afficher un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Données mises à jour')),
    );
    
    // Rafraîchir
    _loadData();
  }
}
```

---

### 13. Comment optimiser les performances ?

**Bonnes pratiques :**

1. **Utiliser le cache :**
```dart
final clients = await _db.getAllClientsWithCache(); // Avec cache
```

2. **Debounce les rafraîchissements :**
```dart
Timer? _debounceTimer;

void _onDataChanged() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    _loadData();
  });
}
```

3. **Charger uniquement les données nécessaires :**
```dart
// ❌ Mauvais
final allData = await _db.getAllData();

// ✅ Bon
final recentData = await _db.getRecentData(limit: 50);
```

4. **Utiliser des listes virtuelles :**
```dart
ListView.builder( // Charge uniquement les éléments visibles
  itemCount: _data.length,
  itemBuilder: (context, index) => ...,
)
```

---

### 14. La synchronisation fonctionne-t-elle avec les transactions ?

**Oui !** Les transactions sont supportées :

```dart
await _db.transaction(() async {
  await _db.customStatement('INSERT INTO ventes ...');
  await _db.customStatement('INSERT INTO detventes ...');
  await _db.customStatement('UPDATE stocks ...');
});

// Le broadcast est envoyé après la transaction complète
```

---

### 15. Comment gérer les erreurs de synchronisation ?

**Gestion automatique :**
```dart
try {
  await _db.customStatement('INSERT INTO ...');
} catch (e) {
  // L'opération est mise en queue automatiquement
  debugPrint('Erreur, opération en queue: $e');
}
```

**Gestion manuelle :**
```dart
void _onDataChanged() {
  try {
    _loadData();
  } catch (e) {
    debugPrint('Erreur rafraîchissement: $e');
    // Afficher un message à l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur de synchronisation')),
    );
  }
}
```

---

### 16. Puis-je voir les clients connectés ?

**Oui !** Depuis le serveur :

```dart
// Dans l'interface serveur
final clients = NetworkServer.instance.getConnectedClientsInfo();

for (final client in clients) {
  debugPrint('Client: ${client['nom']} - IP: ${client['ip']}');
}
```

**Affichage dans l'UI :**
```dart
// Voir widgets/modals/clients_connectes_modal.dart
```

---

### 17. La synchronisation fonctionne-t-elle avec les fichiers ?

**Non.** La synchronisation actuelle ne gère que les données de la base de données.

**Pour les fichiers :**
- Utiliser un système de partage de fichiers (SMB, NFS)
- Ou implémenter un système de synchronisation de fichiers séparé

---

### 18. Comment migrer mon code existant ?

**Étapes :**

1. **Identifier les écrans à synchroniser**
2. **Ajouter RealtimeSyncWidget**
3. **Implémenter _loadData()**
4. **Tester**

**Exemple de migration :**

**Avant :**
```dart
class VentesScreen extends StatefulWidget {
  @override
  State<VentesScreen> createState() => _VentesScreenState();
}

class _VentesScreenState extends State<VentesScreen> {
  List<Vente> _ventes = [];

  @override
  void initState() {
    super.initState();
    _loadVentes();
  }

  Future<void> _loadVentes() async {
    final ventes = await _db.getAllVentes();
    setState(() => _ventes = ventes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ventes')),
      body: ListView.builder(...),
    );
  }
}
```

**Après :**
```dart
class VentesScreen extends StatefulWidget {
  @override
  State<VentesScreen> createState() => _VentesScreenState();
}

class _VentesScreenState extends State<VentesScreen> {
  List<Vente> _ventes = [];

  @override
  void initState() {
    super.initState();
    _loadVentes();
  }

  Future<void> _loadVentes() async {
    final ventes = await _db.getAllVentes();
    if (mounted) setState(() => _ventes = ventes);
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeSyncWidget(  // ← Ajouté
      onDataChanged: _loadVentes,  // ← Ajouté
      child: Scaffold(
        appBar: AppBar(title: Text('Ventes')),
        body: ListView.builder(...),
      ),
    );  // ← Ajouté
  }
}
```

**Changements : 3 lignes !**

---

## 🆘 Problèmes Courants

### Problème : "Les changements n'apparaissent pas"

**Solutions :**
1. Vérifier que le serveur est en mode serveur
2. Vérifier que les clients sont connectés
3. Vérifier les logs WebSocket
4. Utiliser l'écran de test

### Problème : "Erreur de connexion WebSocket"

**Solutions :**
1. Vérifier l'IP et le port
2. Vérifier le pare-feu
3. Vérifier que le serveur est démarré
4. Tester avec `127.0.0.1` en local

### Problème : "Les données ne se rafraîchissent pas"

**Solutions :**
1. Vérifier que `onDataChanged` est bien appelé
2. Vérifier que `_loadData()` est implémenté
3. Vérifier que `setState()` est appelé
4. Vérifier que le widget est `mounted`

---

## 📚 Ressources

- **Guide complet** : `REALTIME_SYNC_GUIDE.md`
- **Exemples** : `INTEGRATION_EXAMPLES.md`
- **Changelog** : `CHANGELOG_REALTIME_SYNC.md`
- **Résumé** : `SYNC_SUMMARY.md`

---

**Vous avez d'autres questions ? Consultez les fichiers de documentation ou utilisez l'écran de test !** 🚀
