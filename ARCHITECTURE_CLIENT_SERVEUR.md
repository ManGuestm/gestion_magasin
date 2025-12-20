# Guide Architecture Client/Serveur

## 🏗️ Architecture

### Serveur (Administrateur)
- **Rôle**: Héberge la base de données SQLite
- **Port**: 8080 (configurable)
- **Accès**: Administrateur uniquement
- **Base de données**: Locale sur le serveur

### Client (Vendeur, Caisse)
- **Rôle**: Se connecte au serveur distant
- **Base de données**: Aucune base locale, tout passe par le serveur
- **Synchronisation**: Temps réel via HTTP REST

## 🔐 Contrôle d'accès

### Validation Brouillard → Journal

**Qui peut valider?**
- ✅ Administrateur
- ✅ Caisse
- ❌ Vendeur (saisie uniquement)

**Workflow:**
1. Vendeur crée une vente → Statut: BROUILLARD
2. Caisse/Admin valide → Statut: JOURNAL

## 📡 Synchronisation

### Mode Client
- Toutes les lectures passent par le serveur
- Toutes les écritures sont envoyées au serveur
- Pas de fallback local
- Synchronisation instantanée

### Mode Serveur
- Base de données locale
- Broadcast des changements aux clients
- Gestion des sessions

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

### Validation Brouillard → Journal
```dart
final validationService = ValidationBrouillardService();

// Vérifier les permissions
if (validationService.canValidateToJournal()) {
  await validationService.validateVenteToJournal(numVente);
}
```

### Synchronisation temps réel
```dart
// Envelopper l'écran avec RealtimeSyncWrapper
RealtimeSyncWrapper(
  onDataChanged: () {
    // Rafraîchir les données
    _loadData();
  },
  child: YourScreen(),
)
```

## 🔧 Services modifiés

1. **database_service.dart**
   - Suppression des fallbacks locaux en mode CLIENT
   - Force l'utilisation du serveur distant

2. **validation_brouillard_service.dart** (NOUVEAU)
   - Contrôle d'accès par rôle
   - Validation Brouillard → Journal

3. **realtime_sync_wrapper.dart** (NOUVEAU)
   - Widget pour synchronisation temps réel
   - Rafraîchissement automatique

## ⚠️ Important

- **Pas de base locale en mode Client**: Toutes les données viennent du serveur
- **Connexion requise**: Le client ne peut pas fonctionner hors ligne
- **Rôles stricts**: Vendeur ne peut pas valider en Journal
- **Synchronisation instantanée**: Les changements sont propagés immédiatement

## 🐛 Dépannage

### Client ne se connecte pas
- Vérifier l'IP du serveur
- Vérifier que le port 8080 est ouvert
- Vérifier les credentials

### Données non synchronisées
- Vérifier que le serveur est en mode SERVER
- Vérifier que le client est en mode CLIENT
- Vérifier les logs de synchronisation

### Vendeur peut valider
- Vérifier le rôle dans la base de données
- Utiliser ValidationBrouillardService pour les validations
