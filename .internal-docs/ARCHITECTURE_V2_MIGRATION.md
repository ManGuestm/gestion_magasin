# Architecture Serveur/Client - Guide de Migration

## ✅ Modules Implémentés

### 1. **CacheManager** (`lib/services/sync/cache_manager.dart`)

- ✅ Versioning des données en cache
- ✅ Invalidation avec TTL
- ✅ Persista en SharedPreferences
- ✅ Méthodes: `setCache()`, `getCache()`, `invalidateCache()`, `invalidateAllCache()`

### 2. **SyncQueueService** (`lib/services/sync/sync_queue_service.dart`)

- ✅ Queue de synchronisation offline-first
- ✅ Stockage persistent en SharedPreferences
- ✅ Support des opérations: INSERT, UPDATE, DELETE
- ✅ Retry logic avec limite configurable
- ✅ Méthodes: `addOperation()`, `getPendingOperations()`, `markAsSynced()`, `removeOperation()`

### 3. **AuthTokenService** (`lib/services/auth/auth_token_service.dart`)

- ✅ Gestion des tokens JWT
- ✅ Authentification HTTP
- ✅ Auto-refresh des tokens expirés
- ✅ Sauvegarde secure en SharedPreferences
- ✅ Méthodes: `authenticate()`, `refreshToken()`, `logout()`

### 4. **EnhancedNetworkClient** (`lib/services/network/enhanced_network_client.dart`)

- ✅ Client réseau avec auth headers
- ✅ Test de connexion `testConnection()`
- ✅ Requêtes authentifiées `query()` et `execute()`
- ✅ Gestion auto des tokens expirés
- ✅ Disconnection propre

### 5. **DatabaseService V2** (`lib/database/database_service.dart`)

- ✅ Trois modes mutuellement exclusifs:
  - `DatabaseMode.local` - Base SQLite locale
  - `DatabaseMode.serverMode` - Serveur réseau
  - `DatabaseMode.clientMode` - Client réseau avec cache/sync
  
#### Nouvelles Méthodes

- `initializeLocal()` - Initialisation locale uniquement
- `initializeAsServer(port)` - Mode serveur
- `initializeAsClient(ip, port, user, pass)` - Mode client avec auth
- `syncWithServer()` - Synchronisation avec le serveur
- `getAllClientsWithCache()` - Récupération avec cache + fallback
- `addClientWithSync()` - Ajout avec queue offline

---

## 📋 Plan de Finalisation

### Phase 1: ❌ BACKCOMPAT - Maintenir les anciens appels (NÉCESSAIRE)

Les callers existants utilisent:

- `DatabaseService().setNetworkMode(true/false)` → DÉPRECIÉ
- `DatabaseService().initialize()` → MARQUER COMME DÉPRECIÉ
- Vérifier tous les fichiers qui appellent ces méthodes

**Fichiers à mettre à jour:**

1. `lib/services/network_manager.dart` - Passer à `initializeAsClient()`
2. `lib/services/network_config_service.dart` - Adapter la configuration
3. `lib/services/vente_service.dart` - Vérifier les références
4. Tous les services qui utilisent `DatabaseService()`

### Phase 2: ❌ REMPLACER les anciennes méthodes du initialize()

- [ ] Commenter/désactiver le bloc try/catch du vieux `initialize()`
- [ ] Ajouter @deprecated sur `setNetworkMode()`
- [ ] Ajouter migration guide

### Phase 3: ✅ TESTER les nouveaux modes

- [ ] Test mode LOCAL
- [ ] Test mode CLIENT avec sync
- [ ] Test failover (perte de connexion + queue)
- [ ] Test retry après reconnexion

### Phase 4: ✅ AJOUTER imports manquants

- [ ] Ajouter `SyncOperationType` import
- [ ] Vérifier `CltData` et `CltCompanion` disponibles

---

## 🔧 Actions Immédiates Requises

### ❌ BLOCKER: References à `_networkDb` partout

Le fichier DatabaseService a du code legacy qui référence:

- `_networkDb` (supprimé dans V2)
- `_isNetworkMode` (remplacé par `_mode`)
- `NetworkClient` (remplacé par `EnhancedNetworkClient`)

**Solution:** Garder le legacy pour backcompat temporaire, puis migrer les callers

### ✅ DONE: Nouvelle architecture en place

- CacheManager → versioning + invalidation
- SyncQueueService → offline-first queue
- AuthTokenService → JWT tokens
- EnhancedNetworkClient → authenticated HTTP client
- DatabaseService modes distincts

---

## 🎯 Utilisation Recommandée

### Mode LOCAL (Desktop sans réseau)

```dart
final db = DatabaseService();
await db.initializeLocal();
```

### Mode CLIENT (Desktop connect au serveur)

```dart
final db = DatabaseService();
final success = await db.initializeAsClient(
  '192.168.1.100',
  8080,
  'username',
  'password',
);

if (success) {
  // Lire avec cache
  final clients = await db.getAllClientsWithCache();
  
  // Écrire avec queue si offline
  await db.addClientWithSync(newClient);
  
  // Synchroniser quand connecté
  await db.syncWithServer();
}
```

### Mode SERVER (Backend - à implémenter)

```dart
final db = DatabaseService();
await db.initializeAsServer(port: 8080);
// Démarrer serveur HTTP...
```

---

## 📦 Dépendances Ajoutées

- `jwt_decoder: ^2.0.1` - Pour decoder les JWT tokens

---

## ⚠️ Notes Importantes

1. **Token Expiry**: Les tokens JWT sontauto-refreshés si expiration < 5 min
2. **Cache Versioning**: Le numéro de version doit correspondre côté client/serveur
3. **Offline-First**: Les opérations en offline sont persistées et envoyées lors de la reconnexion
4. **Fallback**: En mode CLIENT, les données locales peuvent être utilisées en fallback
5. **Cleanup**: Appeler `reset()` ou `close()` pour nettoyer les ressources

---

## 🚀 Prochaines Étapes

1. Implémenter le serveur correspondant (Node.js/Dart/Python)
2. Migrer tous les callers vers les nouveaux modes
3. Ajouter tests unitaires pour les scenarios offline
4. Documenter les endpoints serveur requis
5. Configurer CORS si nécessaire pour le frontend web
