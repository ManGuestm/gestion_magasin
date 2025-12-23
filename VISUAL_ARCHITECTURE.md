# 🎨 Architecture Visuelle - Serveur/Client v2.0

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    GESTION MAGASIN - ARCHITECTURE v2.0                    ║
║                         Serveur/Client Strict                             ║
╚═══════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────┐
│                         RÉSEAU LOCAL (LAN)                              │
│                         192.168.1.0/24                                  │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        │                         │                         │
        ▼                         ▼                         ▼

╔═══════════════════╗   ╔═══════════════════╗   ╔═══════════════════╗
║    SERVEUR        ║   ║    CLIENT 1       ║   ║    CLIENT 2       ║
║                   ║   ║                   ║   ║                   ║
║  🖥️  Principal    ║   ║  💻 Vendeur       ║   ║  💻 Caisse        ║
║                   ║   ║                   ║   ║                   ║
║  192.168.1.100    ║   ║  192.168.1.101    ║   ║  192.168.1.102    ║
║  Port: 8080       ║   ║                   ║   ║                   ║
║                   ║   ║                   ║   ║                   ║
║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║
║  │ 🔒 Admin    │  ║   ║  │ 🔒 Vendeur  │  ║   ║  │ 🔒 Caisse   │  ║
║  │ UNIQUEMENT  │  ║   ║  │ UNIQUEMENT  │  ║   ║  │ UNIQUEMENT  │  ║
║  └─────────────┘  ║   ║  └─────────────┘  ║   ║  └─────────────┘  ║
║                   ║   ║                   ║   ║                   ║
║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║
║  │ 💾 SQLite   │  ║   ║  │ ❌ Pas de   │  ║   ║  │ ❌ Pas de   │  ║
║  │ Locale      │  ║   ║  │ base locale │  ║   ║  │ base locale │  ║
║  └─────────────┘  ║   ║  └─────────────┘  ║   ║  └─────────────┘  ║
║                   ║   ║                   ║   ║                   ║
║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║   ║  ┌─────────────┐  ║
║  │ HTTP Server │  ║   ║  │ HTTP Client │  ║   ║  │ HTTP Client │  ║
║  │ WebSocket   │  ║   ║  │ WebSocket   │  ║   ║  │ WebSocket   │  ║
║  └─────────────┘  ║   ║  └─────────────┘  ║   ║  └─────────────┘  ║
╚═══════════════════╝   ╚═══════════════════╝   ╚═══════════════════╝
        │                         │                         │
        └─────────────────────────┴─────────────────────────┘
                                  │
                    Synchronisation temps réel
                         WebSocket < 20ms


╔═══════════════════════════════════════════════════════════════════════════╗
║                         FLUX DE SYNCHRONISATION                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

    CLIENT A (Vendeur)
         │
         │ 1️⃣ Créer une vente
         │    POST /api/query
         │    INSERT INTO ventes...
         ▼
    ┌─────────┐
    │ SERVEUR │
    └────┬────┘
         │
         │ 2️⃣ Enregistrer dans SQLite
         │
         │ 3️⃣ Broadcast WebSocket
         │    {"type": "data_change", ...}
         │
         ├──────────────┬──────────────┐
         │              │              │
         ▼              ▼              ▼
    CLIENT A       CLIENT B       CLIENT C
    (Vendeur)      (Caisse)       (Vendeur)
         │              │              │
         │ 4️⃣ Notification reçue       │
         │    Rafraîchir UI            │
         ▼              ▼              ▼
    [UI Update]   [UI Update]   [UI Update]


╔═══════════════════════════════════════════════════════════════════════════╗
║                         CONTRÔLE D'ACCÈS                                  ║
╚═══════════════════════════════════════════════════════════════════════════╝

                    ┌───────────────────┐
                    │ AUTHENTIFICATION  │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  Vérifier rôle    │
                    └─────────┬─────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │Administrateur│  │    Caisse    │  │   Vendeur    │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                 │
    Mode CLIENT?      Mode CLIENT?      Mode CLIENT?
           │                 │                 │
           ▼                 ▼                 ▼
        ❌ NON            ✅ OUI            ✅ OUI
           │                 │                 │
           ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ Accès refusé │  │ Token généré │  │ Token généré │
    │ Message:     │  │ Connexion OK │  │ Connexion OK │
    │ "Admin doit  │  └──────────────┘  └──────────────┘
    │ utiliser     │
    │ Serveur"     │
    └──────────────┘


╔═══════════════════════════════════════════════════════════════════════════╗
║                         MATRICE D'ACCÈS                                   ║
╚═══════════════════════════════════════════════════════════════════════════╝

    ┌────────────────┬──────────┬──────────┬──────────────┐
    │ Rôle           │ Serveur  │ Client   │ Base locale  │
    ├────────────────┼──────────┼──────────┼──────────────┤
    │ Administrateur │ ✅ OUI   │ ❌ NON   │ ✅ OUI       │
    │ Caisse         │ ❌ NON   │ ✅ OUI   │ ❌ NON       │
    │ Vendeur        │ ❌ NON   │ ✅ OUI   │ ❌ NON       │
    └────────────────┴──────────┴──────────┴──────────────┘


╔═══════════════════════════════════════════════════════════════════════════╗
║                         STACK TECHNIQUE                                   ║
╚═══════════════════════════════════════════════════════════════════════════╝

    SERVEUR                          CLIENT
    ┌─────────────────┐             ┌─────────────────┐
    │ Flutter App     │             │ Flutter App     │
    ├─────────────────┤             ├─────────────────┤
    │ NetworkServer   │             │ NetworkClient   │
    ├─────────────────┤             ├─────────────────┤
    │ HTTP Server     │◄───────────►│ HTTP Client     │
    │ (Port 8080)     │   REST API  │                 │
    ├─────────────────┤             ├─────────────────┤
    │ WebSocket       │◄───────────►│ WebSocket       │
    │ Server          │  Real-time  │ Client          │
    ├─────────────────┤             ├─────────────────┤
    │ DatabaseService │             │ NetworkDatabase │
    ├─────────────────┤             │ Service         │
    │ SQLite (Drift)  │             │ (Pas de DB)     │
    └─────────────────┘             └─────────────────┘


╔═══════════════════════════════════════════════════════════════════════════╗
║                         PERFORMANCE                                       ║
╚═══════════════════════════════════════════════════════════════════════════╝

    Latence réseau (LAN)
    ┌────────────────────────────────────────┐
    │ Ping:                    < 1 ms        │
    │ Requête HTTP:            5-10 ms       │
    │ WebSocket notification:  < 5 ms        │
    │ Synchronisation totale:  10-20 ms      │
    └────────────────────────────────────────┘

    Capacité
    ┌────────────────────────────────────────┐
    │ Clients simultanés:      50+           │
    │ Requêtes/minute:         1000+         │
    │ Taille base SQLite:      < 10 GB       │
    └────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════════════════╗
║                         SÉCURITÉ                                          ║
╚═══════════════════════════════════════════════════════════════════════════╝

    Couches de sécurité
    ┌─────────────────────────────────────────────────┐
    │ 1️⃣ Authentification                             │
    │    ├─ Username + Password                       │
    │    ├─ Vérification bcrypt                       │
    │    └─ Token généré                              │
    │                                                  │
    │ 2️⃣ Validation du rôle                           │
    │    ├─ Administrateur → Serveur uniquement       │
    │    ├─ Caisse → Client uniquement                │
    │    └─ Vendeur → Client uniquement               │
    │                                                  │
    │ 3️⃣ WebSocket sécurisé                           │
    │    ├─ Bearer Token requis                       │
    │    ├─ Validation CSRF (Origin/Host)             │
    │    └─ Session Manager                           │
    │                                                  │
    │ 4️⃣ Audit complet                                │
    │    ├─ Toutes les tentatives loggées             │
    │    ├─ Actions tracées                           │
    │    └─ Historique complet                        │
    └─────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════════════════╗
║                         LÉGENDE                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

    🖥️  = Serveur
    💻 = Client
    🔒 = Restriction d'accès
    💾 = Base de données
    ❌ = Interdit
    ✅ = Autorisé
    ◄─► = Communication bidirectionnelle
    ──► = Communication unidirectionnelle
    1️⃣ 2️⃣ 3️⃣ 4️⃣ = Étapes du processus


╔═══════════════════════════════════════════════════════════════════════════╗
║                         VERSION                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

    Version: 2.0
    Date: 2024
    Statut: ✅ Prêt pour production
```
