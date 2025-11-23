# Guide de Navigation Tab/Shift+Tab

## Vue d'ensemble

La navigation par touches Tab et Shift+Tab a été implémentée dans toute l'application pour améliorer l'expérience utilisateur et permettre une navigation rapide entre les champs de formulaire.

## Fonctionnalités

### Navigation Tab
- **Tab** : Avance vers le champ suivant
- **Shift+Tab** : Retourne au champ précédent

### Implémentation

#### 1. Mixin TabNavigationMixin
Tous les modales utilisent maintenant le mixin `TabNavigationMixin` qui fournit :
- Gestion automatique des focus nodes
- Navigation séquentielle entre les champs
- Méthodes utilitaires pour la gestion du focus

#### 2. Composants mis à jour
- **FormNavigationMixin** : Mixin de base pour la navigation dans les formulaires
- **KeyboardService** : Service étendu avec support Tab/Shift+Tab
- **FormShortcutsWidget** : Widget de raccourcis avec navigation Tab
- **TabNavigationWidget** : Widget utilitaire pour la navigation Tab

#### 3. Modales concernés
Tous les modales de l'application (76 fichiers) ont été mis à jour :
- Modales d'ajout/modification (clients, articles, fournisseurs, etc.)
- Modales de gestion (ventes, achats, stocks, etc.)
- Modales d'états et rapports
- Modales de configuration

## Utilisation

### Pour les développeurs

#### Créer un nouveau modal avec navigation Tab
```dart
class MyModalState extends State<MyModal> with TabNavigationMixin {
  late final FocusNode _field1FocusNode;
  late final FocusNode _field2FocusNode;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser les focus nodes
    _field1FocusNode = createFocusNode();
    _field2FocusNode = createFocusNode();
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        child: Column(
          children: [
            TextFormField(
              focusNode: _field1FocusNode,
              onTap: () => updateFocusIndex(_field1FocusNode),
            ),
            TextFormField(
              focusNode: _field2FocusNode,
              onTap: () => updateFocusIndex(_field2FocusNode),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Méthodes disponibles
- `createFocusNode()` : Crée et enregistre un nouveau focus node
- `nextField()` : Passe au champ suivant
- `previousField()` : Retourne au champ précédent
- `updateFocusIndex(FocusNode)` : Met à jour l'index du focus actuel
- `handleTabNavigation(KeyEvent)` : Gère les événements Tab/Shift+Tab

### Pour les utilisateurs

#### Raccourcis clavier
- **Tab** : Passer au champ suivant
- **Shift+Tab** : Retourner au champ précédent
- **Enter** : Valider ou passer au champ suivant (selon le contexte)
- **Escape** : Fermer le modal

#### Navigation dans les formulaires
1. Ouvrir un modal de saisie
2. Utiliser Tab pour naviguer vers le champ suivant
3. Utiliser Shift+Tab pour revenir au champ précédent
4. Les champs sont parcourus dans l'ordre logique de saisie

## Avantages

### Productivité
- Navigation rapide sans utiliser la souris
- Saisie continue sans interruption
- Workflow optimisé pour les utilisateurs expérimentés

### Accessibilité
- Conforme aux standards d'accessibilité
- Support des lecteurs d'écran
- Navigation intuitive pour tous les utilisateurs

### Cohérence
- Comportement uniforme dans toute l'application
- Standards de navigation respectés
- Expérience utilisateur homogène

## Maintenance

### Ajout de nouveaux champs
Lors de l'ajout de nouveaux champs dans un modal existant :
1. Créer un nouveau focus node avec `createFocusNode()`
2. L'assigner au champ avec `focusNode: myFocusNode`
3. Ajouter `onTap: () => updateFocusIndex(myFocusNode)`

### Ordre de navigation
L'ordre de navigation suit l'ordre de création des focus nodes. Pour modifier l'ordre :
1. Réorganiser l'ordre d'appel de `createFocusNode()` dans `initState()`
2. Ou utiliser une liste personnalisée de focus nodes

### Débogage
- Vérifier que le mixin `TabNavigationMixin` est bien ajouté
- S'assurer que `handleTabNavigation(event)` est appelé dans `onKeyEvent`
- Contrôler que tous les champs ont un focus node assigné

## Fichiers modifiés

### Nouveaux fichiers
- `lib/widgets/common/tab_navigation_widget.dart`
- `lib/utils/tab_navigation_updater.dart`
- `apply_tab_navigation.dart`

### Fichiers mis à jour
- `lib/mixins/form_navigation_mixin.dart`
- `lib/services/keyboard_service.dart`
- `lib/widgets/common/form_shortcuts_widget.dart`
- Tous les modales dans `lib/widgets/modals/` (76 fichiers)

## Tests

### Test manuel
1. Ouvrir n'importe quel modal de saisie
2. Appuyer sur Tab pour naviguer entre les champs
3. Appuyer sur Shift+Tab pour revenir en arrière
4. Vérifier que la navigation est fluide et logique

### Cas de test
- Navigation dans les modales simples (ajout client, article)
- Navigation dans les modales complexes (ventes, achats)
- Comportement avec les champs désactivés
- Interaction avec les dropdowns et autocomplete

## Support

Pour toute question ou problème concernant la navigation Tab/Shift+Tab :
1. Vérifier ce guide de documentation
2. Consulter les exemples dans les modales existants
3. Tester avec les modales de référence (AddClientModal, AddArticleModal)