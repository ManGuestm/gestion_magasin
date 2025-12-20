# Architecture Client/Serveur - Gestion Magasin

## 🏭 Architecture

### SERVEUR (Administrateur)
- Base de données SQLite locale
- Port 8080
- Broadcast des changements aux clients

### CLIENT (Vendeur, Caisse)
- ❌ **AUCUNE base de données locale**
- Toutes les requêtes passent par le serveur
- Synchronisation temps réel

## 🔐 Validation Brouillard → Journal

**Qui peut valider?**
- ✅ Administrateur
- ✅ Caisse
- ❌ Vendeur (saisie uniquement)

## 🚀 Configuration

### Serveur
```dart
await DatabaseService().initializeAsServer(port: 8080);
await NetworkServer.instance.start(port: 8080);
```

### Client
```dart
await DatabaseService().initializeAsClient(
  serverIp: '192.168.1.100',
  port: 8080,
  username: 'vendeur1',
  password: 'password',
);
```

## 💡 Utilisation

### Validation
```dart
final validationService = ValidationBrouillardService();

if (validationService.canValidateToJournal()) {
  await validationService.validateVenteToJournal(numVente);
}
```

### Synchronisation temps réel
```dart
RealtimeSyncWrapper(
  onDataChanged: () => _loadData(),
  child: YourScreen(),
)
```

## ⚠️ Important

- ❌ **Pas de base locale en mode CLIENT** - Aucune base SQLite créée
- 🔒 **Accès bloqué** - `database.getAllClients()` lève une erreur en mode CLIENT
- ✅ **Utiliser** - `getClientsWithModeAwareness()` à la place
- 📡 **Connexion obligatoire** - Ne fonctionne pas hors ligne

## 🔧 Fichiers créés/modifiés

1. **database_service.dart** - Bloque création base locale en mode CLIENT
2. **validation_brouillard_service.dart** - Contrôle validation par rôle
3. **realtime_sync_wrapper.dart** - Widget synchronisation temps réel
