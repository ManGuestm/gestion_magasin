# Architecture Serveur/Client - Gestion Magasin

## 🏗️ Vue d'ensemble

L'application utilise une architecture **Serveur/Client** avec synchronisation temps réel via WebSocket.

---

## 🖥️ ORDINATEUR SERVEUR

### Caractéristiques
- **Rôle**: Ordinateur principal
- **État**: Toujours allumé
- **Base de données**: Locale (SQLite)
- **Accès**: **Administrateur uniquement** 🔒

### Configuration
```dart
Mode: NetworkMode.server
Port: 8080 (par défaut)
Base de données: Locale (lib/database/database.dart)
```

### Restrictions d'accès
- ✅ **Administrateur**: Accès complet
- ❌ **Caisse**: Interdit
- ❌ **Vendeur**: Interdit

### Démarrage
```dart
// Dans network_server.dart
await NetworkServer.instance.start(port: 8080);

// Initialisation base de données
await DatabaseService().initializeLocal();
```

---

## 💻 ORDINATEUR CLIENT

### Caractéristiques
- **Rôle**: Poste de travail distant
- **Base de données**: **Aucune base locale** - Tout passe par le serveur
- **Connexion**: Réseau local (LAN)
- **Accès**: **Caisse et Vendeur uniquement** 🔒

### Configuration
```dart
Mode: NetworkMode.client
Serveur: 192.168.1.100:8080 (exemple)
Authentification: username + password
```

### Restrictions d'accès
- ❌ **Administrateur**: Interdit (doit utiliser le serveur)
- ✅ **Caisse**: Autorisé
- ✅ **Vendeur**: Autorisé

### Connexion
```dart
// Dans network_client.dart
await NetworkClient.instance.connect(
  serverIp: '192.168.1.100',
  port: 8080,
  username: 'vendeur1',
  password: 'password123',
);

// Initialisation en mode client (pas de base locale)
await DatabaseService().initializeAsClient(
  serverIp, port, username, password
);
```

---

## 🔄 Synchronisation Temps Réel

### Technologie
- **WebSocket**: Communication bidirectionnelle
- **Broadcast automatique**: Tous les clients reçoivent les changements
- **Pas de polling**: Efficace et performant

### Flux de données

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  CLIENT A   │         │   SERVEUR   │         │  CLIENT B   │
│  (Vendeur)  │         │   (Admin)   │         │  (Caisse)   │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │  1. Vente créée       │                       │
       ├──────────────────────>│                       │
       │                       │                       │
       │  2. Enregistrement    │                       │
       │     dans SQLite       │                       │
       │                       │                       │
       │                       │  3. Broadcast WebSocket
       │                       ├──────────────────────>│
       │                       │                       │
       │  4. Notification      │  5. Notification      │
       │<──────────────────────┤     reçue             │
       │                       │                       │
```

### Exemple d'utilisation

```dart
// Dans un écran client
class VentesModal extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return RealtimeSyncWrapper(
      onRefresh: _loadVentes,
      child: // ... votre UI
    );
  }
}
```

---

## 🔐 Contrôle d'accès

### Authentification Serveur (network_server.dart)

```dart
Future<Map<String, dynamic>> authenticateUser(Map<String, dynamic> data) async {
  final user = await _databaseService.database.getUserByCredentials(username, password);
  
  // Vérification du rôle
  if (user.role == 'Administrateur') {
    return {
      'success': false,
      'error': 'Accès refusé: Les Administrateurs doivent utiliser le mode Serveur uniquement',
    };
  }
  
  if (user.role != 'Caisse' && user.role != 'Vendeur') {
    return {
      'success': false,
      'error': 'Accès refusé: Seuls Caisse et Vendeur peuvent se connecter en mode client',
    };
  }
  
  // Authentification réussie
  return {'success': true, 'data': userData, 'token': token};
}
```

### Authentification Client (network_client.dart)

```dart
Future<bool> connect(String serverIp, int port, String username, String password) async {
  // Test connexion HTTP
  final request = await client.get(serverIp, port, '/api/health');
  
  // Authentification
  final authResult = await authenticate(username, password);
  if (authResult == null) {
    throw Exception('Authentification échouée');
  }
  
  // Connexion WebSocket
  _socket = await WebSocket.connect('ws://$serverIp:$port/ws');
  
  return true;
}
```

---

## 📊 Gestion des données

### Mode Serveur (LOCAL)
```dart
// Accès direct à la base SQLite
final articles = await database.getAllArticles();
await database.insertArticle(article);
```

### Mode Client (RÉSEAU)
```dart
// Toutes les requêtes passent par le serveur
final articles = await _networkClient.getAllArticles();
await _networkClient.execute('INSERT INTO articles ...');
```

### Wrappers avec détection automatique
```dart
// Dans database_service.dart
Future<List<Article>> getArticlesWithModeAwareness() async {
  if (_mode == DatabaseMode.clientMode) {
    // Mode client: requête réseau
    final result = await _networkClient.getAllArticles();
    return result.map((row) => Article.fromJson(row)).toList();
  }
  // Mode serveur: accès local
  return _database!.getAllArticles();
}
```

---

## 🚀 Configuration initiale

### 1. Premier démarrage
L'application détecte automatiquement le premier démarrage et affiche l'écran de configuration réseau.

### 2. Choix du mode

#### Mode Serveur
1. Sélectionner "Serveur"
2. Cliquer sur "Sauvegarder"
3. Redémarrer l'application
4. Se connecter avec un compte **Administrateur**

#### Mode Client
1. Sélectionner "Client"
2. Saisir l'adresse IP du serveur (ex: `192.168.1.100`)
3. Saisir le port (défaut: `8080`)
4. Tester la connexion
5. Cliquer sur "Sauvegarder"
6. Redémarrer l'application
7. Se connecter avec un compte **Caisse** ou **Vendeur**

### 3. Écran de configuration

```dart
// Accès via login_screen.dart
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NetworkConfigScreen()),
    );
  },
  child: Text('Configuration réseau'),
)
```

---

## 🛠️ Fichiers clés

### Serveur
- `lib/services/network_server.dart` - Serveur HTTP/WebSocket
- `lib/services/network/http_server.dart` - Serveur HTTP REST
- `lib/database/database_service.dart` - Gestion base de données

### Client
- `lib/services/network_client.dart` - Client réseau
- `lib/services/network/enhanced_network_client.dart` - Client amélioré
- `lib/services/realtime_sync_service.dart` - Synchronisation temps réel

### Configuration
- `lib/services/network_config_service.dart` - Service de configuration
- `lib/services/network_manager.dart` - Gestionnaire réseau
- `lib/screens/network_config_screen.dart` - Écran de configuration

### Widgets
- `lib/widgets/common/realtime_sync_wrapper.dart` - Wrapper synchronisation
- `lib/widgets/common/network_status_widget.dart` - Statut réseau

---

## 📝 Logs et débogage

### Serveur
```
✅ Serveur démarré sur port 8080
🔐 Authentification du CLIENT: vendeur1
✅ Authentification réussie pour CLIENT: vendeur1 (Vendeur)
✅ Client WebSocket authentifié connecté depuis 192.168.1.101
```

### Client
```
🌐 Tentative de connexion CLIENT à http://192.168.1.100:8080
✅ Test HTTP réussi
🔐 Authentification CLIENT avec utilisateur: vendeur1
✅ Authentification réussie - Token et Session obtenu
✅ CLIENT connecté et authentifié au serveur
📥 Changement reçu du serveur: insert
```

---

## ⚠️ Points importants

1. **Pas de base locale en mode client**: Toutes les données transitent par le serveur
2. **Administrateur = Serveur uniquement**: Les admins ne peuvent pas se connecter en mode client
3. **Caisse/Vendeur = Client uniquement**: Ces rôles doivent utiliser le mode client
4. **Synchronisation automatique**: Les changements sont propagés instantanément via WebSocket
5. **Sécurité**: Authentification par token, validation des rôles, audit complet

---

## 🔧 Dépannage

### Problème: "Impossible de se connecter au serveur"
- Vérifier que le serveur est démarré
- Vérifier l'adresse IP et le port
- Vérifier le pare-feu Windows
- Utiliser le bouton "Tester" dans la configuration

### Problème: "Accès refusé"
- Vérifier le rôle de l'utilisateur
- Administrateur → Mode Serveur
- Caisse/Vendeur → Mode Client

### Problème: "Base de données non initialisée"
- Redémarrer l'application
- Vérifier la configuration réseau
- Consulter les logs de démarrage

---

## 📚 Ressources

- **Guide synchronisation**: `REALTIME_SYNC_GUIDE.md`
- **README principal**: `README.md`
- **Documentation API**: Voir commentaires dans les fichiers sources

---

**Version**: 2.0  
**Dernière mise à jour**: 2024
