# Gestion de Magasin

Application de gestion de magasin développée avec Flutter pour desktop Windows.

## Fonctionnalités

### Modules principaux

- **Commerces** : Gestion des opérations commerciales
- **Gestions** : Administration et gestion générale
- **Trésorerie** : Gestion financière et comptable
- **États** : Rapports et statistiques
- **Paramètres** : Configuration de l'application
- **Aide** : Documentation et support

### Module États

- Articles
- Clients
- Commerciaux
- Immobilisations
- Autres Comptes
- Marges
- Statistiques Achats
- Statistiques Ventes

## Installation

1. Assurez-vous d'avoir Flutter installé avec support desktop Windows
2. Clonez le projet
3. Exécutez `flutter pub get` pour installer les dépendances
4. Lancez l'application avec `flutter run -d windows`

## Configuration requise

- Flutter SDK >=3.10.0
- Windows 10 ou supérieur
- Visual Studio 2019 ou supérieur (pour la compilation)

## Structure du projet

```
lib/
├── main.dart              # Point d'entrée de l'application
├── screens/
│   └── home_screen.dart   # Écran principal avec menu
├── widgets/
│   └── menu_card.dart     # Widget pour les cartes du menu
└── models/                # Modèles de données (à développer)
```

## Développement

L'application utilise une architecture modulaire avec :

- Navigation par cartes sur l'écran principal
- Sous-menu contextuel pour les États
- Interface adaptée pour desktop Windows
- Thème Material Design 3
