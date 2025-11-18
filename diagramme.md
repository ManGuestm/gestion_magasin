Diagramme de la Base de Données Gestion Magasin
ENTITÉS PRINCIPALES
📦 ARTICLES (articles)
designation (PK) - Désignation de l'article
u1, u2, u3 - Unités de mesure
tu2u1, tu3u2 - Taux de conversion
pvu1, pvu2, pvu3 - Prix de vente par unité
stocksu1, stocksu2, stocksu3 - Stocks par unité
sec, usec, cmup - Section et coût moyen
dep, action, categorie - Département et classification
emb - Emballage

👥 CLIENTS (clt)
rsoc (PK) - Raison sociale
adr, capital, rcs, nif, stat - Informations société
tel, port, email, site - Coordonnées
soldes, soldesa - Soldes
delai, plafon, taux - Conditions commerciales
commercial, categorie - Références commerciales

🏭 FOURNISSEURS (frns)
rsoc (PK) - Raison sociale
adr, capital, rcs, nif, stat - Informations société
tel, port, email, site - Coordonnées
soldes, soldesa - Soldes
datedernop, delai - Dernières opérations

GESTION DES STOCKS
📊 STOCKS (stocks)
ref (PK) - Référence
daty, lib - Date et libellé
numachats, numventes - Références opérations
refart - Référence article
qe, qs - Quantités entrée/sortie
entres, sortie - Mouvements
stocksu1, stocksu2, stocksu3 - Niveaux de stock
depots, cmup - Localisation et coût
clt, frns - Relations clients/fournisseurs

🏬 DÉPÔTS (depots)
depots (PK) - Nom du dépôt

🔄 TRANSFERT (transf)
num (PK) - Numéro transfert
numtransf - Référence transfert
daty - Date
de, au - Départ/Arrivée
contre - Contrepartie

OPÉRATIONS COMMERCIALES
🛒 VENTES (ventes)
num (PK) - Numéro vente
numventes, nfact - Références
daty - Date
clt - Client
modepai, echeance - Paiement
totalnt, totalttc, tva - Totaux
avance, regl - Règlements
commerc, commission - Commercial
emb, transp - Logistique

🛍️ DÉTAILS VENTES (detventes)
num (PK) - Numéro ligne
numventes - Référence vente
designation - Article
unites, depots - Unités et dépôt
q, pu - Quantité et prix
emb, transp - Logistique

📥 ACHATS (achats)
num (PK) - Numéro achat
numachats, nfact - Références
daty - Date
frns - Fournisseur
modepai, echeance - Paiement
totalnt, totalttc, tva - Totaux
contre, bq - Conditions
regl, datregl - Règlement

📋 DÉTAILS ACHATS (detachats)
num (PK) - Numéro ligne
numachats - Référence achat
designation - Article
unites, depots - Unités et dépôt
q, pu - Quantité et prix
emb, transp - Logistique

GESTION FINANCIÈRE
💰 CAISSE (caisse)
ref (PK) - Référence
daty, lib - Date et libellé
debit, credit - Mouvements
soldes - Solde
type, clt, frns - Typologie

🏦 BANQUE (banque)
ref (PK) - Référence
daty, lib - Date et libellé
debit, credit - Mouvements
soldes - Solde
code, type - Codification
clt, frns - Relations

📝 CHÈQUES (chequier)
ncheq - Numéro chèque
tire, bqtire - Tiré et banque
montant - Montant
datechq, daterecep - Dates
action, numventes - Statut et référence

COMPTES ET RÉCONCILIATION
💳 COMPTE CLIENT (compteclt)
ref (PK) - Référence
daty, lib - Date et libellé
numventes, nfact - Références vente
refart - Article
qs, pus - Quantités et prix
entres, sorties - Mouvements
solde - Solde client
clt - Client

💼 COMPTE FOURNISSEUR (comptefrns)
ref (PK) - Référence
daty, lib - Date et libellé
numachats, nfact - Références achat
refart - Article
qe, pu - Quantités et prix
entres, sortie - Mouvements
solde - Solde fournisseur
frns - Fournisseur

UTILISATEURS ET SOCIÉTÉ
👤 UTILISATEURS (users)
id (PK) - Identifiant
nom, username - Informations
mot_de_passe - Mot de passe
role - Rôle utilisateur
actif - Statut
date_creation - Date création

🏢 SOCIÉTÉ (soc)
ref (PK) - Référence
rsoc - Raison sociale
activites - Activités
adr, logo - Adresse et logo
capital, rcs, nif, stat - Informations légales
tel, email, site - Coordonnées
tva, t - Taxes

TABLES SPÉCIALISÉES
RETOURS (retventes, retachats)
BONS DE LIVRAISON (blclt)
PRODUCTION (prod, detprod)
EMBALLAGES (emb)
COMMERCIAUX (com)
PRIX DE VENTE (pv)

Ce schéma représente un système complet de gestion d'entrepôt avec :
Gestion multi-dépôts
Unités de mesure multiples
Suivi financier complet
Gestion des tiers (clients/fournisseurs)
Contrôle des stocks en temps réel
Système d'authentification