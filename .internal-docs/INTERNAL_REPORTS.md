# Rapports internes et constats techniques

## ⚠️ CONFIDENTIAL - DO NOT COMMIT TO PUBLIC REPOSITORY

Ce fichier regroupe les analyses, constats et problèmes techniques identifiés lors du développement. Il est destiné à l'équipe technique interne uniquement et réside en dehors de l'arborescence publique.

## Points critiques en mode Client réseau

- Gestion de connexion : Vérifiez que le client se connecte correctement au serveur et maintient la connexion
- Synchronisation des données : Les opérations CRUD doivent être routées vers le serveur distant, pas la base locale
- Gestion des transactions : Les transactions SQLite locales peuvent entrer en conflit avec les opérations distantes
- Timeout et retry : Les appels réseau doivent avoir une gestion d'erreur appropriée
- État de connexion : L'application doit détecter les déconnexions et basculer en mode approprié

## Actions recommandées

- Consultez le panneau Code Issues pour voir tous les problèmes de sécurité, qualité et architecture détectés
- Vérifiez particulièrement les fichiers liés aux services réseau et à la base de données
- Assurez-vous que les opérations en mode Client passent par HTTP/WebSocket et non par SQLite directement

---

**Note**: Ce fichier réside dans `.internal-docs/` qui est exclu de git. Pour l'accès en équipe, utilisez un stockage privé sécurisé (e.g., wiki privé, SharePoint, Notion).

Pour toute nouvelle analyse ou constat, ajoutez une section ci-dessous ou utilisez le tracker interne.
