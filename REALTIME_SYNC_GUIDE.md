# Guide d'Intégration - Synchronisation Temps Réel

## 🎯 Objectif

Activer la synchronisation automatique des données entre tous les clients connectés au serveur.

## ✅ Modifications Effectuées

### 1. **Serveur HTTP** (`lib/services/network/http_server.dart`)

- ✅ Ajout du broadcast automatique dans `/api/execute`
- ✅ Ajout du broadcast dans `/api/sync`
- Les changements sont maintenant diffusés à tous les clients WebSocket connectés

### 2. **Client Réseau** (`lib/services/network_client.dart`)

- ✅ Amélioration de la gestion des messages WebSocket
- ✅ Notification immédiate des listeners après une opération
- ✅ Logs détaillés pour le debugging

### 3. **DatabaseService** (`lib/database/database_service.dart`)

- ✅ Broadcast automatique des changements en mode serveur
- ✅ Intégration dans `customStatement()`

### 4. **Nouveau Service** (`lib/services/realtime_sync_service.dart`)

- ✅ Service centralisé pour gérer la synchronisation temps réel
- ✅ Système de callbacks pour notifier les écrans
- ✅ Invalidation automatique du cache

### 5. **Widget Helper** (`lib/widgets/common/realtime_sync_widget.dart`)

- ✅ Widget pour simplifier l'intégration dans les écrans
- ✅ Gestion automatique du cycle de vie

## 📋 Comment Intégrer dans un Écran

### Méthode 1 : Utiliser le Widget (Recommandé)

```dart
import 'package:gestion_magasin/widgets/common/realtime_sync_widget.dart';

class MonEcran extends StatefulWidget {
  @override
  State<MonEcran> createState() => _MonEcranState();
}

class _MonEcranState extends State<MonEcran> {
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Charger vos données
    final data = await DatabaseService().getAllClients();
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeSyncWidget(
      onDataChanged: _loadData, // ← Rafraîchit automatiquement
      child: Scaffold(
        appBar: AppBar(title: Text('Mon Écran')),
        body: ListView.builder(
          itemCount: _data.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(_data[index].toString()),
          ),
        ),
      ),
    );
  }
}
```

### Méthode 2 : Utiliser le Service Directement

```dart
import 'package:gestion_magasin/services/realtime_sync_service.dart';

class MonEcran extends StatefulWidget {
  @override
  State<MonEcran> createState() => _MonEcranState();
}

class _MonEcranState extends State<MonEcran> {
  final RealtimeSyncService _syncService = RealtimeSyncService();
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _syncService.startListening();
    _syncService.addRefreshCallback(_onDataChanged);
    _loadData();
  }

  @override
  void dispose() {
    _syncService.removeRefreshCallback(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    debugPrint('🔄 Données modifiées, rafraîchissement...');
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService().getAllClients();
    if (mounted) {
      setState(() => _data = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mon Écran')),
      body: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_data[index].toString()),
        ),
      ),
    );
  }
}
```

## 🔥 Scénarios de Synchronisation

### Scénario 1 : Vente sur Client A

```Client A (Vendeur) → Fait une vente
    ↓
Envoi HTTP POST /api/execute au Serveur
    ↓
Serveur enregistre + BROADCAST WebSocket
    ↓
✅ Client B (Admin) reçoit notification → Rafraîchit tableau de bord
✅ Client C (Caisse) reçoit notification → Met à jour liste ventes
```

### Scénario 2 : Ajout Article sur Serveur

```Serveur → Ajout d'un article
    ↓
customStatement() appelé
    ↓
BROADCAST automatique via NetworkServer
    ↓
✅ Tous les clients reçoivent la notification
✅ Les écrans avec RealtimeSyncWidget se rafraîchissent
```

### Scénario 3 : Modification Client sur Client B

```Client B → Modifie un client
    ↓
Envoi au Serveur via /api/execute
    ↓
Serveur enregistre + BROADCAST
    ↓
✅ Client A voit la modification immédiatement
✅ Client C voit la modification immédiatement
```

## 🧪 Test de la Synchronisation

### 1. Démarrer le Serveur

```bash
# Sur l'ordinateur serveur
flutter run -d windows
# Choisir mode "Serveur" dans la configuration réseau
```

### 2. Connecter les Clients

```bash
# Sur chaque ordinateur client
flutter run -d windows
# Choisir mode "Client"
# Entrer l'IP du serveur (ex: 192.168.1.100)
# Port: 8080
# Username: admin
# Password: admin123
```

### 3. Tester la Synchronisation

#### Test 1 : Vente

- Client A : Créer une vente
- Client B : Vérifier que la vente apparaît dans le tableau de bord
- Serveur : Vérifier que la vente est visible

#### Test 2 : Article

- Serveur : Ajouter un article
- Client A : Vérifier que l'article apparaît dans la liste
- Client B : Vérifier que l'article apparaît dans la liste

#### Test 3 : Client

- Client A : Ajouter un client
- Client B : Vérifier que le client apparaît
- Serveur : Vérifier que le client est enregistré

## 📊 Logs de Débogage

Les logs suivants confirment la synchronisation :

**Serveur :**

```✏️ Execute: INSERT INTO ventes ... by vendeur1
🔥 Broadcasting change to 3 clients
✅ Execute réussie pour vendeur1
```

**Client :**

```🔔 Changement reçu: insert
🔄 Traitement changement: insert
📥 Changement reçu du serveur: insert
✅ 2 écrans notifiés
```

## ⚠️ Points Importants

1. **WebSocket requis** : La synchronisation temps réel nécessite une connexion WebSocket active
2. **Cache invalidé** : Le cache est automatiquement invalidé lors des changements
3. **Callbacks multiples** : Plusieurs écrans peuvent écouter simultanément
4. **Mode serveur** : Le broadcast n'est actif qu'en mode serveur
5. **Gestion d'erreurs** : Les erreurs de callback n'affectent pas les autres listeners

## 🚀 Prochaines Étapes

Pour intégrer dans vos écrans existants :

1. Identifier les écrans qui affichent des données partagées
2. Ajouter `RealtimeSyncWidget` autour du Scaffold
3. Implémenter une méthode de rafraîchissement
4. Tester avec plusieurs clients connectés

## 📝 Exemple Complet : Tableau de Bord

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../widgets/common/realtime_sync_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  int _totalVentes = 0;
  int _totalClients = 0;
  double _chiffreAffaires = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final ventes = await _db.getTotalVentes();
    final clients = await _db.getTotalClients();
    final ca = await _db.getVentesToday();
    
    if (mounted) {
      setState(() {
        _totalVentes = ventes.toInt();
        _totalClients = clients;
        _chiffreAffaires = ca;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeSyncWidget(
      onDataChanged: () {
        debugPrint('🔄 Rafraîchissement du tableau de bord');
        _loadStats();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Tableau de Bord')),
        body: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Ventes'),
                trailing: Text('$_totalVentes'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Clients'),
                trailing: Text('$_totalClients'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('CA Aujourd\'hui'),
                trailing: Text('${_chiffreAffaires.toStringAsFixed(2)} Ar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## ✅ Résultat Final

Avec ces modifications :

✅ **Synchronisation automatique** entre tous les clients
✅ **Temps réel** : Les changements apparaissent immédiatement
✅ **Pas de polling** : Utilise WebSocket pour l'efficacité
✅ **Facile à intégrer** : Un simple widget wrapper
✅ **Robuste** : Gestion d'erreurs et fallback sur cache local

La synchronisation est maintenant **ACTIVE** et **FONCTIONNELLE** ! 🎉
