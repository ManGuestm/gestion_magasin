# Configuration Réseau - Exemples

## 📋 Configuration Serveur

### Fichier: SharedPreferences (automatique)
```json
{
  "network_mode": "server",
  "server_port": "8080",
  "app_configured": true
}
```

### Étapes de configuration
1. Lancer l'application
2. Cliquer sur "Configuration réseau" (écran de login)
3. Sélectionner "Serveur"
4. Cliquer sur "Sauvegarder"
5. Redémarrer l'application
6. Se connecter avec un compte **Administrateur**

### Vérification
```bash
# Ouvrir un navigateur sur le serveur
http://localhost:8080/api/health

# Réponse attendue:
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

## 📋 Configuration Client

### Fichier: SharedPreferences (automatique)
```json
{
  "network_mode": "client",
  "server_ip": "192.168.1.100",
  "server_port": "8080",
  "network_username": "vendeur1",
  "network_password": "password123",
  "app_configured": true
}
```

### Étapes de configuration
1. Lancer l'application
2. Cliquer sur "Configuration réseau" (écran de login)
3. Sélectionner "Client"
4. Saisir l'adresse IP du serveur (ex: `192.168.1.100`)
5. Saisir le port: `8080`
6. Cliquer sur "Tester" pour vérifier la connexion
7. Cliquer sur "Sauvegarder"
8. Redémarrer l'application
9. Se connecter avec un compte **Caisse** ou **Vendeur**

### Vérification
```bash
# Sur le client, vérifier la connexion
# Les logs devraient afficher:
✅ CLIENT: Connecté à 192.168.1.100:8080
📌 Aucune base locale - Tout passe par le serveur
🔒 Accès: Caisse et Vendeur uniquement
```

---

## 🏢 Exemple de déploiement entreprise

### Scénario: Magasin avec 1 serveur et 3 clients

```
┌─────────────────────────────────────────────────────────────┐
│                    RÉSEAU LOCAL (LAN)                       │
│                    192.168.1.0/24                           │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌───────▼────────┐
│   SERVEUR      │   │   CLIENT 1      │   │   CLIENT 2     │
│                │   │                 │   │                │
│ IP: .100       │   │ IP: .101        │   │ IP: .102       │
│ Port: 8080     │   │ → Serveur: .100 │   │ → Serveur: .100│
│                │   │                 │   │                │
│ Utilisateur:   │   │ Utilisateur:    │   │ Utilisateur:   │
│ - admin        │   │ - vendeur1      │   │ - caisse1      │
│   (Admin)      │   │   (Vendeur)     │   │   (Caisse)     │
│                │   │                 │   │                │
│ Base SQLite    │   │ Pas de base     │   │ Pas de base    │
│ Locale         │   │ locale          │   │ locale         │
└────────────────┘   └─────────────────┘   └────────────────┘
```

### Configuration détaillée

#### Serveur (192.168.1.100)
```yaml
Mode: server
Port: 8080
Base de données: C:\Users\Admin\AppData\Local\gestion_magasin\database.db
Utilisateurs autorisés:
  - admin (Administrateur)
```

#### Client 1 (192.168.1.101) - Vendeur
```yaml
Mode: client
Serveur: 192.168.1.100:8080
Utilisateurs autorisés:
  - vendeur1 (Vendeur)
  - vendeur2 (Vendeur)
Base de données: Aucune (tout via réseau)
```

#### Client 2 (192.168.1.102) - Caisse
```yaml
Mode: client
Serveur: 192.168.1.100:8080
Utilisateurs autorisés:
  - caisse1 (Caisse)
  - caisse2 (Caisse)
Base de données: Aucune (tout via réseau)
```

---

## 🔐 Gestion des utilisateurs

### Création des comptes (sur le serveur)

```sql
-- Administrateur (pour le serveur)
INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation)
VALUES ('admin-001', 'Administrateur Principal', 'admin', 'hashed_password', 'Administrateur', 1, datetime('now'));

-- Vendeurs (pour les clients)
INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation)
VALUES ('vendeur-001', 'Vendeur 1', 'vendeur1', 'hashed_password', 'Vendeur', 1, datetime('now'));

INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation)
VALUES ('vendeur-002', 'Vendeur 2', 'vendeur2', 'hashed_password', 'Vendeur', 1, datetime('now'));

-- Caissiers (pour les clients)
INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation)
VALUES ('caisse-001', 'Caissier 1', 'caisse1', 'hashed_password', 'Caisse', 1, datetime('now'));

INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation)
VALUES ('caisse-002', 'Caissier 2', 'caisse2', 'hashed_password', 'Caisse', 1, datetime('now'));
```

### Matrice d'accès

| Rôle | Mode Serveur | Mode Client | Permissions |
|------|--------------|-------------|-------------|
| Administrateur | ✅ Oui | ❌ Non | Toutes |
| Vendeur | ❌ Non | ✅ Oui | Ventes, Clients, Articles |
| Caisse | ❌ Non | ✅ Oui | Ventes, Encaissements |

---

## 🌐 Configuration réseau Windows

### 1. Trouver l'adresse IP du serveur

```cmd
# Ouvrir CMD sur le serveur
ipconfig

# Chercher "Carte Ethernet" ou "Carte réseau sans fil"
# Noter l'adresse IPv4, exemple: 192.168.1.100
```

### 2. Configurer le pare-feu Windows

```cmd
# Ouvrir Windows Defender Firewall
# → Paramètres avancés
# → Règles de trafic entrant
# → Nouvelle règle...

Type: Port
Protocole: TCP
Port: 8080
Action: Autoriser la connexion
Profil: Domaine, Privé, Public
Nom: Gestion Magasin Server
```

### 3. Tester la connexion

```cmd
# Sur un client, tester la connexion
ping 192.168.1.100

# Tester le port
telnet 192.168.1.100 8080

# Ou utiliser PowerShell
Test-NetConnection -ComputerName 192.168.1.100 -Port 8080
```

---

## 🔧 Dépannage

### Problème: "Impossible de se connecter au serveur"

**Vérifications**:
```bash
# 1. Serveur démarré?
# Sur le serveur, vérifier les logs:
✅ Serveur démarré sur port 8080

# 2. Adresse IP correcte?
ipconfig  # Sur le serveur

# 3. Pare-feu autorise le port 8080?
# Windows Defender Firewall → Règles de trafic entrant

# 4. Réseau local accessible?
ping 192.168.1.100  # Depuis le client
```

### Problème: "Accès refusé"

**Causes**:
- Administrateur essaie de se connecter en mode client
- Caisse/Vendeur essaie de se connecter en mode serveur

**Solution**:
- Administrateur → Mode Serveur uniquement
- Caisse/Vendeur → Mode Client uniquement

### Problème: "Synchronisation ne fonctionne pas"

**Vérifications**:
```bash
# 1. WebSocket connecté?
# Logs client:
✅ Client WebSocket authentifié connecté

# 2. Changements diffusés?
# Logs serveur:
📤 Broadcast changement: insert

# 3. Changements reçus?
# Logs client:
📥 Changement reçu du serveur: insert
```

---

## 📊 Monitoring

### Logs serveur
```
🖥️  MODE SERVEUR
  → Initialisation de la base de données locale
  ✅ Base locale initialisée
  → Démarrage du serveur réseau...
  ✅ Serveur démarré avec succès
✅ Serveur démarré sur port 8080
🛡️  Services de sécurité activés
```

### Logs client
```
🌐 MODE CLIENT (RÉSEAU LOCAL)
  Serveur: 192.168.1.100:8080
  Utilisateur: vendeur1
  → Connexion au serveur...
  ✅ Connecté au serveur avec succès
✅ CLIENT: Connecté à 192.168.1.100:8080
📌 Aucune base locale - Tout passe par le serveur
🔒 Accès: Caisse et Vendeur uniquement
```

---

## 📚 Ressources

- **Architecture**: `ARCHITECTURE_SERVEUR_CLIENT.md`
- **Migration**: `MIGRATION_GUIDE.md`
- **Synchronisation**: `REALTIME_SYNC_GUIDE.md`
- **README**: `README.md`

---

**Version**: 2.0  
**Dernière mise à jour**: 2024
