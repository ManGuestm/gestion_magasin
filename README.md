# Gestion de Magasin

Application professionnelle de gestion de magasin développée avec Flutter pour desktop Windows.

## 🚀 Fonctionnalités

### Modules Principaux

- **Commerces** : Ventes, achats, gestion articles/clients/fournisseurs
- **Gestions** : Stocks, transferts, dépôts, inventaires
- **Trésorerie** : Caisse, banque, comptes clients/fournisseurs
- **États** : Rapports détaillés et statistiques
- **Paramètres** : Configuration société et système

### Fonctionnalités Avancées

- **Authentification sécurisée** avec cryptage bcrypt
- **Architecture réseau** serveur/client avec synchronisation temps réel
- **Gestion multi-utilisateurs** avec contrôle d'accès par rôles
- **Audit complet** des actions utilisateurs
- **Sauvegarde automatique** programmable
- **Validation de données** en temps réel
- **Génération PDF** pour factures et rapports

## 🛠️ Technologies

- **Framework** : Flutter 3.10+
- **Base de données** : SQLite avec Drift ORM
- **Sécurité** : bcrypt, validation avancée
- **Réseau** : HTTP/WebSocket pour synchronisation
- **Architecture** : Clean Architecture avec services

## 📋 Prérequis

- Windows 10 ou supérieur
- Flutter SDK ≥3.10.0
- Visual Studio 2019+ (pour compilation)

## 🔧 Installation

1. **Cloner le projet**

   ```bash
   git clone <repository-url>
   cd gestion_magasin
   ```

2. **Installer les dépendances**

   ```bash
   flutter pub get
   ```

3. **Lancer l'application**

   ```bash
   flutter run -d windows
   ```

## 👤 Connexion par défaut

- **Utilisateur** : `admin`
- **Mot de passe** : `admin123`

## 🏗️ Architecture

```text
lib/
├── database/           # Modèles et base de données
├── screens/           # Écrans principaux
├── widgets/           # Composants réutilisables
├── services/          # Services métier
└── main.dart         # Point d'entrée
```

## 🔐 Sécurité

- Cryptage bcrypt pour mots de passe
- Audit trail complet
- Contrôle d'accès basé sur les rôles
- Validation de données stricte
- Sauvegarde chiffrée

## 📊 Gestion des Données

- **Articles** : Stock multi-dépôts, CMUP automatique
- **Clients/Fournisseurs** : Comptes, soldes, historique
- **Ventes/Achats** : Workflow brouillard → journal
- **Stocks** : Mouvements tracés, inventaires
- **Trésorerie** : Caisse, banque, règlements

## 🌐 Mode Réseau

L'application supporte deux modes :

- **Serveur** : Héberge la base de données
- **Client** : Se connecte au serveur avec synchronisation temps réel

## 📈 Rapports

- Statistiques ventes/achats
- États de stocks par dépôt
- Comptes clients/fournisseurs
- Marges et bénéfices
- Différences de prix

## 🔧 Configuration

Accès via **Paramètres** :

- Configuration société
- Gestion utilisateurs
- Paramètres réseau
- Sauvegarde automatique

## 📝 Licence

Propriétaire - Tous droits réservés

## 🆘 Support

Pour toute assistance technique, contactez l'équipe de développement.

ℹ️ Les analyses et constats techniques ont été déplacés vers le tracker interne. Pour les signalements ou le suivi des problèmes, consultez le fichier CONTRIBUTING ou le panneau Issues du projet.