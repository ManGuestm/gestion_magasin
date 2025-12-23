# Guide de Migration - Architecture Serveur/Client

## 🎯 Résumé des changements

### Avant (Architecture mixte)
- Base locale sur tous les ordinateurs
- Synchronisation optionnelle
- Tous les rôles pouvaient se connecter partout

### Après (Architecture stricte)
- **Serveur**: Base locale, Administrateur uniquement
- **Client**: Pas de base locale, Caisse/Vendeur uniquement
- Synchronisation temps réel obligatoire

---

## 🔄 Modifications apportées

### 1. Restriction d'accès Serveur (network_server.dart)

```dart
// AVANT: Tous les rôles pouvaient se connecter
if (user.role != 'Caisse' && user.role != 'Vendeur') {
  return {'success': false, 'error': 'Rôle non autorisé'};
}

// APRÈS: Administrateur interdit en mode client
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
```

### 2. Messages clarifiés (database_service.dart)

```dart
// Mode LOCAL (Serveur)
debugPrint('✅ Base de données initialisée en mode LOCAL (SERVEUR)');

// Mode CLIENT
debugPrint('✅ CLIENT: Connecté à $serverIp:$port');
debugPrint('📌 Aucune base locale - Tout passe par le serveur');
debugPrint('🔒 Accès: Caisse et Vendeur uniquement');
```

### 3. Interface de configuration (network_config_screen.dart)

Ajout d'indicateurs visuels:
```dart
// Mode Serveur
Text(
  '🔒 Accès: Administrateur uniquement',
  style: TextStyle(
    fontSize: 11,
    color: Colors.orange,
    fontWeight: FontWeight.bold,
  ),
)

// Mode Client
Text(
  '🔒 Accès: Caisse et Vendeur uniquement',
  style: TextStyle(
    fontSize: 11,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 📋 Checklist de migration

### Pour les développeurs

- [x] Modifier `network_server.dart` - Restriction Administrateur
- [x] Modifier `database_service.dart` - Messages clarifiés
- [x] Modifier `network_config_screen.dart` - Indicateurs visuels
- [x] Créer `ARCHITECTURE_SERVEUR_CLIENT.md` - Documentation
- [x] Créer `MIGRATION_GUIDE.md` - Ce guide

### Pour les utilisateurs

- [ ] Identifier l'ordinateur qui sera le serveur
- [ ] Configurer le serveur en mode "Serveur"
- [ ] Créer un compte Administrateur sur le serveur
- [ ] Noter l'adresse IP du serveur
- [ ] Configurer les clients en mode "Client"
- [ ] Créer des comptes Caisse/Vendeur pour les clients
- [ ] Tester la connexion et la synchronisation

---

## 🚀 Déploiement

### Étape 1: Serveur

1. **Installation**
   ```bash
   # Sur l'ordinateur serveur
   flutter run -d windows
   ```

2. **Configuration**
   - Lancer l'application
   - Aller dans "Configuration réseau"
   - Sélectionner "Serveur"
   - Sauvegarder et redémarrer

3. **Connexion**
   - Se connecter avec un compte **Administrateur**
   - Vérifier que le serveur est démarré (port 8080)

4. **Vérification**
   - Ouvrir un navigateur
   - Aller sur `http://localhost:8080/api/health`
   - Devrait afficher: `{"status":"ok","timestamp":"..."}`

### Étape 2: Clients

1. **Installation**
   ```bash
   # Sur chaque ordinateur client
   flutter run -d windows
   ```

2. **Configuration**
   - Lancer l'application
   - Aller dans "Configuration réseau"
   - Sélectionner "Client"
   - Saisir l'IP du serveur (ex: `192.168.1.100`)
   - Saisir le port: `8080`
   - Tester la connexion
   - Sauvegarder et redémarrer

3. **Connexion**
   - Se connecter avec un compte **Caisse** ou **Vendeur**
   - Vérifier la connexion au serveur

4. **Vérification**
   - Créer une vente sur le client
   - Vérifier qu'elle apparaît sur le serveur
   - Vérifier la synchronisation temps réel

---

## 🧪 Tests

### Test 1: Restriction Administrateur

```
✅ Serveur: Administrateur peut se connecter
❌ Client: Administrateur ne peut PAS se connecter
   → Message: "Accès refusé: Les Administrateurs doivent utiliser le mode Serveur uniquement"
```

### Test 2: Restriction Caisse/Vendeur

```
❌ Serveur: Caisse/Vendeur ne peuvent PAS se connecter (optionnel selon besoin)
✅ Client: Caisse/Vendeur peuvent se connecter
```

### Test 3: Synchronisation temps réel

```
1. Client A: Créer une vente
2. Serveur: Vérifier que la vente apparaît immédiatement
3. Client B: Vérifier que la vente apparaît immédiatement
```

### Test 4: Pas de base locale (Client)

```
1. Client: Se connecter
2. Serveur: Arrêter le serveur
3. Client: Essayer de créer une vente
   → Devrait échouer avec message d'erreur réseau
4. Serveur: Redémarrer le serveur
5. Client: Devrait se reconnecter automatiquement
```

---

## 🐛 Résolution de problèmes

### Problème: Administrateur ne peut pas se connecter en mode client

**Cause**: Restriction intentionnelle  
**Solution**: Utiliser le mode Serveur pour les Administrateurs

```dart
// Dans network_server.dart (ligne ~240)
if (user.role == 'Administrateur') {
  return {
    'success': false,
    'error': 'Accès refusé: Les Administrateurs doivent utiliser le mode Serveur uniquement',
  };
}
```

### Problème: Client ne peut pas se connecter

**Causes possibles**:
1. Serveur non démarré
2. Adresse IP incorrecte
3. Port incorrect
4. Pare-feu bloque la connexion
5. Rôle utilisateur incorrect

**Solutions**:
```bash
# 1. Vérifier le serveur
# Sur le serveur, ouvrir http://localhost:8080/api/health

# 2. Vérifier l'IP
ipconfig  # Windows
# Noter l'adresse IPv4

# 3. Vérifier le pare-feu
# Windows Defender Firewall → Autoriser une application
# Ajouter gestion_magasin.exe

# 4. Vérifier le rôle
# Seuls Caisse et Vendeur peuvent se connecter en mode client
```

### Problème: Synchronisation ne fonctionne pas

**Vérifications**:
```dart
// 1. Vérifier que le widget utilise RealtimeSyncWrapper
return RealtimeSyncWrapper(
  onRefresh: _loadData,
  child: // ... votre UI
);

// 2. Vérifier les logs serveur
// Devrait afficher: "✅ Client WebSocket authentifié connecté"

// 3. Vérifier les logs client
// Devrait afficher: "📥 Changement reçu du serveur: insert"
```

---

## 📊 Comparaison des modes

| Fonctionnalité | Mode Serveur | Mode Client |
|----------------|--------------|-------------|
| Base de données locale | ✅ Oui | ❌ Non |
| Accès Administrateur | ✅ Oui | ❌ Non |
| Accès Caisse/Vendeur | ❌ Non* | ✅ Oui |
| Synchronisation temps réel | ✅ Oui (broadcast) | ✅ Oui (receive) |
| Doit être toujours allumé | ✅ Oui | ❌ Non |
| Connexion réseau requise | ❌ Non | ✅ Oui |

*Optionnel: Vous pouvez autoriser Caisse/Vendeur sur le serveur si nécessaire

---

## 🔐 Sécurité

### Authentification renforcée

```dart
// 1. Validation du rôle côté serveur
if (user.role == 'Administrateur') {
  // Interdit en mode client
}

// 2. Token d'authentification
final token = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${username.hashCode}';

// 3. Validation WebSocket
final authHeader = request.headers.value('Authorization');
if (authHeader == null || !authHeader.startsWith('Bearer ')) {
  // Connexion refusée
}

// 4. Audit des tentatives
await _auditService.log(
  userId: user.id,
  userName: user.nom,
  action: AuditAction.error,
  module: 'Authentification',
  details: 'Tentative de connexion CLIENT avec rôle Administrateur (interdit)',
);
```

---

## 📚 Ressources supplémentaires

- **Architecture complète**: `ARCHITECTURE_SERVEUR_CLIENT.md`
- **Guide synchronisation**: `REALTIME_SYNC_GUIDE.md`
- **README principal**: `README.md`

---

## ✅ Validation finale

Avant de déployer en production:

- [ ] Tous les tests passent
- [ ] Administrateur ne peut pas se connecter en mode client
- [ ] Caisse/Vendeur peuvent se connecter en mode client
- [ ] Synchronisation temps réel fonctionne
- [ ] Pas de base locale sur les clients
- [ ] Documentation à jour
- [ ] Formation des utilisateurs effectuée

---

**Version**: 2.0  
**Date**: 2024  
**Auteur**: Équipe de développement
