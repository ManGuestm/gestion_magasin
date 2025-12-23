# Nouveau Rôle : Consultant

## Résumé des modifications

Un nouveau rôle utilisateur "Consultant" a été ajouté à l'application avec les restrictions suivantes :

### Caractéristiques du rôle Consultant

✅ **Permissions accordées :**
- Accès uniquement au menu "Ventes (Tous dépôts)"
- Peut voir l'aperçu de facture de vente

❌ **Restrictions :**
- Ne peut PAS imprimer les factures
- Ne peut PAS imprimer les bons de livraison
- Ne peut PAS accéder aux autres modules (Achats, Fournisseurs, Trésorerie, etc.)
- Ne peut PAS créer ou modifier de ventes

### Fichiers modifiés

1. **lib/services/auth_service.dart**
   - Ajout des permissions pour le rôle Consultant
   - Ajout de la méthode `isConsultantRestrictedModal()` pour vérifier les restrictions
   - Ajout de la méthode `canPrint()` pour vérifier si l'utilisateur peut imprimer

2. **lib/services/menu_service.dart**
   - Filtrage des menus pour n'afficher que "Ventes (Tous dépôts)" pour les consultants

3. **lib/screens/gestion_utilisateurs_screen.dart**
   - Ajout du rôle "Consultant" dans le dropdown de sélection
   - Ajout de la couleur violette pour identifier visuellement le rôle Consultant

4. **lib/widgets/modals/ventes_modal.dart**
   - Ajout de la méthode `_canPrint()` pour vérifier les permissions d'impression
   - Modification des boutons "Imprimer Facture" et "Imprimer BL" pour les cacher aux consultants

### Comment créer un utilisateur Consultant

1. Aller dans **Paramètres** → **Gestion des utilisateurs**
2. Cliquer sur **Ajouter un utilisateur**
3. Remplir les informations :
   - Nom complet
   - Nom d'utilisateur
   - Mot de passe
   - **Rôle : Consultant** (nouveau choix disponible)
4. Cliquer sur **Créer**

### Comportement attendu

Lorsqu'un utilisateur avec le rôle "Consultant" se connecte :

1. Le menu principal n'affiche que "Ventes (Tous dépôts)"
2. Dans l'écran de ventes :
   - Peut voir toutes les ventes existantes
   - Peut cliquer sur "Aperçu Facture" pour voir la facture
   - Les boutons "Imprimer Facture" et "Imprimer BL" sont cachés
3. Tous les autres menus sont inaccessibles

### Code couleur des rôles

- 🔴 **Administrateur** : Rouge
- 🟠 **Caisse** : Orange
- 🟢 **Vendeur** : Vert
- 🟣 **Consultant** : Violet (nouveau)

### Notes techniques

- Le rôle Consultant est stocké dans la base de données comme les autres rôles
- Les restrictions sont appliquées côté client (interface) et peuvent être renforcées côté serveur si nécessaire
- Le système de permissions est extensible pour ajouter d'autres rôles à l'avenir
