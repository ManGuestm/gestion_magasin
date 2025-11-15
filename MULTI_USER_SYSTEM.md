# Système Multi-Utilisateur - Gestion de Magasin

## Fonctionnalités Implémentées

### 1. Table Users
- **Structure** : id, nom, email, mot_de_passe, role, actif, date_creation
- **Rôles disponibles** : Administrateur, Caisse, Vendeur
- **Contraintes** : Email unique, utilisateur actif/inactif

### 2. Service d'Authentification (AuthService)
- **Singleton** pour gérer l'état de connexion
- **Méthodes** :
  - `login(email, password)` : Authentification
  - `logout()` : Déconnexion
  - `hasRole(role)` : Vérification de rôle
  - `canAccess(feature)` : Contrôle d'accès par fonctionnalité

### 3. Permissions par Rôle

#### Administrateur
- **Accès total** à toutes les fonctionnalités
- Gestion des utilisateurs
- Configuration système

#### Caisse
- Ventes
- Clients
- Articles (lecture seule)
- Stocks (lecture seule)
- Caisse
- États de ventes

#### Vendeur
- Ventes
- Clients (lecture seule)
- Articles (lecture seule)
- Stocks (lecture seule)

### 4. Écrans Ajoutés

#### Écran de Connexion (LoginScreen)
- Design professionnel noir/blanc/gris
- Validation des champs
- Gestion des erreurs
- Compte par défaut affiché

#### Gestion des Utilisateurs (UsersManagementModal)
- Liste des utilisateurs avec statut
- Création/modification d'utilisateurs
- Activation/désactivation
- Contrôle d'accès (administrateurs uniquement)

### 5. Intégration Système

#### Écran Principal (HomeScreen)
- Affichage du nom et rôle de l'utilisateur connecté
- Bouton de déconnexion
- Contrôle d'accès aux menus selon les permissions
- Messages d'accès refusé

#### Base de Données
- Migration automatique vers version 41
- Création automatique de l'utilisateur admin par défaut
- Méthodes CRUD complètes pour les utilisateurs

### 6. Sécurité

#### Authentification
- Vérification email/mot de passe
- Gestion des sessions
- Redirection automatique vers login si non connecté

#### Autorisation
- Contrôle d'accès basé sur les rôles
- Vérification des permissions avant l'accès aux fonctionnalités
- Interface adaptée selon les droits

## Compte par Défaut

**Email** : admin@magasin.mg  
**Mot de passe** : admin123  
**Rôle** : Administrateur

## Utilisation

1. **Premier démarrage** : L'application crée automatiquement le compte administrateur
2. **Connexion** : Utiliser les identifiants par défaut ou créer de nouveaux utilisateurs
3. **Gestion** : Les administrateurs peuvent gérer les utilisateurs via Paramètres > Gestion des utilisateurs
4. **Permissions** : L'interface s'adapte automatiquement selon le rôle de l'utilisateur connecté

## Architecture

```
lib/
├── services/
│   └── auth_service.dart          # Service d'authentification
├── screens/
│   ├── login_screen.dart          # Écran de connexion
│   └── splash_screen.dart         # Modifié pour intégrer l'auth
├── widgets/modals/
│   └── users_management_modal.dart # Gestion des utilisateurs
└── database/
    ├── database.dart              # Table Users ajoutée
    └── database_service.dart      # Méthodes utilisateurs
```

## Sécurité Future

Pour une sécurité renforcée, considérer :
- Hachage des mots de passe (bcrypt, argon2)
- Tokens JWT pour les sessions
- Audit des actions utilisateurs
- Politique de mots de passe complexes
- Verrouillage après tentatives échouées