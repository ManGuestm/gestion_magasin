import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// Table Société - utilisée par: Menu Paramètres - Configuration société
class Soc extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  TextColumn get rsoc => text().withLength(max: 100).nullable()();
  TextColumn get activites => text().nullable()();
  TextColumn get adr => text().withLength(max: 200).nullable()();
  TextColumn get logo => text().withLength(max: 200).nullable()();
  RealColumn get capital => real().nullable()();
  TextColumn get rcs => text().withLength(max: 50).nullable()();
  TextColumn get nif => text().withLength(max: 50).nullable()();
  TextColumn get stat => text().withLength(max: 50).nullable()();
  TextColumn get tel => text().withLength(max: 20).nullable()();
  TextColumn get port => text().withLength(max: 20).nullable()();
  TextColumn get email => text().withLength(max: 100).nullable()();
  TextColumn get site => text().withLength(max: 100).nullable()();
  TextColumn get fax => text().withLength(max: 20).nullable()();
  TextColumn get telex => text().withLength(max: 50).nullable()();
  RealColumn get tva => real().nullable()();
  RealColumn get t => real().nullable()();
  TextColumn get val => text().withLength(max: 50).nullable()();
  TextColumn get cif => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Dépôts - utilisée par: Menu Gestions - Gestion des dépôts
class Depots extends Table {
  TextColumn get depots => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {depots};
}

// Table Articles - utilisée par: Menu États - Articles, Menu Commerces - Gestion articles
class Articles extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  TextColumn get u1 => text().withLength(max: 20).nullable()();
  TextColumn get u2 => text().withLength(max: 20).nullable()();
  RealColumn get tu2u1 => real().nullable()();
  TextColumn get u3 => text().withLength(max: 20).nullable()();
  RealColumn get tu3u2 => real().nullable()();
  RealColumn get pvu1 => real().nullable()();
  RealColumn get pvu2 => real().nullable()();
  RealColumn get pvu3 => real().nullable()();
  RealColumn get stocksu1 => real().nullable()();
  RealColumn get stocksu2 => real().nullable()();
  RealColumn get stocksu3 => real().nullable()();
  TextColumn get sec => text().withLength(max: 50).nullable()();
  RealColumn get usec => real().nullable()();
  RealColumn get cmup => real().nullable()();
  TextColumn get dep => text().withLength(max: 50).nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  TextColumn get categorie => text().withLength(max: 50).nullable()();
  TextColumn get classification => text().withLength(max: 50).nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {designation};
}

// Table Clients - utilisée par: Menu États - Clients, Menu Commerces - Gestion clients
class Clt extends Table {
  TextColumn get rsoc => text().withLength(min: 1, max: 100)();
  TextColumn get adr => text().withLength(max: 200).nullable()();
  RealColumn get capital => real().nullable()();
  TextColumn get rcs => text().withLength(max: 50).nullable()();
  TextColumn get nif => text().withLength(max: 50).nullable()();
  TextColumn get stat => text().withLength(max: 50).nullable()();
  TextColumn get tel => text().withLength(max: 20).nullable()();
  TextColumn get port => text().withLength(max: 20).nullable()();
  TextColumn get email => text().withLength(max: 100).nullable()();
  TextColumn get site => text().withLength(max: 100).nullable()();
  TextColumn get fax => text().withLength(max: 20).nullable()();
  TextColumn get telex => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();
  DateTimeColumn get datedernop => dateTime().nullable()();
  IntColumn get delai => integer().nullable()();
  RealColumn get soldesa => real().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  TextColumn get commercial => text().withLength(max: 100).nullable()();
  RealColumn get plafon => real().nullable()();
  RealColumn get taux => real().nullable()();
  TextColumn get categorie => text().withLength(max: 50).nullable()();
  RealColumn get plafonbl => real().nullable()();

  @override
  Set<Column> get primaryKey => {rsoc};
}

// Table Fournisseurs - utilisée par: Menu Commerces - Gestion fournisseurs
class Frns extends Table {
  TextColumn get rsoc => text().withLength(min: 1, max: 100)();
  TextColumn get adr => text().withLength(max: 200).nullable()();
  RealColumn get capital => real().nullable()();
  TextColumn get rcs => text().withLength(max: 50).nullable()();
  TextColumn get nif => text().withLength(max: 50).nullable()();
  TextColumn get stat => text().withLength(max: 50).nullable()();
  TextColumn get tel => text().withLength(max: 20).nullable()();
  TextColumn get port => text().withLength(max: 20).nullable()();
  TextColumn get email => text().withLength(max: 100).nullable()();
  TextColumn get site => text().withLength(max: 100).nullable()();
  TextColumn get fax => text().withLength(max: 20).nullable()();
  TextColumn get telex => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();
  DateTimeColumn get datedernop => dateTime().nullable()();
  IntColumn get delai => integer().nullable()();
  RealColumn get soldesa => real().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {rsoc};
}

// Table Commerciaux - utilisée par: Menu États - Commerciaux, Menu Gestions - Gestion commerciaux
class Com extends Table {
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  TextColumn get adr => text().withLength(max: 200).nullable()();
  TextColumn get tel => text().withLength(max: 20).nullable()();
  TextColumn get email => text().withLength(max: 100).nullable()();
  RealColumn get soldes => real().nullable()();
  RealColumn get taux => real().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  RealColumn get soldesa => real().nullable()();

  @override
  Set<Column> get primaryKey => {nom};
}

// Table Ventes - utilisée par: Menu Commerces - Ventes, Menu États - Statistiques Ventes
class Ventes extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get modepai => text().withLength(max: 50).nullable()();
  DateTimeColumn get echeance => dateTime().nullable()();
  RealColumn get totalnt => real().nullable()();
  RealColumn get totalttc => real().nullable()();
  RealColumn get tva => real().nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
  RealColumn get avance => real().nullable()();
  TextColumn get bq => text().withLength(max: 50).nullable()();
  RealColumn get regl => real().nullable()();
  DateTimeColumn get datrcol => dateTime().nullable()();
  TextColumn get mregl => text().withLength(max: 50).nullable()();
  TextColumn get commerc => text().withLength(max: 100).nullable()();
  RealColumn get commission => real().nullable()();
  RealColumn get remise => real().nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get as => text().withLength(max: 50).nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();
  TextColumn get transp => text().withLength(max: 100).nullable()();
  TextColumn get heure => text().withLength(max: 10).nullable()();
  TextColumn get poste => text().withLength(max: 50).nullable()();
  RealColumn get montantRecu => real().nullable()();
  RealColumn get monnaieARendre => real().nullable()();
}

// Table Achats - utilisée par: Menu Commerces - Achats, Menu États - Statistiques Achats
class Achats extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get modepai => text().withLength(max: 50).nullable()();
  DateTimeColumn get echeance => dateTime().nullable()();
  RealColumn get totalnt => real().nullable()();
  RealColumn get totalttc => real().nullable()();
  RealColumn get tva => real().nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
  TextColumn get bq => text().withLength(max: 50).nullable()();
  RealColumn get regl => real().nullable()();
  DateTimeColumn get datregl => dateTime().nullable()();
  TextColumn get mregl => text().withLength(max: 50).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get as => text().withLength(max: 50).nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();
  TextColumn get transp => text().withLength(max: 100).nullable()();
}

// Table Stocks - utilisée par: Menu Gestions - Gestion stocks, Menu États - Articles (stocks)
class Stocks extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  TextColumn get refart => text().withLength(max: 50).nullable()();
  RealColumn get qe => real().nullable()();
  RealColumn get entres => real().nullable()();
  RealColumn get qs => real().nullable()();
  RealColumn get pus => real().nullable()();
  RealColumn get sortie => real().nullable()();
  RealColumn get stocksu1 => real().nullable()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get ue => text().withLength(max: 20).nullable()();
  TextColumn get us => text().withLength(max: 20).nullable()();
  RealColumn get stocksu2 => real().nullable()();
  RealColumn get stocksu3 => real().nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get cmup => real().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  RealColumn get stkdep => real().nullable()();
  TextColumn get marq => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Autres Comptes - utilisée par: Menu États - Autres Comptes, Menu Trésorerie - Autres comptes
class Autrescompte extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  TextColumn get code => text().withLength(max: 50).nullable()();
  TextColumn get compte => text().withLength(max: 50).nullable()();
  RealColumn get entres => real().nullable()();
  RealColumn get sortie => real().nullable()();
  RealColumn get solde => real().nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Banque - utilisée par: Menu Trésorerie - Gestion banque
class Banque extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  RealColumn get debit => real().nullable()();
  RealColumn get credit => real().nullable()();
  RealColumn get soldes => real().nullable()();
  TextColumn get code => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get comptes => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Bon de Livraison Clients - utilisée par: Menu Commerces - Bon de livraison clients
class Blclt extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get ecrptancebi => text().withLength(max: 50).nullable()();
  RealColumn get montant => real().nullable()();
  TextColumn get mp => text().withLength(max: 50).nullable()();
  TextColumn get libpaiement => text().withLength(max: 100).nullable()();
  DateTimeColumn get echeancepaiement => dateTime().nullable()();
  RealColumn get rap => real().nullable()();
  TextColumn get com => text().withLength(max: 50).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
}

// Table Banques - utilisée par: Menu Trésorerie - Configuration banques
class Bq extends Table {
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get intitule => text().withLength(max: 100).nullable()();
  TextColumn get nCompte => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

// Table Comptes Auxiliaires - utilisée par: Menu Trésorerie - Comptes auxiliaires
class Ca extends Table {
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get intitule => text().withLength(max: 100).nullable()();
  TextColumn get compte => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();
  RealColumn get soldesa => real().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

// Table Caisse - utilisée par: Menu Trésorerie - Gestion caisse
class Caisse extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  RealColumn get debit => real().nullable()();
  RealColumn get credit => real().nullable()();
  RealColumn get soldes => real().nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get comptes => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Chéquier - utilisée par: Menu Trésorerie - Gestion chéquiers
class Chequier extends Table {
  IntColumn get a => integer().nullable()();
  IntColumn get nop => integer().nullable()();
  TextColumn get ncheq => text().withLength(max: 50).nullable()();
  TextColumn get tire => text().withLength(max: 100).nullable()();
  TextColumn get bqtire => text().withLength(max: 100).nullable()();
  RealColumn get montant => real().nullable()();
  DateTimeColumn get datechq => dateTime().nullable()();
  DateTimeColumn get daterecep => dateTime().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  TextColumn get nonaction => text().withLength(max: 50).nullable()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
}

// Table Clients Internes - utilisée par: Menu États - Clients (informations internes)
class Clti extends Table {
  TextColumn get rsoc => text().withLength(min: 1, max: 100)();
  RealColumn get soldes => real().nullable()();
  RealColumn get soldes1 => real().nullable()();
  IntColumn get zanaka => integer().nullable()();

  @override
  Set<Column> get primaryKey => {rsoc};
}

// Table Comptes Clients - utilisée par: Menu Trésorerie - Comptes clients
class Compteclt extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  TextColumn get refart => text().withLength(max: 50).nullable()();
  RealColumn get qs => real().nullable()();
  RealColumn get pus => real().nullable()();
  RealColumn get entres => real().nullable()();
  RealColumn get sorties => real().nullable()();
  RealColumn get solde => real().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Comptes Commerciaux - utilisée par: Menu Trésorerie - Comptes commerciaux
class Comptecom extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  RealColumn get entres => real().nullable()();
  RealColumn get sorties => real().nullable()();
  RealColumn get solde => real().nullable()();
  TextColumn get com => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  RealColumn get montant => real().nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Comptes Fournisseurs - utilisée par: Menu Trésorerie - Comptes fournisseurs
class Comptefrns extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  TextColumn get refart => text().withLength(max: 50).nullable()();
  RealColumn get qe => real().nullable()();
  RealColumn get pu => real().nullable()();
  RealColumn get entres => real().nullable()();
  RealColumn get sortie => real().nullable()();
  RealColumn get solde => real().nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Répartition par Dépôt - utilisée par: Menu Gestions - Répartition stocks par dépôt
class Depart extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  TextColumn get depots => text().withLength(min: 1, max: 50)();
  RealColumn get stocksu1 => real().nullable()();
  RealColumn get stocksu2 => real().nullable()();
  RealColumn get stocksu3 => real().nullable()();

  @override
  Set<Column> get primaryKey => {designation, depots};
}

// Table Détails Achats - utilisée par: Menu Commerces - Détails achats
class Detachats extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();
  TextColumn get transp => text().withLength(max: 100).nullable()();
  RealColumn get qe => real().nullable()();
}

// Table Détails Production - utilisée par: Menu Commerces - Détails production
class Detprod extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numaprod => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
}

// Table Détails Transferts - utilisée par: Menu Gestions - Détails transferts
class Dettransf extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numtransf => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  RealColumn get q => real().nullable()();
}

// Table Détails Ventes - utilisée par: Menu Commerces - Détails ventes
class Detventes extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();
  TextColumn get transp => text().withLength(max: 100).nullable()();
  RealColumn get qe => real().nullable()();
  RealColumn get diffPrix => real().nullable()(); // Différence entre prix de vente standard et prix saisi
}

// Table Effets de Commerce - utilisée par: Menu Trésorerie - Gestion effets de commerce
class Effets extends Table {
  IntColumn get a => integer().nullable()();
  IntColumn get nop => integer().nullable()();
  TextColumn get ncheq => text().withLength(max: 50).nullable()();
  TextColumn get tire => text().withLength(max: 100).nullable()();
  TextColumn get bqtire => text().withLength(max: 100).nullable()();
  RealColumn get montant => real().nullable()();
  DateTimeColumn get datechq => dateTime().nullable()();
  DateTimeColumn get daterecep => dateTime().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  TextColumn get nonaction => text().withLength(max: 50).nullable()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
}

// Table Immobilisations - utilisée par: Menu États - Immobilisations, Menu Gestions - Gestion immobilisations
class Emb extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  RealColumn get vo => real().nullable()();
  TextColumn get action => text().withLength(max: 50).nullable()();
  TextColumn get categorie => text().withLength(max: 50).nullable()();
  RealColumn get amt => real().nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get description => text().nullable()();
  RealColumn get taux => real().nullable()();

  @override
  Set<Column> get primaryKey => {designation};
}

// Table Emballages Clients - utilisée par: Menu Commerces - Emballages clients
class Emblclt extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get emb => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
}

// Table Fiches Stocks - utilisée par: Menu Gestions - Fiches stocks
class Fstocks extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  TextColumn get art => text().withLength(max: 100).nullable()();
  RealColumn get qe => real().nullable()();
  RealColumn get qs => real().nullable()();
  RealColumn get qst => real().nullable()();
  TextColumn get ue => text().withLength(max: 20).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Modes de Paiement - utilisée par: Menu Trésorerie - Modes de paiement
class Mp extends Table {
  TextColumn get mp => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {mp};
}

// Table Production - utilisée par: Menu Commerces - Production
class Prod extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numaprod => text().withLength(max: 50).nullable()();
  TextColumn get obs => text().nullable()();
  DateTimeColumn get socDaty => dateTime().nullable()();
  TextColumn get produits => text().withLength(max: 100).nullable()();
  TextColumn get depot => text().withLength(max: 50).nullable()();
  TextColumn get cte => text().withLength(max: 50).nullable()();
  RealColumn get totalttc => real().nullable()();
  RealColumn get cmup => real().nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get unite => text().withLength(max: 20).nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
}

// Table Prix de Vente - utilisée par: Menu Commerces - Prix de vente
class Pv extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  TextColumn get categorie => text().withLength(max: 50).nullable()();
  RealColumn get pvu1 => real().nullable()();
  RealColumn get pvu2 => real().nullable()();
  RealColumn get pvu3 => real().nullable()();

  @override
  Set<Column> get primaryKey => {designation};
}

// Table Retours Achats - utilisée par: Menu Commerces - Retours achats
class Retachats extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get frns => text().withLength(max: 100).nullable()();
  TextColumn get modepai => text().withLength(max: 50).nullable()();
  DateTimeColumn get echeance => dateTime().nullable()();
  RealColumn get totalnt => real().nullable()();
  RealColumn get totalttc => real().nullable()();
  RealColumn get tva => real().nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
  TextColumn get bq => text().withLength(max: 50).nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get numachats1 => text().withLength(max: 50).nullable()();
}

// Table Détails Retours Achats - utilisée par: Menu Commerces - Détails retours achats
class Retdetachats extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unite => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
}

// Table Détails Retours Ventes - utilisée par: Menu Commerces - Détails retours ventes
class Retdeventes extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
}

// Table Retours Ventes - utilisée par: Menu Commerces - Retours ventes
class Retventes extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get nfact => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get clt => text().withLength(max: 100).nullable()();
  TextColumn get modepai => text().withLength(max: 50).nullable()();
  DateTimeColumn get echeance => dateTime().nullable()();
  RealColumn get totalnt => real().nullable()();
  RealColumn get totalttc => real().nullable()();
  RealColumn get tva => real().nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
  RealColumn get avance => real().nullable()();
  TextColumn get bq => text().withLength(max: 50).nullable()();
  TextColumn get commerc => text().withLength(max: 100).nullable()();
  RealColumn get commission => real().nullable()();
  RealColumn get remise => real().nullable()();
  TextColumn get verification => text().withLength(max: 50).nullable()();
  TextColumn get type => text().withLength(max: 50).nullable()();
  TextColumn get numventes1 => text().withLength(max: 50).nullable()();
}

// Table Stock Intrants - utilisée par: Menu Commerces - Stock intrants production
class Sintrant extends Table {
  TextColumn get des => text().withLength(min: 1, max: 100)();
  RealColumn get q => real().nullable()();

  @override
  Set<Column> get primaryKey => {des};
}

// Table Stock Produits - utilisée par: Menu Commerces - Stock produits finis
class Sproduit extends Table {
  TextColumn get des => text().withLength(min: 1, max: 100)();
  RealColumn get q => real().nullable()();

  @override
  Set<Column> get primaryKey => {des};
}

// Table Unités de Mesure - utilisée par: Menu Paramètres - Unités de mesure
class Tblunit extends Table {
  TextColumn get lib => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {lib};
}

// Table Transferts - utilisée par: Menu Gestions - Transferts entre dépôts
class Transf extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numtransf => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get de => text().withLength(max: 50).nullable()();
  TextColumn get au => text().withLength(max: 50).nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
}

// Table Tri Banque - utilisée par: Menu Trésorerie - Tri opérations banque
class Tribanque extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  RealColumn get debit => real().nullable()();
  RealColumn get credit => real().nullable()();
  RealColumn get soldes => real().nullable()();
  TextColumn get code => text().withLength(max: 50).nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Tri Caisse - utilisée par: Menu Trésorerie - Tri opérations caisse
class Tricaisse extends Table {
  TextColumn get ref => text().withLength(min: 1, max: 50)();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get lib => text().withLength(max: 100).nullable()();
  RealColumn get debit => real().nullable()();
  RealColumn get credit => real().nullable()();
  RealColumn get soldes => real().nullable()();

  @override
  Set<Column> get primaryKey => {ref};
}

// Table Users - utilisée par: Système d'authentification multi-utilisateur
class Users extends Table {
  TextColumn get id => text().withLength(min: 1, max: 50)();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  TextColumn get username => text().withLength(min: 1, max: 100)();
  TextColumn get motDePasse => text().withLength(min: 1, max: 255)();
  TextColumn get role => text().withLength(min: 1, max: 50)();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();
  DateTimeColumn get dateCreation => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {username},
      ];
}

/// Base de données principale de l'application Gestion de Magasin
///
/// Cette classe gère toutes les opérations de base de données pour l'application
/// de gestion de magasin développée avec Flutter et Drift ORM.
///
/// Tables incluses:
/// - Configuration: Soc (Société), Depots, Tblunit (Unités)
/// - Commerce: Articles, Clt (Clients), Frns (Fournisseurs), Com (Commerciaux)
/// - Transactions: Ventes, Achats, Stocks, Détails des opérations
/// - Trésorerie: Banque, Caisse, Comptes, Modes de paiement
/// - Production: Prod, Sintrant, Sproduit
/// - Retours: Retachats, Retventes et leurs détails
/// - Immobilisations: Emb
/// - Transferts: Transf, Dettransf
@DriftDatabase(tables: [
  Soc,
  Depots,
  Articles,
  Clt,
  Frns,
  Com,
  Ventes,
  Achats,
  Stocks,
  Autrescompte,
  Banque,
  Blclt,
  Bq,
  Ca,
  Caisse,
  Chequier,
  Clti,
  Compteclt,
  Comptecom,
  Comptefrns,
  Depart,
  Detachats,
  Detprod,
  Dettransf,
  Detventes,
  Effets,
  Emb,
  Emblclt,
  Fstocks,
  Mp,
  Prod,
  Pv,
  Retachats,
  Retdetachats,
  Retdeventes,
  Retventes,
  Sintrant,
  Sproduit,
  Tblunit,
  Transf,
  Tribanque,
  Tricaisse,
  Users
])
class AppDatabase extends _$AppDatabase {
  /// Constructeur de la base de données
  /// Initialise la connexion à la base de données SQLite locale
  AppDatabase() : super(_openConnection());

  /// Version actuelle du schéma de base de données
  /// Incrémentée à chaque modification de structure
  @override
  int get schemaVersion => 43;

  /// Stratégie de migration de la base de données
  /// Gère la création initiale et les mises à jour de schéma
  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Création initiale de toutes les tables
        onCreate: (Migrator m) {
          return m.createAll();
        },
        // Migration progressive des versions antérieures
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1) {
            await m.createTable(depots);
            await m.createTable(articles);
            await m.createTable(clt);
            await m.createTable(frns);
            await m.createTable(com);
            await m.createTable(ventes);
            await m.createTable(achats);
            await m.createTable(stocks);
          } else if (from == 2) {
            await m.createTable(articles);
            await m.createTable(clt);
            await m.createTable(frns);
            await m.createTable(com);
            await m.createTable(ventes);
            await m.createTable(achats);
            await m.createTable(stocks);
          } else if (from == 3) {
            await m.createTable(articles);
            await m.createTable(clt);
            await m.createTable(frns);
            await m.createTable(com);
            await m.createTable(ventes);
            await m.createTable(achats);
            await m.createTable(stocks);
          } else if (from == 4) {
            await m.createTable(clt);
            await m.createTable(frns);
            await m.createTable(com);
            await m.createTable(ventes);
            await m.createTable(achats);
            await m.createTable(stocks);
          } else if (from == 5) {
            await m.createTable(autrescompte);
            await m.createTable(banque);
            await m.createTable(blclt);
          } else if (from == 6) {
            await m.createTable(bq);
          } else if (from == 7) {
            await m.createTable(ca);
          } else if (from == 8) {
            await m.createTable(caisse);
          } else if (from == 9) {
            await m.createTable(chequier);
          } else if (from == 10) {
            await m.createTable(clti);
          } else if (from == 11) {
            await m.createTable(compteclt);
          } else if (from == 12) {
            await m.createTable(comptecom);
          } else if (from == 13) {
            await m.createTable(comptefrns);
          } else if (from == 14) {
            await m.createTable(depart);
          } else if (from == 15) {
            await m.createTable(detachats);
          } else if (from == 16) {
            await m.createTable(detprod);
          } else if (from == 17) {
            await m.createTable(dettransf);
          } else if (from == 18) {
            await m.createTable(detventes);
          } else if (from == 19) {
            await m.createTable(effets);
          } else if (from == 20) {
            await m.createTable(emb);
          } else if (from == 21) {
            await m.createTable(emblclt);
          } else if (from == 22) {
            await m.createTable(fstocks);
          } else if (from == 23) {
            await m.createTable(mp);
          } else if (from == 24) {
            await m.createTable(prod);
          } else if (from == 25) {
            await m.createTable(pv);
          } else if (from == 26) {
            await m.createTable(retachats);
          } else if (from == 27) {
            await m.createTable(retdetachats);
          } else if (from == 28) {
            await m.createTable(retdeventes);
          } else if (from == 29) {
            await m.createTable(retventes);
          } else if (from == 30) {
            await m.createTable(sintrant);
          } else if (from == 31) {
            await m.createTable(sproduit);
          } else if (from == 32) {
            await m.createTable(tblunit);
          } else if (from == 33) {
            await m.createTable(transf);
          } else if (from == 34) {
            await m.createTable(tribanque);
          } else if (from == 35) {
            await m.createTable(tricaisse);
          } else if (from == 36) {
            // Recréer la table depart sans contrainte unique sur designation
            await m.deleteTable('depart');
            await m.createTable(depart);
          } else if (from == 37) {
            // Recréer la table depart avec clé primaire composite
            await m.deleteTable('depart');
            await m.createTable(depart);
          } else if (from == 38) {
            // Forcer la recréation de la table depart avec clé primaire composite
            await m.deleteTable('depart');
            await m.createTable(depart);
          } else if (from == 39) {
            // Ajouter les colonnes montantRecu et monnaieARendre à la table ventes
            await m.addColumn(ventes, ventes.montantRecu as GeneratedColumn);
            await m.addColumn(ventes, ventes.monnaieARendre as GeneratedColumn);
          } else if (from == 40) {
            // Ajouter la table Users pour l'authentification
            await m.createTable(users);
          } else if (from == 41) {
            // Modifier la table Users pour utiliser username au lieu d'email
            await m.deleteTable('users');
            await m.createTable(users);
          } else if (from == 42) {
            // Ajouter la colonne diff_prix à la table detventes
            await m.addColumn(detventes, detventes.diffPrix as GeneratedColumn);
          }
        },
      );

  // ========== MÉTHODES SOCIÉTÉ ==========
  /// Récupère toutes les informations de société
  Future<List<SocData>> getAllSoc() => select(soc).get();

  /// Récupère une société par sa référence
  Future<SocData?> getSocByRef(String ref) =>
      (select(soc)..where((tbl) => tbl.ref.equals(ref))).getSingleOrNull();

  /// Insère une nouvelle société
  Future<int> insertSoc(SocCompanion entry) => into(soc).insert(entry);

  /// Met à jour une société existante
  Future<bool> updateSoc(SocCompanion entry) => update(soc).replace(entry);

  /// Supprime une société par référence
  Future<int> deleteSoc(String ref) => (delete(soc)..where((tbl) => tbl.ref.equals(ref))).go();

  // ========== MÉTHODES DÉPÔTS ==========
  /// Récupère tous les dépôts
  Future<List<Depot>> getAllDepots() => select(depots).get();

  /// Récupère un dépôt par nom
  Future<Depot?> getDepotByName(String name) =>
      (select(depots)..where((tbl) => tbl.depots.equals(name))).getSingleOrNull();

  /// Insère un nouveau dépôt
  Future<int> insertDepot(DepotsCompanion entry) => into(depots).insert(entry);

  /// Met à jour un dépôt existant
  Future<bool> updateDepot(DepotsCompanion entry) => update(depots).replace(entry);

  /// Supprime un dépôt par nom
  Future<int> deleteDepot(String name) => (delete(depots)..where((tbl) => tbl.depots.equals(name))).go();

  // ========== MÉTHODES ARTICLES ==========
  /// Récupère tous les articles
  Future<List<Article>> getAllArticles() => select(articles).get();

  /// Récupère un article par désignation
  Future<Article?> getArticleByDesignation(String designation) =>
      (select(articles)..where((tbl) => tbl.designation.equals(designation))).getSingleOrNull();

  /// Insère un nouvel article
  Future<int> insertArticle(ArticlesCompanion entry) => into(articles).insert(entry);

  /// Met à jour un article existant
  Future<bool> updateArticle(ArticlesCompanion entry) => update(articles).replace(entry);

  /// Supprime un article par désignation
  Future<int> deleteArticle(String designation) =>
      (delete(articles)..where((tbl) => tbl.designation.equals(designation))).go();

  // ========== MÉTHODES CLIENTS ==========
  /// Récupère tous les clients
  Future<List<CltData>> getAllClients() => select(clt).get();

  /// Récupère un client par raison sociale
  Future<CltData?> getClientByRsoc(String rsoc) =>
      (select(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).getSingleOrNull();

  /// Insère un nouveau client
  Future<int> insertClient(CltCompanion entry) => into(clt).insert(entry);

  /// Met à jour un client existant
  Future<int> updateClient(String rsoc, CltCompanion entry) =>
      (update(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).write(entry);

  /// Supprime un client par raison sociale
  Future<int> deleteClient(String rsoc) => (delete(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).go();

  // ========== MÉTHODES FOURNISSEURS ==========
  /// Récupère tous les fournisseurs
  Future<List<Frn>> getAllFournisseurs() => select(frns).get();

  /// Récupère un fournisseur par raison sociale
  Future<Frn?> getFournisseurByRsoc(String rsoc) =>
      (select(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).getSingleOrNull();

  /// Insère un nouveau fournisseur
  Future<int> insertFournisseur(FrnsCompanion entry) => into(frns).insert(entry);

  /// Met à jour un fournisseur existant
  Future<int> updateFournisseur(String rsoc, FrnsCompanion entry) =>
      (update(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).write(entry);

  /// Supprime un fournisseur par raison sociale
  Future<int> deleteFournisseur(String rsoc) => (delete(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).go();

  // ========== MÉTHODES COMMERCIAUX ==========
  /// Récupère tous les commerciaux
  Future<List<ComData>> getAllCommerciaux() => select(com).get();

  /// Récupère un commercial par nom
  Future<ComData?> getCommercialByNom(String nom) =>
      (select(com)..where((tbl) => tbl.nom.equals(nom))).getSingleOrNull();

  /// Insère un nouveau commercial
  Future<int> insertCommercial(ComCompanion entry) => into(com).insert(entry);

  /// Met à jour un commercial existant
  Future<bool> updateCommercial(ComCompanion entry) => update(com).replace(entry);

  /// Supprime un commercial par nom
  Future<int> deleteCommercial(String nom) => (delete(com)..where((tbl) => tbl.nom.equals(nom))).go();

  // ========== MÉTHODES VENTES ==========
  /// Récupère toutes les ventes
  Future<List<Vente>> getAllVentes() => select(ventes).get();

  /// Insère une nouvelle vente
  Future<int> insertVente(VentesCompanion entry) => into(ventes).insert(entry);

  /// Met à jour une vente existante
  Future<bool> updateVente(VentesCompanion entry) => update(ventes).replace(entry);

  /// Supprime une vente par numéro
  Future<int> deleteVente(int num) => (delete(ventes)..where((tbl) => tbl.num.equals(num))).go();

  // ========== MÉTHODES ACHATS ==========
  /// Récupère tous les achats
  Future<List<Achat>> getAllAchats() => select(achats).get();

  /// Insère un nouvel achat
  Future<int> insertAchat(AchatsCompanion entry) => into(achats).insert(entry);

  /// Met à jour un achat existant
  Future<bool> updateAchat(AchatsCompanion entry) => update(achats).replace(entry);

  /// Supprime un achat par numéro
  Future<int> deleteAchat(int num) => (delete(achats)..where((tbl) => tbl.num.equals(num))).go();

  // ========== MÉTHODES STOCKS ==========
  /// Récupère tous les mouvements de stock
  Future<List<Stock>> getAllStocks() => select(stocks).get();

  /// Récupère les stocks d'un article spécifique
  Future<List<Stock>> getStocksByArticle(String refart) =>
      (select(stocks)..where((tbl) => tbl.refart.equals(refart))).get();

  /// Récupère les stocks d'un dépôt spécifique
  Future<List<Stock>> getStocksByDepot(String depot) =>
      (select(stocks)..where((tbl) => tbl.depots.equals(depot))).get();

  /// Insère un nouveau mouvement de stock
  Future<int> insertStock(StocksCompanion entry) => into(stocks).insert(entry);

  /// Met à jour un mouvement de stock existant
  Future<bool> updateStock(StocksCompanion entry) => update(stocks).replace(entry);

  /// Supprime un mouvement de stock par référence
  Future<int> deleteStock(String ref) => (delete(stocks)..where((tbl) => tbl.ref.equals(ref))).go();

  // ========== MÉTHODES AUTRES COMPTES ==========
  /// Récupère tous les autres comptes
  Future<List<AutrescompteData>> getAllAutrescomptes() => select(autrescompte).get();

  /// Insère un nouveau compte
  Future<int> insertAutrescompte(AutrescompteCompanion entry) => into(autrescompte).insert(entry);

  /// Met à jour un compte existant
  Future<bool> updateAutrescompte(AutrescompteCompanion entry) => update(autrescompte).replace(entry);

  /// Supprime un compte par référence
  Future<int> deleteAutrescompte(String ref) =>
      (delete(autrescompte)..where((tbl) => tbl.ref.equals(ref))).go();

  // ========== MÉTHODES BANQUE ==========
  /// Récupère toutes les opérations bancaires
  Future<List<BanqueData>> getAllBanques() => select(banque).get();

  /// Insère une nouvelle opération bancaire
  Future<int> insertBanque(BanqueCompanion entry) => into(banque).insert(entry);

  /// Met à jour une opération bancaire existante
  Future<bool> updateBanque(BanqueCompanion entry) => update(banque).replace(entry);

  /// Supprime une opération bancaire par référence
  Future<int> deleteBanque(String ref) => (delete(banque)..where((tbl) => tbl.ref.equals(ref))).go();

  // ========== MÉTHODES BON DE LIVRAISON ==========
  /// Récupère tous les bons de livraison clients
  Future<List<BlcltData>> getAllBlclts() => select(blclt).get();

  /// Insère un nouveau bon de livraison
  Future<int> insertBlclt(BlcltCompanion entry) => into(blclt).insert(entry);

  /// Met à jour un bon de livraison existant
  Future<bool> updateBlclt(BlcltCompanion entry) => update(blclt).replace(entry);

  /// Supprime un bon de livraison par numéro
  Future<int> deleteBlclt(int num) => (delete(blclt)..where((tbl) => tbl.num.equals(num))).go();

  // ========== MÉTHODES BANQUES CONFIGURÉES ==========
  /// Récupère toutes les banques configurées
  Future<List<BqData>> getAllBqs() => select(bq).get();

  /// Insère une nouvelle banque configurée
  Future<int> insertBq(BqCompanion entry) => into(bq).insert(entry);

  /// Met à jour une banque configurée existante
  Future<bool> updateBq(BqCompanion entry) => update(bq).replace(entry);

  /// Supprime une banque configurée par code
  Future<int> deleteBq(String code) => (delete(bq)..where((tbl) => tbl.code.equals(code))).go();

  // ========== MÉTHODES COMPTES AUXILIAIRES ==========
  /// Récupère tous les comptes auxiliaires
  Future<List<CaData>> getAllCas() => select(ca).get();

  /// Insère un nouveau compte auxiliaire
  Future<int> insertCa(CaCompanion entry) => into(ca).insert(entry);

  /// Met à jour un compte auxiliaire existant
  Future<bool> updateCa(CaCompanion entry) => update(ca).replace(entry);

  /// Supprime un compte auxiliaire par code
  Future<int> deleteCa(String code) => (delete(ca)..where((tbl) => tbl.code.equals(code))).go();

  // ========== AUTRES MÉTHODES ==========

  /// Récupère toutes les opérations de caisse
  Future<List<CaisseData>> getAllCaisses() => select(caisse).get();

  /// Récupère tous les chéquiers
  Future<List<ChequierData>> getAllChequiers() => select(chequier).get();

  /// Récupère tous les comptes clients
  Future<List<ComptecltData>> getAllCompteclts() => select(compteclt).get();

  /// Récupère tous les comptes commerciaux
  Future<List<ComptecomData>> getAllComptecoms() => select(comptecom).get();

  /// Récupère tous les comptes fournisseurs
  Future<List<Comptefrn>> getAllComptefrns() => select(comptefrns).get();

  /// Insère un nouveau compte client
  Future<int> insertCompteclt(ComptecltCompanion entry) => into(compteclt).insert(entry);

  /// Insère un nouveau compte fournisseur
  Future<int> insertComptefrns(ComptefrnsCompanion entry) => into(comptefrns).insert(entry);

  // ========== MÉTHODES SPÉCIALISÉES VENTES ==========

  /// Enregistre une vente complète avec détails et mise à jour des stocks
  Future<void> enregistrerVenteComplete({
    required VentesCompanion vente,
    required List<Map<String, dynamic>> lignesVente,
  }) async {
    await transaction(() async {
      // 1. Insérer la vente principale
      await into(ventes).insert(vente);

      // 2. Insérer les détails de vente
      for (var ligne in lignesVente) {
        final detailCompanion = DetventesCompanion(
          numventes: vente.numventes,
          designation: Value(ligne['designation']),
          unites: Value(ligne['unites']),
          q: Value(ligne['quantite']),
          pu: Value(ligne['prixUnitaire']),
          daty: vente.daty,
          depots: Value(ligne['depot']),
        );
        await into(detventes).insert(detailCompanion);

        // 3. Mettre à jour les stocks
        await _mettreAJourStocksVente(
          ligne['designation'],
          ligne['depot'],
          ligne['unites'],
          ligne['quantite'],
          ligne['article'],
          vente.numventes.value ?? '',
        );
      }

      // 4. Mettre à jour le solde client si nécessaire
      if (vente.clt.present && vente.totalttc.present && vente.avance.present) {
        await _mettreAJourSoldeClient(
          vente.clt.value!,
          vente.totalttc.value! - (vente.avance.value ?? 0),
        );
      }
    });
  }

  /// Met à jour les stocks après une vente
  Future<void> _mettreAJourStocksVente(
    String designation,
    String depot,
    String unite,
    double quantite,
    Article article,
    String numVente,
  ) async {
    // 1. Mettre à jour le stock par dépôt (table depart)
    final stockDepart = await customSelect(
      'SELECT * FROM depart WHERE designation = ? AND depots = ?',
      variables: [Variable(designation), Variable(depot)]
    ).getSingleOrNull();

    // Convertir la quantité vendue selon l'unité
    double quantiteU1 = 0, quantiteU2 = 0;

    if (unite == article.u1) {
      quantiteU1 = quantite;
    } else if (unite == article.u2 && article.tu2u1 != null) {
      quantiteU1 = quantite / article.tu2u1!;
      quantiteU2 = quantite;
    } else if (unite == article.u2) {
      quantiteU2 = quantite;
    }

    if (stockDepart != null) {
      // Déduire du stock du dépôt
      final stockU1Actuel = stockDepart.read<double?>('stocksu1') ?? 0;
      final stockU2Actuel = stockDepart.read<double?>('stocksu2') ?? 0;
      
      await customStatement(
        'UPDATE depart SET stocksu1 = ?, stocksu2 = ? WHERE designation = ? AND depots = ?',
        [stockU1Actuel - quantiteU1, stockU2Actuel - quantiteU2, designation, depot]
      );
    }

    // 2. Mettre à jour le stock global (table articles)
    final stockGlobalU1 = (article.stocksu1 ?? 0) - quantiteU1;
    final stockGlobalU2 = (article.stocksu2 ?? 0) - quantiteU2;
    
    await customStatement(
      'UPDATE articles SET stocksu1 = ?, stocksu2 = ? WHERE designation = ?',
      [stockGlobalU1, stockGlobalU2, designation]
    );

    // 3. Créer un mouvement de stock dans la table stocks
    await _creerMouvementStock(
      designation: designation,
      depot: depot,
      unite: unite,
      quantiteSortie: quantite,
      type: 'VENTE',
      numVente: numVente,
    );
  }

  /// Met à jour le solde d'un client
  Future<void> _mettreAJourSoldeClient(String rsocClient, double montant) async {
    final client = await getClientByRsoc(rsocClient);
    if (client != null) {
      final nouveauSolde = (client.soldes ?? 0) + montant;
      await customStatement(
        'UPDATE clt SET soldes = ?, datedernop = ? WHERE rsoc = ?',
        [nouveauSolde, DateTime.now().toIso8601String(), rsocClient]
      );
      
      // Créer un mouvement dans compteclt
      final ref = 'CLT${DateTime.now().millisecondsSinceEpoch}';
      await customStatement(
        '''INSERT INTO compteclt (ref, daty, lib, entres, sorties, solde, clt)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          ref,
          DateTime.now().toIso8601String(),
          'Vente à crédit',
          montant > 0 ? montant : 0,
          montant < 0 ? -montant : 0,
          nouveauSolde,
          rsocClient
        ]
      );
    }
  }

  /// Crée un mouvement de stock
  Future<void> _creerMouvementStock({
    required String designation,
    required String depot,
    required String unite,
    double? quantiteEntree,
    double? quantiteSortie,
    required String type,
    String? numVente,
    String? numAchat,
  }) async {
    final ref = 'MVT${DateTime.now().millisecondsSinceEpoch}';

    await customStatement(
      '''INSERT INTO stocks (ref, daty, lib, refart, qe, qs, entres, sortie, ue, us, depots, numventes, numachats, verification)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        ref,
        DateTime.now().toIso8601String(),
        '$type - $designation',
        designation,
        quantiteEntree ?? 0,
        quantiteSortie ?? 0,
        quantiteEntree ?? 0,
        quantiteSortie ?? 0,
        unite,
        unite,
        depot,
        numVente,
        numAchat,
        type
      ]
    );
  }

  // ========== MÉTHODES SPÉCIALISÉES STOCKS ==========

  /// Récupère le stock détaillé d'un article par dépôt
  Future<Map<String, Map<String, double>>> getStockDetailleArticle(String designation) async {
    final stocksDepart = await (select(depart)..where((d) => d.designation.equals(designation))).get();

    Map<String, Map<String, double>> result = {};

    for (var stock in stocksDepart) {
      result[stock.depots] = {
        'u1': stock.stocksu1 ?? 0,
        'u2': stock.stocksu2 ?? 0,
        'u3': stock.stocksu3 ?? 0,
      };
    }

    return result;
  }

  /// Initialise le stock d'un article dans un dépôt
  Future<void> initialiserStockArticleDepot(String designation, String depot,
      {double? stockU1, double? stockU2, double? stockU3}) async {
    await into(depart).insertOnConflictUpdate(DepartCompanion(
      designation: Value(designation),
      depots: Value(depot),
      stocksu1: Value(stockU1 ?? 0),
      stocksu2: Value(stockU2 ?? 0),
      stocksu3: Value(stockU3 ?? 0),
    ));
  }

  // ========== MÉTHODES SPÉCIALISÉES PRIX ==========

  /// Récupère ou calcule le prix de vente d'un article
  Future<Map<String, double>> getPrixVenteArticle(String designation) async {
    // Vérifier d'abord dans la table Prix de Vente
    final prixVente = await (select(pv)..where((p) => p.designation.equals(designation))).getSingleOrNull();

    if (prixVente != null) {
      return {
        'u1': prixVente.pvu1 ?? 0,
        'u2': prixVente.pvu2 ?? 0,
        'u3': prixVente.pvu3 ?? 0,
      };
    }

    // Sinon calculer à partir du CMUP avec marge
    final article = await getArticleByDesignation(designation);
    if (article != null && article.cmup != null) {
      double cmup = article.cmup!;
      return {
        'u1': cmup * (article.tu2u1 ?? 1) * (article.tu3u2 ?? 1) * 1.2,
        'u2': cmup * (article.tu3u2 ?? 1) * 1.2,
        'u3': cmup * 1.2,
      };
    }

    return {'u1': 0, 'u2': 0, 'u3': 0};
  }

  // ========== MÉTHODES SPÉCIALISÉES RAPPORTS ==========

  /// Récupère les statistiques de vente par période
  Future<Map<String, dynamic>> getStatistiquesVentes(DateTime debut, DateTime fin) async {
    final ventesQuery = select(ventes)..where((v) => v.daty.isBetweenValues(debut, fin));

    final ventesListe = await ventesQuery.get();

    double totalHT = 0;
    double totalTTC = 0;
    int nombreVentes = ventesListe.length;

    for (var vente in ventesListe) {
      totalHT += vente.totalnt ?? 0;
      totalTTC += vente.totalttc ?? 0;
    }

    return {
      'nombreVentes': nombreVentes,
      'totalHT': totalHT,
      'totalTTC': totalTTC,
      'moyenneVente': nombreVentes > 0 ? totalTTC / nombreVentes : 0,
    };
  }

  /// Récupère le top des articles vendus
  Future<List<Map<String, dynamic>>> getTopArticlesVendus(int limite,
      {DateTime? debut, DateTime? fin}) async {
    String query = '''
      SELECT
        dv.designation,
        SUM(dv.q) as quantite_totale,
        SUM(dv.q * dv.pu) as chiffre_affaires,
        COUNT(*) as nombre_ventes
      FROM detventes dv
      JOIN ventes v ON dv.numventes = v.numventes
    ''';

    final params = <dynamic>[];
    if (debut != null && fin != null) {
      query += ' WHERE v.daty BETWEEN ? AND ?';
      params.addAll([debut.toIso8601String(), fin.toIso8601String()]);
    }

    query += '''
      GROUP BY dv.designation
      ORDER BY chiffre_affaires DESC
      LIMIT ?
    ''';
    params.add(limite);

    final result = await customSelect(query, variables: params.map((p) => Variable(p)).toList()).get();

    return result
        .map((row) => {
              'designation': row.read<String>('designation'),
              'quantite_totale': row.read<double>('quantite_totale'),
              'chiffre_affaires': row.read<double>('chiffre_affaires'),
              'nombre_ventes': row.read<int>('nombre_ventes'),
            })
        .toList();
  }

  /// Calcule le solde d'un client basé sur les ventes, retours et mouvements de compte
  Future<double> calculerSoldeClient(String rsocClient) async {
    const query = '''
      SELECT 
        COALESCE(SUM(CASE 
          WHEN v.totalttc IS NOT NULL AND v.avance IS NOT NULL 
          THEN v.totalttc - v.avance 
          ELSE 0 
        END), 0) as solde_ventes,
        COALESCE(SUM(rv.totalttc), 0) as solde_retours,
        COALESCE(SUM(cc.entres - cc.sorties), 0) as solde_compte
      FROM (SELECT ? as client) c
      LEFT JOIN ventes v ON v.clt = c.client AND v.modepai = 'A crédit'
      LEFT JOIN retventes rv ON rv.clt = c.client
      LEFT JOIN compteclt cc ON cc.clt = c.client
    ''';

    final result = await customSelect(
      query,
      variables: [Variable(rsocClient)],
    ).getSingle();

    final soldeVentes = result.read<double>('solde_ventes');
    final soldeRetours = result.read<double>('solde_retours');
    final soldeCompte = result.read<double>('solde_compte');

    return soldeVentes - soldeRetours + soldeCompte;
  }

  // ========== MÉTHODES UTILISATEURS ==========

  /// Récupère tous les utilisateurs
  Future<List<User>> getAllUsers() => select(users).get();

  /// Récupère un utilisateur par username
  Future<User?> getUserByUsername(String username) =>
      (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();

  /// Récupère un utilisateur par ID
  Future<User?> getUserById(String id) => (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// Insère un nouvel utilisateur
  Future<int> insertUser(UsersCompanion entry) => into(users).insert(entry);

  /// Met à jour un utilisateur existant
  Future<bool> updateUser(UsersCompanion entry) => update(users).replace(entry);

  /// Supprime un utilisateur par ID
  Future<int> deleteUser(String id) => (delete(users)..where((u) => u.id.equals(id))).go();

  /// Active/désactive un utilisateur
  Future<int> toggleUserStatus(String id, bool actif) =>
      (update(users)..where((u) => u.id.equals(id))).write(UsersCompanion(actif: Value(actif)));

  /// Authentifie un utilisateur
  Future<User?> authenticateUser(String username, String motDePasse) async {
    final user = await (select(users)
          ..where(
              (u) => u.username.equals(username) & u.motDePasse.equals(motDePasse) & u.actif.equals(true)))
        .getSingleOrNull();
    return user;
  }

  /// Crée l'utilisateur administrateur par défaut avec mot de passe crypté
  Future<void> createDefaultAdmin() async {
    final existingAdmin =
        await (select(users)..where((u) => u.role.equals('Administrateur'))).getSingleOrNull();

    final hashedPassword = _hashPassword('admin123');

    if (existingAdmin == null) {
      await into(users).insert(UsersCompanion(
        id: const Value('admin'),
        nom: const Value('Administrateur'),
        username: const Value('admin'),
        motDePasse: Value(hashedPassword),
        role: const Value('Administrateur'),
        actif: const Value(true),
        dateCreation: Value(DateTime.now()),
      ));
    } else if (existingAdmin.motDePasse == 'admin123') {
      // Mettre à jour l'admin existant avec mot de passe crypté
      await (update(users)..where((u) => u.id.equals(existingAdmin.id)))
          .write(UsersCompanion(motDePasse: Value(hashedPassword)));
    }

    // Initialiser les modes de paiement par défaut
    await _initializeDefaultPaymentModes();
  }

  /// Initialise les modes de paiement par défaut
  Future<void> _initializeDefaultPaymentModes() async {
    const defaultModes = ['Espèces', 'A crédit', 'Mobile Money'];

    for (final mode in defaultModes) {
      await customStatement('INSERT OR IGNORE INTO mp (mp) VALUES (?)', [mode]);
    }
  }

  /// Crypte un mot de passe avec SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ========== MÉTHODES CONTRE PASSER ==========

  /// Contre passe une vente (annulation avec remise en stock)
  Future<void> contrePasserVente(String numVentes) async {
    await transaction(() async {
      // 1. Récupérer la vente et ses détails
      final vente = await (select(ventes)..where((v) => v.numventes.equals(numVentes))).getSingleOrNull();
      if (vente == null) throw Exception('Vente introuvable');

      if (vente.verification == 'CONTRE_PASSE') {
        throw Exception('Cette vente est déjà contre passée');
      }

      final detailsVente = await (select(detventes)..where((d) => d.numventes.equals(numVentes))).get();

      // 2. Remettre les quantités en stock pour chaque ligne
      for (var detail in detailsVente) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          final article = await getArticleByDesignation(detail.designation!);
          if (article != null) {
            await _remettreStockVente(
              detail.designation!,
              detail.depots!,
              detail.unites!,
              detail.q!,
              article,
              numVentes,
            );
          }
        }
      }

      // 3. Marquer la vente comme contre passée
      await (update(ventes)..where((v) => v.numventes.equals(numVentes)))
          .write(const VentesCompanion(verification: Value('CONTRE_PASSE')));

      // 4. Ajuster le solde client si nécessaire
      if (vente.clt != null && vente.totalttc != null) {
        await _ajusterSoldeClientContrePassage(vente.clt!, vente.totalttc!);
      }
    });
  }

  /// Remet en stock les quantités d'une vente contre passée
  Future<void> _remettreStockVente(
    String designation,
    String depot,
    String unite,
    double quantite,
    Article article,
    String numVentes,
  ) async {
    // 1. Remettre le stock par dépôt (table depart)
    final stockDepart = await (select(depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockDepart != null) {
      // Convertir la quantité à remettre selon l'unité
      double quantiteU1 = 0, quantiteU2 = 0;

      if (unite == article.u1) {
        quantiteU1 = quantite;
      } else if (unite == article.u2 && article.tu2u1 != null) {
        quantiteU1 = quantite / article.tu2u1!;
        quantiteU2 = quantite;
      } else if (unite == article.u2) {
        quantiteU2 = quantite;
      }

      // Ajouter au stock du dépôt
      await (update(depart)..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: Value((stockDepart.stocksu1 ?? 0) + quantiteU1),
        stocksu2: Value((stockDepart.stocksu2 ?? 0) + quantiteU2),
      ));
    }

    // 2. Remettre le stock global (table articles)
    await (update(articles)..where((a) => a.designation.equals(designation))).write(ArticlesCompanion(
      stocksu1:
          Value((article.stocksu1 ?? 0) + (unite == article.u1 ? quantite : quantite / (article.tu2u1 ?? 1))),
      stocksu2: Value((article.stocksu2 ?? 0) + (unite == article.u2 ? quantite : 0)),
    ));

    // 3. Créer un mouvement de stock de remise
    await _creerMouvementStock(
      designation: designation,
      depot: depot,
      unite: unite,
      quantiteEntree: quantite,
      type: 'CONTRE_PASSE',
      numVente: numVentes,
    );
  }

  /// Ajuste le solde client lors d'un contre passage
  Future<void> _ajusterSoldeClientContrePassage(String rsocClient, double montantVente) async {
    final client = await getClientByRsoc(rsocClient);
    if (client != null) {
      await (update(clt)..where((c) => c.rsoc.equals(rsocClient))).write(CltCompanion(
        soldes: Value((client.soldes ?? 0) - montantVente),
        datedernop: Value(DateTime.now()),
      ));
    }
  }

  /// Vérifie si une vente peut être contre passée
  Future<Map<String, dynamic>> peutContrePasserVente(String numVentes) async {
    final vente = await (select(ventes)..where((v) => v.numventes.equals(numVentes))).getSingleOrNull();

    if (vente == null) {
      return {'possible': false, 'raison': 'Vente introuvable'};
    }

    if (vente.verification == 'CONTRE_PASSE') {
      return {'possible': false, 'raison': 'Vente déjà contre passée'};
    }

    if (vente.verification != 'Journal') {
      return {
        'possible': false,
        'raison': 'Seules les ventes validées (Journal) peuvent être contre passées'
      };
    }

    // Vérifier si la vente n'est pas trop ancienne (optionnel)
    if (vente.daty != null) {
      final daysDiff = DateTime.now().difference(vente.daty!).inDays;
      if (daysDiff > 30) {
        return {'possible': false, 'raison': 'Vente trop ancienne (plus de 30 jours)'};
      }
    }

    return {'possible': true, 'raison': 'Vente peut être contre passée'};
  }

  // ========== MÉTHODES RÉGULARISATION ==========

  /// Enregistre une régularisation de compte tiers
  Future<void> enregistrerRegularisation({
    required String type,
    required String raisonSociale,
    required DateTime date,
    required String libelle,
    required double montant,
    required String affectation,
  }) async {
    final ref = 'REG-${DateTime.now().millisecondsSinceEpoch}';

    if (type == 'Client') {
      await into(compteclt).insert(ComptecltCompanion(
        ref: Value(ref),
        daty: Value(date),
        lib: Value(libelle),
        entres: Value(affectation == 'Débit' ? montant : 0.0),
        sorties: Value(affectation == 'Crédit' ? montant : 0.0),
        clt: Value(raisonSociale),
        solde: Value(affectation == 'Débit' ? montant : -montant),
      ));
    } else {
      await into(comptefrns).insert(ComptefrnsCompanion(
        ref: Value(ref),
        daty: Value(date),
        lib: Value(libelle),
        entres: Value(affectation == 'Crédit' ? montant : 0.0),
        sortie: Value(affectation == 'Débit' ? montant : 0.0),
        frns: Value(raisonSociale),
        solde: Value(affectation == 'Crédit' ? montant : -montant),
      ));
    }
  }
}

/// Fonction de connexion à la base de données SQLite
/// Crée le fichier de base de données dans le répertoire des documents de l'application
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_magasin.db'));
    return NativeDatabase(file);
  });
}
