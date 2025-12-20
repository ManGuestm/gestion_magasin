# 👥 Guide Utilisateur - Synchronisation Temps Réel

## 🎯 Qu'est-ce que c'est ?

La synchronisation temps réel permet à **tous les utilisateurs** de voir les modifications **instantanément** sur tous les ordinateurs connectés.

### Exemple Concret

```
📍 Magasin avec 3 ordinateurs :

Ordinateur 1 (Caisse)    : Vendeur enregistre une vente
Ordinateur 2 (Bureau)    : Administrateur voit la vente IMMÉDIATEMENT
Ordinateur 3 (Dépôt)     : Gestionnaire voit le stock mis à jour IMMÉDIATEMENT

⏱️ Temps : Moins d'1 seconde !
```

---

## ✅ Avantages

### Pour le Vendeur
- ✅ Pas besoin de rafraîchir manuellement
- ✅ Voit les nouveaux articles ajoutés par l'admin
- ✅ Voit les prix mis à jour en temps réel

### Pour l'Administrateur
- ✅ Voit toutes les ventes en temps réel
- ✅ Suit l'activité du magasin en direct
- ✅ Prend des décisions avec des données à jour

### Pour le Gestionnaire
- ✅ Voit les mouvements de stock instantanément
- ✅ Évite les ruptures de stock
- ✅ Optimise les commandes

---

## 🖥️ Configuration

### Étape 1 : Identifier le Serveur

**Un seul ordinateur doit être le serveur** (généralement l'ordinateur principal du bureau).

```
┌─────────────────────────────────────┐
│  ORDINATEUR SERVEUR                 │
│  • Ordinateur principal             │
│  • Toujours allumé                  │
│  • Contient la base de données      │
│  • Les autres se connectent à lui   │
└─────────────────────────────────────┘
```

### Étape 2 : Configurer le Serveur

1. Lancer l'application
2. Aller dans **Paramètres** → **Configuration Réseau**
3. Choisir **Mode : Serveur**
4. Noter l'adresse IP affichée (ex: `192.168.1.100`)
5. Cliquer sur **Enregistrer**

```
┌─────────────────────────────────────┐
│  Configuration Réseau               │
├─────────────────────────────────────┤
│  Mode : ● Serveur  ○ Client         │
│  Port : 8080                        │
│  IP Serveur : 192.168.1.100         │
│                                     │
│  [Enregistrer]                      │
└─────────────────────────────────────┘
```

### Étape 3 : Configurer les Clients

Sur **chaque autre ordinateur** :

1. Lancer l'application
2. Aller dans **Paramètres** → **Configuration Réseau**
3. Choisir **Mode : Client**
4. Entrer l'IP du serveur (ex: `192.168.1.100`)
5. Entrer le port : `8080`
6. Entrer vos identifiants
7. Cliquer sur **Enregistrer**

```
┌─────────────────────────────────────┐
│  Configuration Réseau               │
├─────────────────────────────────────┤
│  Mode : ○ Serveur  ● Client         │
│  IP Serveur : 192.168.1.100         │
│  Port : 8080                        │
│  Utilisateur : vendeur1             │
│  Mot de passe : ********            │
│                                     │
│  [Tester] [Enregistrer]             │
└─────────────────────────────────────┘
```

---

## 🔍 Vérifier que ça Fonctionne

### Test Simple

1. **Sur le Client 1** : Créer une vente
2. **Sur le Client 2** : Vérifier que la vente apparaît automatiquement
3. **Sur le Serveur** : Vérifier que la vente est visible

### Indicateurs de Connexion

```
✅ Connecté au serveur 192.168.1.100:8080
   3 clients connectés
```

Si vous voyez ce message, **tout fonctionne !**

---

## ⚠️ Problèmes Courants

### Problème 1 : "Impossible de se connecter au serveur"

**Solutions :**
1. Vérifier que le serveur est allumé
2. Vérifier l'adresse IP (elle peut changer)
3. Vérifier que les ordinateurs sont sur le même réseau
4. Désactiver temporairement le pare-feu

### Problème 2 : "Les changements n'apparaissent pas"

**Solutions :**
1. Vérifier la connexion (indicateur en haut)
2. Redémarrer l'application
3. Vérifier que le mode est bien configuré (Serveur/Client)

### Problème 3 : "Authentification échouée"

**Solutions :**
1. Vérifier le nom d'utilisateur
2. Vérifier le mot de passe
3. Contacter l'administrateur

---

## 📋 Scénarios d'Utilisation

### Scénario 1 : Vente à la Caisse

```
1. Vendeur (Caisse) enregistre une vente
   ↓
2. Vente apparaît IMMÉDIATEMENT sur :
   • Tableau de bord de l'admin
   • Écran de caisse du bureau
   • Rapport des ventes
```

### Scénario 2 : Ajout d'Article

```
1. Admin ajoute un nouvel article
   ↓
2. Article apparaît IMMÉDIATEMENT :
   • Dans la liste des articles du vendeur
   • Dans les écrans de vente
   • Dans les rapports de stock
```

### Scénario 3 : Modification de Prix

```
1. Admin modifie le prix d'un article
   ↓
2. Nouveau prix visible IMMÉDIATEMENT :
   • Sur tous les écrans de vente
   • Dans les devis en cours
   • Dans les rapports
```

---

## 🎓 Bonnes Pratiques

### ✅ À FAIRE

1. **Toujours laisser le serveur allumé** pendant les heures d'ouverture
2. **Vérifier la connexion** au début de la journée
3. **Utiliser des mots de passe forts** pour chaque utilisateur
4. **Sauvegarder régulièrement** la base de données

### ❌ À ÉVITER

1. **Ne pas éteindre le serveur** pendant que des clients travaillent
2. **Ne pas changer l'IP du serveur** sans prévenir
3. **Ne pas partager les mots de passe** entre utilisateurs
4. **Ne pas travailler hors ligne** si possible

---

## 📊 Tableau de Bord

### Informations Affichées en Temps Réel

```
┌─────────────────────────────────────────────────────┐
│  TABLEAU DE BORD                                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Ventes Aujourd'hui :  15 ventes  ← Mis à jour     │
│  Chiffre d'Affaires :  1,250,000 Ar  ← En direct   │
│  Clients :             234  ← Temps réel            │
│  Articles en Stock :   1,456  ← Synchronisé         │
│                                                     │
│  Dernière Vente : Il y a 2 minutes  ← Instantané   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔔 Notifications

Vous verrez des notifications quand :

- ✅ Une nouvelle vente est enregistrée
- ✅ Un article est ajouté ou modifié
- ✅ Un client est créé ou mis à jour
- ✅ Le stock change

```
┌─────────────────────────────────────┐
│  ✅ Nouvelle vente enregistrée      │
│     Vente #1234 - 45,000 Ar         │
└─────────────────────────────────────┘
```

---

## 🆘 Support

### En cas de problème :

1. **Vérifier la connexion** (indicateur en haut à droite)
2. **Redémarrer l'application**
3. **Contacter l'administrateur système**
4. **Consulter ce guide**

### Informations à fournir :

- Votre nom d'utilisateur
- Le message d'erreur exact
- Ce que vous faisiez quand le problème est survenu
- Capture d'écran si possible

---

## ✅ Checklist Quotidienne

### Au Début de la Journée

- [ ] Vérifier que le serveur est allumé
- [ ] Vérifier la connexion sur chaque client
- [ ] Tester une vente pour confirmer la synchronisation

### Pendant la Journée

- [ ] Surveiller l'indicateur de connexion
- [ ] Signaler tout problème immédiatement

### En Fin de Journée

- [ ] Vérifier que toutes les ventes sont synchronisées
- [ ] Faire une sauvegarde (si vous êtes admin)
- [ ] Laisser le serveur allumé (sauf instruction contraire)

---

## 🎉 Résumé

```
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║  ✅ SYNCHRONISATION TEMPS RÉEL ACTIVE                ║
║                                                       ║
║  • Tous les ordinateurs voient les mêmes données     ║
║  • Mises à jour instantanées (< 1 seconde)           ║
║  • Pas besoin de rafraîchir manuellement             ║
║  • Travaillez en toute confiance !                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

---

## 📞 Contact

**Administrateur Système :** [Nom]  
**Téléphone :** [Numéro]  
**Email :** [Email]

---

**Ce guide est destiné aux utilisateurs finaux. Pour la documentation technique, consultez les autres fichiers.**
