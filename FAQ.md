# FAQ - Architecture Serveur/Client

## ❓ Questions fréquentes

### 1. Pourquoi l'Administrateur ne peut-il pas se connecter en mode Client?

**Réponse**: Pour des raisons de sécurité et d'architecture:
- L'Administrateur a accès à toutes les fonctionnalités sensibles
- Le serveur doit toujours être disponible (ordinateur principal)
- Séparation claire des responsabilités

**Solution**: Utilisez le mode Serveur pour les Administrateurs.

---

### 2. Puis-je avoir plusieurs serveurs?

**Réponse**: Non, l'architecture actuelle supporte un seul serveur.

**Raison**: Un seul serveur garantit la cohérence des données.

**Alternative future**: Haute disponibilité avec réplication (v3.0).

---

### 3. Que se passe-t-il si le serveur tombe en panne?

**Réponse**: Les clients ne peuvent plus travailler car ils n'ont pas de base locale.

**Solutions**:
- Serveur sur ordinateur fiable
- UPS (onduleur) pour le serveur
- Sauvegarde automatique activée
- Plan de reprise d'activité

---

### 4. Les clients peuvent-ils travailler hors ligne?

**Réponse**: Non, les clients nécessitent une connexion permanente au serveur.

**Raison**: Pas de base de données locale en mode client.

**Alternative**: Utiliser le mode Serveur (avec base locale) si besoin de travailler hors ligne.

---

### 5. Comment créer des comptes utilisateurs?

**Réponse**: Sur le serveur, via l'interface de gestion des utilisateurs:
1. Se connecter en tant qu'Administrateur
2. Aller dans Paramètres → Gestion utilisateurs
3. Créer un nouveau compte avec le rôle approprié

**Rôles disponibles**:
- Administrateur (serveur uniquement)
- Caisse (client uniquement)
- Vendeur (client uniquement)

---

### 6. Quelle est la différence entre Caisse et Vendeur?

**Réponse**: 
- **Vendeur**: Peut créer des ventes, gérer les clients, consulter les articles
- **Caisse**: Peut créer des ventes, gérer les encaissements, consulter les rapports

**Point commun**: Les deux peuvent se connecter en mode client.

---

### 7. Combien de clients peuvent se connecter simultanément?

**Réponse**: 50+ clients testés avec succès.

**Facteurs limitants**:
- Puissance du serveur
- Qualité du réseau local
- Nombre de requêtes simultanées

**Recommandation**: 10-20 clients pour une performance optimale.

---

### 8. Comment trouver l'adresse IP du serveur?

**Réponse**: Sur le serveur, ouvrir CMD et taper:
```cmd
ipconfig
```
Chercher "Adresse IPv4" (ex: 192.168.1.100)

---

### 9. Le port 8080 est déjà utilisé, que faire?

**Réponse**: Changer le port dans la configuration:
1. Serveur: Modifier le port dans `network_config_service.dart`
2. Clients: Saisir le nouveau port dans la configuration

**Ports alternatifs**: 8081, 8082, 9000, etc.

---

### 10. Comment sauvegarder la base de données?

**Réponse**: Sur le serveur:
1. Aller dans Paramètres → Sauvegarde
2. Cliquer sur "Sauvegarder maintenant"
3. Choisir l'emplacement

**Automatique**: Activer la sauvegarde automatique dans les paramètres.

---

### 11. Puis-je utiliser l'application sur plusieurs sites?

**Réponse**: Oui, mais chaque site doit avoir son propre serveur.

**Configuration**:
- Site A: Serveur A (192.168.1.100)
- Site B: Serveur B (192.168.2.100)
- Les clients de chaque site se connectent à leur serveur local

**Note**: Pas de synchronisation entre sites (pour l'instant).

---

### 12. Comment migrer d'un ancien système?

**Réponse**: Voir `MIGRATION_GUIDE.md` pour les détails.

**Étapes rapides**:
1. Sauvegarder l'ancienne base
2. Installer la nouvelle version
3. Configurer le mode Serveur
4. Importer les données (si nécessaire)
5. Configurer les clients

---

### 13. La synchronisation est-elle instantanée?

**Réponse**: Quasi-instantanée (< 20ms sur LAN).

**Technologie**: WebSocket pour notifications en temps réel.

**Exemple**: Vente créée sur Client A → Visible sur Client B en < 20ms.

---

### 14. Que faire si un client perd la connexion?

**Réponse**: Le client tente automatiquement de se reconnecter.

**Tentatives**: 5 tentatives avec délai de 3 secondes.

**Action utilisateur**: Vérifier le réseau et redémarrer l'application si nécessaire.

---

### 15. Comment désactiver un utilisateur?

**Réponse**: Sur le serveur:
1. Paramètres → Gestion utilisateurs
2. Sélectionner l'utilisateur
3. Cliquer sur "Désactiver"

**Effet**: L'utilisateur ne peut plus se connecter.

---

### 16. Les données sont-elles chiffrées?

**Réponse**: 
- **Mots de passe**: Oui (bcrypt)
- **Communications**: Non (LAN local)
- **Base de données**: Non (SQLite non chiffré)

**Recommandation**: Utiliser un réseau local sécurisé.

---

### 17. Puis-je accéder au serveur depuis Internet?

**Réponse**: Non recommandé pour des raisons de sécurité.

**Alternative**: VPN pour accès distant sécurisé.

---

### 18. Comment voir les clients connectés?

**Réponse**: Sur le serveur:
1. Aller dans Paramètres → Réseau
2. Cliquer sur "Clients connectés"

**Informations affichées**:
- Nom d'utilisateur
- Adresse IP
- Heure de connexion
- Statut

---

### 19. Que faire en cas d'erreur "Base de données non initialisée"?

**Réponse**: 
1. Redémarrer l'application
2. Vérifier la configuration réseau
3. Consulter les logs de démarrage
4. Effacer la configuration et reconfigurer

---

### 20. Comment mettre à jour l'application?

**Réponse**:
1. Sauvegarder la base de données (serveur)
2. Fermer toutes les instances
3. Installer la nouvelle version
4. Redémarrer le serveur en premier
5. Redémarrer les clients

**Important**: Toujours mettre à jour le serveur en premier.

---

## 🔧 Problèmes courants

### Erreur: "Accès refusé"
**Cause**: Rôle incorrect pour le mode
**Solution**: Vérifier le rôle et le mode (Serveur/Client)

### Erreur: "Impossible de se connecter au serveur"
**Cause**: Serveur non démarré ou réseau inaccessible
**Solution**: Vérifier serveur, IP, port, pare-feu

### Erreur: "Token expiré"
**Cause**: Session expirée
**Solution**: Se reconnecter

### Erreur: "Rate limit exceeded"
**Cause**: Trop de requêtes
**Solution**: Attendre 60 secondes

---

## 📚 Ressources

- **Architecture**: `ARCHITECTURE_SERVEUR_CLIENT.md`
- **Migration**: `MIGRATION_GUIDE.md`
- **Configuration**: `CONFIG_EXAMPLES.md`
- **Diagrammes**: `ARCHITECTURE_DIAGRAM.md`
- **Référence rapide**: `QUICK_REFERENCE.md`

---

## 💡 Conseils

1. **Serveur**: Ordinateur puissant, toujours allumé
2. **Réseau**: LAN stable, câblé si possible
3. **Sauvegarde**: Automatique + manuelle régulière
4. **Utilisateurs**: Rôles appropriés pour chaque poste
5. **Monitoring**: Vérifier régulièrement les clients connectés

---

**Besoin d'aide?** Consultez la documentation ou contactez le support.
