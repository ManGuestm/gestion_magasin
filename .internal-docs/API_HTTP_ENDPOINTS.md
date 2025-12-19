# 📡 API HTTP Serveur - Documentation Complète

## Vue d'ensemble

Le serveur HTTP expose 5 endpoints REST pour communiquer avec les clients distants en mode client/serveur.

**Base URL**: `http://<server-ip>:8080`

---

## 🔐 Authentification

Tous les endpoints (sauf `/api/health` et `/api/authenticate`) requièrent un header `Authorization` :

```Authorization: Bearer <token>
```

### Flux d'authentification

1. **Client** → `POST /api/authenticate` avec credentials
2. **Serveur** → Retourne un token JWT valide 1h
3. **Client** → Utilise ce token pour les requêtes suivantes
4. **Token expiré ?** → `POST /api/refresh-token` pour en obtenir un nouveau

---

## 📌 Endpoints

### 1. GET `/api/health` - Test de connexion

Vérifier que le serveur est actif et accessible.

**Requête**:

```http
GET /api/health HTTP/1.1
Host: localhost:8080
```

**Réponse (200 OK)**:

```json
{
  "status": "ok",
  "timestamp": "2025-12-19T15:30:45.123Z",
  "version": "2.0",
  "activeSessions": 2
}
```

**Cas d'erreur**:

- Aucune erreur possible pour ce endpoint

---

### 2. POST `/api/authenticate` - Authentification

Obtenir un token d'authentification pour accéder aux autres endpoints.

**Requête**:

```http
POST /api/authenticate HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**Réponse (200 OK)**:

```json
{
  "success": true,
  "data": {
    "token": "dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM=",
    "expiresAt": "2025-12-19T16:30:45.123Z",
    "userId": "user_-1234567890",
    "username": "admin"
  }
}
```

**Cas d'erreur**:

- **400 - Bad Request**:

```json
{
  "success": false,
  "error": "Missing username or password",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **401 - Unauthorized** (credentials invalides):

```json
{
  "success": false,
  "error": "Invalid credentials",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **503 - Service Unavailable** (serveur plein - max 100 sessions):

```json
{
  "success": false,
  "error": "Server at capacity",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

**Credentials de démo**:

| Username       | Password   | Role           |
|----------------|------------|----------------|
| `admin`        | `admin123` | Administrateur |
| `user`         | `user123`  | Utilisateur    |
| `gestionnaire` | `pass123`  | Gestionnaire   |

---

### 3. POST `/api/refresh-token` - Rafraîchir le token

Obtenir un nouveau token avant expiration (1h).

**Requête**:

```http
POST /api/refresh-token HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM=

{}
```

**Réponse (200 OK)**:

```json
{
  "success": true,
  "data": {
    "token": "dG9rZW5fMTczNDYxMDQ1MDEyM18yMzQ=",
    "expiresAt": "2025-12-19T17:30:45.123Z"
  }
}
```

**Cas d'erreur**:

- **401 - Unauthorized** (token manquant/invalide/expiré):

```json
{
  "success": false,
  "error": "Unauthorized",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

---

### 4. POST `/api/query` - Exécuter une requête SELECT

Récupérer des données depuis la base serveur (lecture seule).

**Requête**:

```http
POST /api/query HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM=

{
  "sql": "SELECT * FROM clt WHERE rsoc = ?",
  "params": ["Client001"]
}
```

**Réponse (200 OK)**:

```json
{
  "success": true,
  "data": [
    {
      "rsoc": "Client001",
      "adr": "123 Rue de la Paix",
      "capital": 50000.0,
      "tel": "+212-5-XX-XX-XX",
      "email": "contact@client001.com"
    }
  ],
  "rowCount": 1
}
```

**Cas d'erreur**:

- **400 - Bad Request** (SQL vide):

```json
{
  "success": false,
  "error": "Missing or empty SQL",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **403 - Forbidden** (requête non-SELECT):

```json
{
  "success": false,
  "error": "Only SELECT queries are allowed",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **400 - Bad Request** (erreur SQL):

```json
{
  "success": false,
  "error": "SQL error: no such table: clt",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **401 - Unauthorized** (token invalide):

```json
{
  "success": false,
  "error": "Unauthorized",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

---

### 5. POST `/api/execute` - Exécuter INSERT/UPDATE/DELETE

Effectuer des modifications dans la base serveur.

**Requête**:

```http
POST /api/execute HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM=

{
  "sql": "INSERT INTO clt (rsoc, adr, tel) VALUES (?, ?, ?)",
  "params": ["NewClient", "456 Avenue", "+212-5-YY-YY-YY"]
}
```

**Réponse (200 OK)**:

```json
{
  "success": true,
  "message": "Query executed successfully"
}
```

**Cas d'erreur**:

- **400 - Bad Request** (SQL vide):

```json
{
  "success": false,
  "error": "Missing or empty SQL",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **403 - Forbidden** (requête SELECT):

```json
{
  "success": false,
  "error": "Only INSERT/UPDATE/DELETE queries are allowed",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **400 - Bad Request** (erreur SQL):

```json
{
  "success": false,
  "error": "SQL error: UNIQUE constraint failed: clt.rsoc",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

- **401 - Unauthorized** (token invalide):

```json
{
  "success": false,
  "error": "Unauthorized",
  "timestamp": "2025-12-19T15:30:45.123Z"
}
```

---

## 🧪 Exemples d'utilisation

### Via `curl`

**1. Test health**:

```bash
curl -X GET http://localhost:8080/api/health
```

**2. Authentification**:

```bash
curl -X POST http://localhost:8080/api/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**3. Query avec token**:

```bash
TOKEN="dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM="

curl -X POST http://localhost:8080/api/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "sql": "SELECT * FROM clt LIMIT 5",
    "params": []
  }'
```

**4. Execute (INSERT)**:

```bash
TOKEN="dG9rZW5fMTczNDYxMDQ1MDEyM18xMjM="

curl -X POST http://localhost:8080/api/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "sql": "UPDATE clt SET soldes = ? WHERE rsoc = ?",
    "params": [1500.0, "Client001"]
  }'
```

### Via Dart (EnhancedNetworkClient)

```dart
// Authentification
final token = await authTokenService.authenticate(
  'http://localhost:8080',
  'admin',
  'admin123',
);

// Query
final result = await enhancedNetworkClient.query(
  'SELECT * FROM clt WHERE soldes > ?',
  [1000.0],
);

// Execute
await enhancedNetworkClient.execute(
  'UPDATE clt SET soldes = ? WHERE rsoc = ?',
  [2000.0, 'Client001'],
);
```

---

## 🔒 Sécurité

### Validation des tokens

- Tokens valides **1 heure**
- Sessions limitées à **100 concurrent**
- Tokens automatiquement nettoyés après expiration
- Pas de stockage du mot de passe en clair (demo only)

### Sécurité SQL

- `SELECT` uniquement autorisé pour `/api/query`
- `INSERT/UPDATE/DELETE` uniquement pour `/api/execute`
- Paramètres bindés pour prévenir SQL injection

### Headers CORS

```Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## 📊 Codes de statut HTTP

| Code | Signification | Cas d'usage |
| **200** | OK | Requête réussie |
| **400** | Bad Request | Requête malformée/SQL invalide |
| **401** | Unauthorized | Token manquant/invalide/expiré |
| **403** | Forbidden | Opération non autorisée (SELECT on `/api/execute`) |
| **404** | Not Found | Endpoint inexistant |
| **405** | Method Not Allowed | Mauvaise méthode HTTP |
| **500** | Internal Server Error | Erreur serveur |
| **503** | Service Unavailable | Serveur à pleine capacité |

---

## 🔄 Flux Offline-First Recommandé

```text
┌─────────────────────────────────────────┐
│  Client Dart (mode CLIENT)              │
├─────────────────────────────────────────┤
│                                         │
│  1. getAllClientsWithCache()            │
│     ├─ Serveur disponible ? OUI        │
│     │  → Fetch via /api/query          │
│     │  → Store in CacheManager         │
│     └─ NON                              │
│        → Use CacheManager.getCache()   │
│        → Fallback local DB             │
│                                         │
│  2. addClientWithSync(client)           │
│     ├─ Serveur disponible ? OUI        │
│     │  → Execute via /api/execute      │
│     │  → Remove from SyncQueue         │
│     └─ NON                              │
│        → Add to SyncQueueService       │
│        → Store in SharedPreferences    │
│                                         │
│  3. syncWithServer()                    │
│     → Process all pending items        │
│     → Retry failed items (max 3x)      │
│     → Clear CacheManager               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📝 Notes importantes

1. **Authentication**: Nouveau token obtenu via `/api/authenticate` à chaque session
2. **Token Refresh**: Appeler `/api/refresh-token` 5 min avant expiration
3. **Offline Mode**: Si serveur indisponible, la queue persiste et synchronise une fois connecté
4. **Database**: Actuellement en démo (SQLite local), en prod: base réseau complète
5. **Credentials**: À remplacer par système d'authentification réel (LDAP, OAuth, etc.)

---

**Version**: 2.0
**Dernière mise à jour**: 19 décembre 2025
