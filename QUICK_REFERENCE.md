# Référence Rapide - Architecture Serveur/Client

## 🚀 Démarrage rapide

### Mode Serveur (Administrateur)
```
1. Lancer l'application
2. Configuration réseau → Serveur → Sauvegarder
3. Redémarrer
4. Se connecter avec compte Administrateur
```

### Mode Client (Caisse/Vendeur)
```
1. Lancer l'application
2. Configuration réseau → Client
3. IP serveur: 192.168.1.100
4. Port: 8080
5. Tester → Sauvegarder
6. Redémarrer
7. Se connecter avec compte Caisse/Vendeur
```

---

## 🔐 Matrice d'accès

| Rôle | Serveur | Client |
|------|---------|--------|
| Administrateur | ✅ | ❌ |
| Caisse | ❌ | ✅ |
| Vendeur | ❌ | ✅ |

---

## 🌐 Ports et protocoles

| Service | Port | Protocole |
|---------|------|-----------|
| HTTP REST | 8080 | TCP |
| WebSocket | 8080 | TCP/WS |
| Health Check | 8080 | HTTP |

---

## 📊 Commandes utiles

### Trouver l'IP du serveur
```cmd
ipconfig
```

### Tester la connexion
```cmd
ping 192.168.1.100
telnet 192.168.1.100 8080
```

### Vérifier le serveur
```
http://localhost:8080/api/health
```

---

## 🐛 Dépannage express

### Problème: "Impossible de se connecter"
```
✓ Serveur démarré?
✓ IP correcte?
✓ Pare-feu autorise port 8080?
✓ Réseau local accessible?
```

### Problème: "Accès refusé"
```
✓ Administrateur → Mode Serveur
✓ Caisse/Vendeur → Mode Client
```

### Problème: "Pas de synchronisation"
```
✓ WebSocket connecté?
✓ Logs serveur: "Client WebSocket connecté"
✓ Logs client: "Changement reçu"
```

---

## 📞 Contacts

- Documentation: `ARCHITECTURE_SERVEUR_CLIENT.md`
- Migration: `MIGRATION_GUIDE.md`
- Configuration: `CONFIG_EXAMPLES.md`
- Support: Équipe de développement

---

## ⚡ Raccourcis clavier

| Action | Raccourci |
|--------|-----------|
| Nouvelle vente | Ctrl+N |
| Rechercher | Ctrl+F |
| Sauvegarder | Ctrl+S |
| Fermer | Échap |

---

## 📋 Checklist déploiement

### Serveur
- [ ] Application installée
- [ ] Mode Serveur configuré
- [ ] Compte Administrateur créé
- [ ] Serveur démarré (port 8080)
- [ ] Pare-feu configuré
- [ ] IP notée

### Client
- [ ] Application installée
- [ ] Mode Client configuré
- [ ] IP serveur saisie
- [ ] Connexion testée
- [ ] Compte Caisse/Vendeur créé
- [ ] Synchronisation vérifiée

---

**Version**: 2.0 | **Mise à jour**: 2024
