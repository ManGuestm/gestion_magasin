# ⚡ QUICK START - Utiliser la Nouvelle Architecture

## 1️⃣ Mode LOCAL (défaut - pas de réseau)

```dart
import 'package:gestion_magasin/database/database_service.dart';

void main() {
  final db = DatabaseService();
  
  // Initialiser en mode local
  await db.initializeLocal();
  
  // Utiliser comme avant
  final clients = await db.database.getAllClients();
  print('Clients: ${clients.length}');
}
```

---

## 2️⃣ Mode CLIENT (connecté au serveur)

```dart
import 'package:gestion_magasin/database/database_service.dart';

void main() async {
  final db = DatabaseService();
  
  // Connecter au serveur
  final success = await db.initializeAsClient(
    '192.168.1.100',  // IP du serveur
    8080,             // Port du serveur
    'admin',          // Username
    'password123',    // Password
  );
  
  if (!success) {
    print('Connexion échouée - basculer en mode local');
    await db.initializeLocal();
    return;
  }
  
  print('Connecté au serveur');
  
  // ✅ Lire avec cache + fallback
  final clients = await db.getAllClientsWithCache();
  
  // ✅ Écrire en offline-first queue
  final newClient = CltCompanion(
    rsoc: const Value('NEW001'),
    designation: const Value('Nouveau Client'),
  );
  await db.addClientWithSync(newClient);
  
  // ✅ Synchroniser quand connecté
  await db.syncWithServer();
}
```

---

## 3️⃣ Services Individuels

### CacheManager

```dart
import 'package:gestion_magasin/services/sync/cache_manager.dart';

final cache = CacheManager();
await cache.initialize();

// Sauvegarder
await cache.setCache('key', data, version: 1);

// Récupérer
final cached = await cache.getCache<MyType>(
  'key',
  expectedVersion: 1,
  maxAge: Duration(minutes: 15),
);

// Invalider
await cache.invalidateCache('key');
```

### SyncQueueService

```dart
import 'package:gestion_magasin/services/sync/sync_queue_service.dart';

final queue = SyncQueueService();
await queue.initialize();

// Ajouter opération offline
await queue.addOperation(
  table: 'clt',
  operation: SyncOperationType.insert,
  data: {'rsoc': '001'},
);

// Récupérer en attente
final pending = await queue.getPendingOperations();

// Marquer comme synced
await queue.markAsSynced(itemId);
```

### AuthTokenService

```dart
import 'package:gestion_magasin/services/auth/auth_token_service.dart';

final auth = AuthTokenService();
await auth.initialize();

// S'authentifier
final token = await auth.authenticate(
  'http://192.168.1.100:8080',
  'user',
  'pass',
);

// Vérifier
if (auth.isAuthenticated) {
  print('Utilisateur: ${auth.username}');
}

// Logout
await auth.logout();
```

### EnhancedNetworkClient

```dart
import 'package:gestion_magasin/services/network/enhanced_network_client.dart';

final client = EnhancedNetworkClient.instance;
await client.initialize();

// Tester
final alive = await client.testConnection('192.168.1.100', 8080);

// Connecter avec auth
await client.connect('192.168.1.100', 8080, 'user', 'pass');

// Requêtes
final data = await client.query('SELECT * FROM clt');
final changes = await client.execute('DELETE FROM clt WHERE id = ?', [1]);

await client.disconnect();
```

---

## 🔄 Gestion des Erreurs

```dart
try {
  final success = await db.initializeAsClient(ip, port, user, pass);
  
  if (!success) {
    // Fallback to local
    await db.initializeLocal();
  }
} catch (e) {
  print('Erreur: $e');
  await db.initializeLocal();
}
```

---

## 📱 Pattern Recommandé: Offline-First

```dart
class OrderService {
  final DatabaseService _db = DatabaseService();
  
  Future<void> addOrder(Order order) async {
    if (_db.mode == DatabaseMode.clientMode) {
      // En mode client, ajouter à la queue
      await _db.addClientWithSync(order);
      
      // Sync automatique quand possible
      try {
        await _db.syncWithServer();
      } catch (e) {
        // Ça va être resynchronisé plus tard
        debugPrint('Sync différée: $e');
      }
    } else {
      // Mode local: direct en base
      await _db.database.insertOrder(order);
    }
  }
  
  Future<List<Order>> getOrders() async {
    if (_db.mode == DatabaseMode.clientMode) {
      // Avec cache + fallback
      return await _db.getAllOrdersWithCache();
    } else {
      // Direct en base locale
      return await _db.database.getAllOrders();
    }
  }
}
```

---

## 🚨 Points Importants

1. **Idempotent**: Appeler `initialize()` plusieurs fois est safe
2. **Offline**: Les modifications en offline seront synchronisées automatiquement
3. **Fallback**: Si serveur indisponible, cache local est utilisé
4. **Token**: Auto-refresh 5 min avant expiration
5. **Reset**: Appeler `reset()` si besoin de changer de mode

---

## 📚 Documentation Complète

- Voir `.internal-docs/ARCHITECTURE_V2_COMPLETE.md` pour détails complets
- Voir `.internal-docs/ARCHITECTURE_V2_MIGRATION.md` pour guide migration
- Voir `.internal-docs/SOLUTIONS_APPLIQUEES.md` pour problèmes/solutions

---

## ✅ Checklist d'Intégration

- [ ] Tester `initializeLocal()` mode offline
- [ ] Configurer IP/port serveur
- [ ] Implémenter serveur HTTP
- [ ] Tester `initializeAsClient()`
- [ ] Tester offline → queue → sync
- [ ] Tester token refresh
- [ ] Tester fallback au cache
- [ ] Migrer NetworkManager
- [ ] Ajouter logs/monitoring
- [ ] Tests unitaires
- [ ] Deploy en production

---

## Prêt à démarrer ! 🚀
