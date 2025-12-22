# Architecture Serveur/Client - Gestion de Magasin

## 📋 Vue d'ensemble

L'application fonctionne en deux modes distincts avec des restrictions d'accès strictes par rôle.

## 🖥️ Mode SERVEUR

### Caractéristiques
- **Ordinateur principal** : Toujours allumé
- **Base de données** : Locale (SQLite)
- **Rôle** : Héberge la base et accepte les connexions clients
- **Port par défaut** : 8080

### 🔒 Accès
- ✅ **Administrateur uniquement**
- ❌ Caisse : Accès refusé
- ❌ Vendeur : Accès refusé

### Fonctionnalités
- Gestion complète de tous les modules
- Configuration des utilisateurs
- Sauvegarde et restauration
- Audit complet des actions
- Accepte les connexions des clients

## 💻 Mode CLIENT

### Caractéristiques
- **Connexion réseau** : Se connecte au serveur
- **Base de données** : Aucune (tout passe par le serveur)
- **Cache** : En mémoire uniquement (volatile)
- **Synchronisation** : Temps réel via WebSocket

### 🔒 Accès
- ❌ Administrateur : Accès refusé
- ✅ **Caisse** : Accès autorisé
- ✅ **Vendeur** : Accès autorisé

### Fonctionnalités
- Ventes et encaissements
- Consultation articles/clients
- Consultation stocks
- Synchronisation automatique des changements

## 🔐 Sécurité

### Authentification
1. **Cryptage bcrypt** : Tous les mots de passe
2. **Validation côté serveur** : Vérification des rôles
3. **Tokens de session** : Pour les connexions WebSocket
4. **Audit trail** : Toutes les tentatives de connexion

### Validation des rôles

#### Côté Client (auth_service.dart)
```dart
bool _validateRoleForMode(String role, bool isNetworkMode) {
  if (isNetworkMode) {
    // Mode CLIENT: Caisse et Vendeur uniquement
    return role == 'Caisse' || role == 'Vendeur';
  } else {
    // Mode SERVEUR: Administrateur uniquement
    return role == 'Administrateur';
  }
}
```

#### Côté Serveur (network_server.dart)
```dart
// Vérifier que seuls Caisse et Vendeur peuvent se connecter en mode CLIENT
if (user.role != 'Caisse' && user.role != 'Vendeur') {
  return {'success': false, 'error': 'Accès refusé: Seuls les utilisateurs Caisse et Vendeur peuvent se connecter en mode client'};
}
```

## 🔄 Synchronisation Temps Réel

### WebSocket
- **Connexion persistante** : Entre serveur et clients
- **Broadcast automatique** : Tous les clients reçoivent les changements
- **Reconnexion automatique** : Jusqu'à 5 tentatives avec délai de 3s
- **Pas de polling** : Efficace et performant

### Types de changements synchronisés
- ✅ Ventes et achats
- ✅ Clients et fournisseurs
- ✅ Articles et stocks
- ✅ Mouvements de stock
- ✅ Opérations de caisse

### Exemple de flux
```
1. Client A fait une vente
2. Serveur reçoit et enregistre
3. Serveur broadcast le changement via WebSocket
4. Client B reçoit la notification
5. Client B rafraîchit automatiquement l'écran
```

## 📡 API REST

### Endpoints

#### `/api/health`
- **Méthode** : GET
- **Usage** : Test de connexion
- **Réponse** : `{"status": "ok", "timestamp": "..."}`

#### `/api/auth`
- **Méthode** : POST
- **Body** : `{"username": "...", "password": "..."}`
- **Validation** : Rôle selon mode
- **Réponse** : `{"success": true, "data": {...}}`

#### `/api/query`
- **Méthode** : POST
- **Headers** : `Authorization: Bearer <token>`
- **Body** : `{"type": "select|insert|update|delete", "query": "...", "params": [...]}`
- **Réponse** : `{"success": true, "data": [...]}`

#### `/ws`
- **Protocole** : WebSocket
- **Headers** : `Authorization: Bearer <token>`
- **Usage** : Synchronisation temps réel

## 🚀 Configuration

### Mode Serveur
1. Ouvrir l'application
2. Aller dans **Paramètres > Configuration réseau**
3. Sélectionner **Serveur**
4. Sauvegarder
5. Se connecter avec un compte **Administrateur**

### Mode Client
1. Ouvrir l'application
2. Aller dans **Paramètres > Configuration réseau**
3. Sélectionner **Client**
4. Saisir :
   - Adresse IP du serveur (ex: 192.168.1.100)
   - Port (défaut: 8080)
   - Nom d'utilisateur (Caisse ou Vendeur)
   - Mot de passe
5. Tester la connexion
6. Sauvegarder
7. Redémarrer l'application

## 🔧 Dépannage

### Client ne peut pas se connecter
1. Vérifier que le serveur est démarré
2. Vérifier l'adresse IP et le port
3. Vérifier le pare-feu Windows
4. Utiliser le bouton **Diagnostic** dans la configuration réseau

### Administrateur ne peut pas se connecter en mode Client
- **Normal** : Les administrateurs ne peuvent se connecter qu'en mode Serveur
- **Solution** : Utiliser un compte Caisse ou Vendeur

### Caisse/Vendeur ne peut pas se connecter en mode Serveur
- **Normal** : Caisse et Vendeur ne peuvent se connecter qu'en mode Client
- **Solution** : Utiliser un compte Administrateur ou passer en mode Client

### Synchronisation ne fonctionne pas
1. Vérifier la connexion WebSocket
2. Vérifier les logs dans la console
3. Redémarrer le client
4. Reconnexion automatique après 3 secondes

## 📊 Monitoring

### Clients connectés
- Aller dans **Paramètres > Clients connectés**
- Voir la liste en temps réel
- Informations : IP, utilisateur, heure de connexion

### Logs d'audit
- Toutes les connexions sont enregistrées
- Tentatives échouées tracées
- Accès refusés documentés

## 🎯 Bonnes pratiques

### Serveur
- ✅ Toujours allumé pendant les heures d'ouverture
- ✅ Sauvegardes régulières
- ✅ Un seul administrateur actif
- ✅ Surveiller les clients connectés

### Client
- ✅ Vérifier la connexion au démarrage
- ✅ Ne pas fermer brutalement
- ✅ Signaler les déconnexions
- ✅ Utiliser des comptes dédiés (Caisse/Vendeur)

## 🔒 Sécurité réseau

### Recommandations
- 🔐 Utiliser un réseau local privé (LAN)
- 🔐 Configurer le pare-feu Windows
- 🔐 Mots de passe forts pour tous les utilisateurs
- 🔐 Changer les mots de passe par défaut
- 🔐 Désactiver les comptes inutilisés

### Ports
- **8080** : HTTP REST API
- **8080** : WebSocket (même port, upgrade HTTP)

## 📝 Notes techniques

### Cache client
- En mémoire uniquement (RAM)
- Invalidé automatiquement lors des changements
- Perdu au redémarrage (normal)

### Transactions
- Gérées côté serveur
- Atomiques et cohérentes
- Rollback automatique en cas d'erreur

### Performance
- Pagination des résultats
- Cache intelligent
- Compression WebSocket
- Requêtes optimisées
