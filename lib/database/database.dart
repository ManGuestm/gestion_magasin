import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

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

class Depots extends Table {
  TextColumn get depots => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {depots};
}

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
}

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

class Bq extends Table {
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get intitule => text().withLength(max: 100).nullable()();
  TextColumn get nCompte => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

class Ca extends Table {
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get intitule => text().withLength(max: 100).nullable()();
  TextColumn get compte => text().withLength(max: 50).nullable()();
  RealColumn get soldes => real().nullable()();
  RealColumn get soldesa => real().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

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

class Clti extends Table {
  TextColumn get rsoc => text().withLength(min: 1, max: 100)();
  RealColumn get soldes => real().nullable()();
  RealColumn get soldes1 => real().nullable()();
  IntColumn get zanaka => integer().nullable()();

  @override
  Set<Column> get primaryKey => {rsoc};
}

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

class Depart extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get stocksu1 => real().nullable()();
  RealColumn get stocksu2 => real().nullable()();
  RealColumn get stocksu3 => real().nullable()();

  @override
  Set<Column> get primaryKey => {designation};
}

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

class Dettransf extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numtransf => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  RealColumn get q => real().nullable()();
}

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
}

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

class Mp extends Table {
  TextColumn get mp => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {mp};
}

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

class Pv extends Table {
  TextColumn get designation => text().withLength(min: 1, max: 100)();
  TextColumn get categorie => text().withLength(max: 50).nullable()();
  RealColumn get pvu1 => real().nullable()();
  RealColumn get pvu2 => real().nullable()();
  RealColumn get pvu3 => real().nullable()();

  @override
  Set<Column> get primaryKey => {designation};
}

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

class Retdetachats extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numachats => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unite => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
}

class Retdeventes extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numventes => text().withLength(max: 50).nullable()();
  TextColumn get designation => text().withLength(max: 100).nullable()();
  TextColumn get unites => text().withLength(max: 20).nullable()();
  TextColumn get depots => text().withLength(max: 50).nullable()();
  RealColumn get q => real().nullable()();
  RealColumn get pu => real().nullable()();
}

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

class Sintrant extends Table {
  TextColumn get des => text().withLength(min: 1, max: 100)();
  RealColumn get q => real().nullable()();

  @override
  Set<Column> get primaryKey => {des};
}

class Sproduit extends Table {
  TextColumn get des => text().withLength(min: 1, max: 100)();
  RealColumn get q => real().nullable()();

  @override
  Set<Column> get primaryKey => {des};
}

class Tblunit extends Table {
  TextColumn get lib => text().withLength(min: 1, max: 50)();

  @override
  Set<Column> get primaryKey => {lib};
}

class Transf extends Table {
  IntColumn get num => integer().autoIncrement()();
  TextColumn get numtransf => text().withLength(max: 50).nullable()();
  DateTimeColumn get daty => dateTime().nullable()();
  TextColumn get de => text().withLength(max: 50).nullable()();
  TextColumn get au => text().withLength(max: 50).nullable()();
  TextColumn get contre => text().withLength(max: 50).nullable()();
}

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
  Tricaisse
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 36;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
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
          }
        },
      );

  Future<List<SocData>> getAllSoc() => select(soc).get();
  Future<SocData?> getSocByRef(String ref) =>
      (select(soc)..where((tbl) => tbl.ref.equals(ref))).getSingleOrNull();
  Future<int> insertSoc(SocCompanion entry) => into(soc).insert(entry);
  Future<bool> updateSoc(SocCompanion entry) => update(soc).replace(entry);
  Future<int> deleteSoc(String ref) => (delete(soc)..where((tbl) => tbl.ref.equals(ref))).go();

  Future<List<Depot>> getAllDepots() => select(depots).get();
  Future<Depot?> getDepotByName(String name) =>
      (select(depots)..where((tbl) => tbl.depots.equals(name))).getSingleOrNull();
  Future<int> insertDepot(DepotsCompanion entry) => into(depots).insert(entry);
  Future<bool> updateDepot(DepotsCompanion entry) => update(depots).replace(entry);
  Future<int> deleteDepot(String name) => (delete(depots)..where((tbl) => tbl.depots.equals(name))).go();

  Future<List<Article>> getAllArticles() => select(articles).get();
  Future<Article?> getArticleByDesignation(String designation) =>
      (select(articles)..where((tbl) => tbl.designation.equals(designation))).getSingleOrNull();
  Future<int> insertArticle(ArticlesCompanion entry) => into(articles).insert(entry);
  Future<bool> updateArticle(ArticlesCompanion entry) => update(articles).replace(entry);
  Future<int> deleteArticle(String designation) =>
      (delete(articles)..where((tbl) => tbl.designation.equals(designation))).go();

  // Clients
  Future<List<CltData>> getAllClients() => select(clt).get();
  Future<CltData?> getClientByRsoc(String rsoc) =>
      (select(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).getSingleOrNull();
  Future<int> insertClient(CltCompanion entry) => into(clt).insert(entry);
  Future<int> updateClient(String rsoc, CltCompanion entry) => 
      (update(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).write(entry);
  Future<int> deleteClient(String rsoc) => (delete(clt)..where((tbl) => tbl.rsoc.equals(rsoc))).go();

  // Fournisseurs
  Future<List<Frn>> getAllFournisseurs() => select(frns).get();
  Future<Frn?> getFournisseurByRsoc(String rsoc) =>
      (select(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).getSingleOrNull();
  Future<int> insertFournisseur(FrnsCompanion entry) => into(frns).insert(entry);
  Future<int> updateFournisseur(String rsoc, FrnsCompanion entry) => 
      (update(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).write(entry);
  Future<int> deleteFournisseur(String rsoc) => (delete(frns)..where((tbl) => tbl.rsoc.equals(rsoc))).go();

  // Commerciaux
  Future<List<ComData>> getAllCommerciaux() => select(com).get();
  Future<ComData?> getCommercialByNom(String nom) =>
      (select(com)..where((tbl) => tbl.nom.equals(nom))).getSingleOrNull();
  Future<int> insertCommercial(ComCompanion entry) => into(com).insert(entry);
  Future<bool> updateCommercial(ComCompanion entry) => update(com).replace(entry);
  Future<int> deleteCommercial(String nom) => (delete(com)..where((tbl) => tbl.nom.equals(nom))).go();

  // Ventes
  Future<List<Vente>> getAllVentes() => select(ventes).get();
  Future<int> insertVente(VentesCompanion entry) => into(ventes).insert(entry);
  Future<bool> updateVente(VentesCompanion entry) => update(ventes).replace(entry);
  Future<int> deleteVente(int num) => (delete(ventes)..where((tbl) => tbl.num.equals(num))).go();

  // Achats
  Future<List<Achat>> getAllAchats() => select(achats).get();
  Future<int> insertAchat(AchatsCompanion entry) => into(achats).insert(entry);
  Future<bool> updateAchat(AchatsCompanion entry) => update(achats).replace(entry);
  Future<int> deleteAchat(int num) => (delete(achats)..where((tbl) => tbl.num.equals(num))).go();

  // Stocks
  Future<List<Stock>> getAllStocks() => select(stocks).get();
  Future<List<Stock>> getStocksByArticle(String refart) =>
      (select(stocks)..where((tbl) => tbl.refart.equals(refart))).get();
  Future<List<Stock>> getStocksByDepot(String depot) =>
      (select(stocks)..where((tbl) => tbl.depots.equals(depot))).get();
  Future<int> insertStock(StocksCompanion entry) => into(stocks).insert(entry);
  Future<bool> updateStock(StocksCompanion entry) => update(stocks).replace(entry);
  Future<int> deleteStock(String ref) => (delete(stocks)..where((tbl) => tbl.ref.equals(ref))).go();

  // Autres Comptes
  Future<List<AutrescompteData>> getAllAutrescomptes() => select(autrescompte).get();
  Future<int> insertAutrescompte(AutrescompteCompanion entry) => into(autrescompte).insert(entry);
  Future<bool> updateAutrescompte(AutrescompteCompanion entry) => update(autrescompte).replace(entry);
  Future<int> deleteAutrescompte(String ref) =>
      (delete(autrescompte)..where((tbl) => tbl.ref.equals(ref))).go();

  // Banque
  Future<List<BanqueData>> getAllBanques() => select(banque).get();
  Future<int> insertBanque(BanqueCompanion entry) => into(banque).insert(entry);
  Future<bool> updateBanque(BanqueCompanion entry) => update(banque).replace(entry);
  Future<int> deleteBanque(String ref) => (delete(banque)..where((tbl) => tbl.ref.equals(ref))).go();

  // BLCLT
  Future<List<BlcltData>> getAllBlclts() => select(blclt).get();
  Future<int> insertBlclt(BlcltCompanion entry) => into(blclt).insert(entry);
  Future<bool> updateBlclt(BlcltCompanion entry) => update(blclt).replace(entry);
  Future<int> deleteBlclt(int num) => (delete(blclt)..where((tbl) => tbl.num.equals(num))).go();

  // Bq
  Future<List<BqData>> getAllBqs() => select(bq).get();
  Future<int> insertBq(BqCompanion entry) => into(bq).insert(entry);
  Future<bool> updateBq(BqCompanion entry) => update(bq).replace(entry);
  Future<int> deleteBq(String code) => (delete(bq)..where((tbl) => tbl.code.equals(code))).go();

  // Ca
  Future<List<CaData>> getAllCas() => select(ca).get();
  Future<int> insertCa(CaCompanion entry) => into(ca).insert(entry);
  Future<bool> updateCa(CaCompanion entry) => update(ca).replace(entry);
  Future<int> deleteCa(String code) => (delete(ca)..where((tbl) => tbl.code.equals(code))).go();

  // Caisse
  Future<List<CaisseData>> getAllCaisses() => select(caisse).get();
  Future<int> insertCaisse(CaisseCompanion entry) => into(caisse).insert(entry);
  Future<bool> updateCaisse(CaisseCompanion entry) => update(caisse).replace(entry);
  Future<int> deleteCaisse(String ref) => (delete(caisse)..where((tbl) => tbl.ref.equals(ref))).go();

  // Chequier
  Future<List<ChequierData>> getAllChequiers() => select(chequier).get();
  Future<int> insertChequier(ChequierCompanion entry) => into(chequier).insert(entry);
  Future<bool> updateChequier(ChequierCompanion entry) => update(chequier).replace(entry);

  // CLTI
  Future<List<CltiData>> getAllCltis() => select(clti).get();
  Future<int> insertClti(CltiCompanion entry) => into(clti).insert(entry);
  Future<bool> updateClti(CltiCompanion entry) => update(clti).replace(entry);
  Future<int> deleteClti(String rsoc) => (delete(clti)..where((tbl) => tbl.rsoc.equals(rsoc))).go();

  // COMPTECLT
  Future<List<ComptecltData>> getAllCompteclts() => select(compteclt).get();
  Future<int> insertCompteclt(ComptecltCompanion entry) => into(compteclt).insert(entry);
  Future<bool> updateCompteclt(ComptecltCompanion entry) => update(compteclt).replace(entry);
  Future<int> deleteCompteclt(String ref) => (delete(compteclt)..where((tbl) => tbl.ref.equals(ref))).go();

  // COMPTECOM
  Future<List<ComptecomData>> getAllComptecoms() => select(comptecom).get();
  Future<int> insertComptecom(ComptecomCompanion entry) => into(comptecom).insert(entry);
  Future<bool> updateComptecom(ComptecomCompanion entry) => update(comptecom).replace(entry);
  Future<int> deleteComptecom(String ref) => (delete(comptecom)..where((tbl) => tbl.ref.equals(ref))).go();

  // COMPTEFRNS
  Future<List<Comptefrn>> getAllComptefrns() => select(comptefrns).get();
  Future<int> insertComptefrns(ComptefrnsCompanion entry) => into(comptefrns).insert(entry);
  Future<bool> updateComptefrns(ComptefrnsCompanion entry) => update(comptefrns).replace(entry);
  Future<int> deleteComptefrns(String ref) => (delete(comptefrns)..where((tbl) => tbl.ref.equals(ref))).go();

  // DEPART
  Future<List<DepartData>> getAllDeparts() => select(depart).get();
  Future<int> insertDepart(DepartCompanion entry) => into(depart).insert(entry);
  Future<bool> updateDepart(DepartCompanion entry) => update(depart).replace(entry);
  Future<int> deleteDepart(String designation) =>
      (delete(depart)..where((tbl) => tbl.designation.equals(designation))).go();

  // DETACHATS
  Future<List<Detachat>> getAllDetachats() => select(detachats).get();
  Future<int> insertDetachat(DetachatsCompanion entry) => into(detachats).insert(entry);
  Future<bool> updateDetachat(DetachatsCompanion entry) => update(detachats).replace(entry);
  Future<int> deleteDetachat(int num) => (delete(detachats)..where((tbl) => tbl.num.equals(num))).go();

  // DETPROD
  Future<List<DetprodData>> getAllDetprods() => select(detprod).get();
  Future<int> insertDetprod(DetprodCompanion entry) => into(detprod).insert(entry);
  Future<bool> updateDetprod(DetprodCompanion entry) => update(detprod).replace(entry);
  Future<int> deleteDetprod(int num) => (delete(detprod)..where((tbl) => tbl.num.equals(num))).go();

  // DETTRANSF
  Future<List<DettransfData>> getAllDettransfs() => select(dettransf).get();
  Future<int> insertDettransf(DettransfCompanion entry) => into(dettransf).insert(entry);
  Future<bool> updateDettransf(DettransfCompanion entry) => update(dettransf).replace(entry);
  Future<int> deleteDettransf(int num) => (delete(dettransf)..where((tbl) => tbl.num.equals(num))).go();

  // DETVENTES
  Future<List<Detvente>> getAllDetventes() => select(detventes).get();
  Future<int> insertDetvente(DetventesCompanion entry) => into(detventes).insert(entry);
  Future<bool> updateDetvente(DetventesCompanion entry) => update(detventes).replace(entry);
  Future<int> deleteDetvente(int num) => (delete(detventes)..where((tbl) => tbl.num.equals(num))).go();

  // EFFETS
  Future<List<Effet>> getAllEffets() => select(effets).get();
  Future<int> insertEffet(EffetsCompanion entry) => into(effets).insert(entry);
  Future<bool> updateEffet(EffetsCompanion entry) => update(effets).replace(entry);

  // EMB
  Future<List<EmbData>> getAllEmbs() => select(emb).get();
  Future<int> insertEmb(EmbCompanion entry) => into(emb).insert(entry);
  Future<bool> updateEmb(EmbCompanion entry) => update(emb).replace(entry);
  Future<int> deleteEmb(String designation) =>
      (delete(emb)..where((tbl) => tbl.designation.equals(designation))).go();

  // EMBLCLT
  Future<List<EmblcltData>> getAllEmblclts() => select(emblclt).get();
  Future<int> insertEmblclt(EmblcltCompanion entry) => into(emblclt).insert(entry);
  Future<bool> updateEmblclt(EmblcltCompanion entry) => update(emblclt).replace(entry);
  Future<int> deleteEmblclt(int num) => (delete(emblclt)..where((tbl) => tbl.num.equals(num))).go();

  // FSTOCKS
  Future<List<Fstock>> getAllFstocks() => select(fstocks).get();
  Future<int> insertFstock(FstocksCompanion entry) => into(fstocks).insert(entry);
  Future<bool> updateFstock(FstocksCompanion entry) => update(fstocks).replace(entry);
  Future<int> deleteFstock(String ref) => (delete(fstocks)..where((tbl) => tbl.ref.equals(ref))).go();

  // MP
  Future<List<MpData>> getAllMps() => select(mp).get();
  Future<int> insertMp(MpCompanion entry) => into(mp).insert(entry);
  Future<bool> updateMp(MpCompanion entry) => update(mp).replace(entry);
  Future<int> deleteMp(String mpValue) => (delete(mp)..where((tbl) => tbl.mp.equals(mpValue))).go();

  // PROD
  Future<List<ProdData>> getAllProds() => select(prod).get();
  Future<int> insertProd(ProdCompanion entry) => into(prod).insert(entry);
  Future<bool> updateProd(ProdCompanion entry) => update(prod).replace(entry);
  Future<int> deleteProd(int num) => (delete(prod)..where((tbl) => tbl.num.equals(num))).go();

  // PV
  Future<List<PvData>> getAllPvs() => select(pv).get();
  Future<int> insertPv(PvCompanion entry) => into(pv).insert(entry);
  Future<bool> updatePv(PvCompanion entry) => update(pv).replace(entry);
  Future<int> deletePv(String designation) =>
      (delete(pv)..where((tbl) => tbl.designation.equals(designation))).go();

  // RETACHATS
  Future<List<Retachat>> getAllRetachats() => select(retachats).get();
  Future<int> insertRetachat(RetachatsCompanion entry) => into(retachats).insert(entry);
  Future<bool> updateRetachat(RetachatsCompanion entry) => update(retachats).replace(entry);
  Future<int> deleteRetachat(int num) => (delete(retachats)..where((tbl) => tbl.num.equals(num))).go();

  // RETDETACHATS
  Future<List<Retdetachat>> getAllRetdetachats() => select(retdetachats).get();
  Future<int> insertRetdetachat(RetdetachatsCompanion entry) => into(retdetachats).insert(entry);
  Future<bool> updateRetdetachat(RetdetachatsCompanion entry) => update(retdetachats).replace(entry);
  Future<int> deleteRetdetachat(int num) => (delete(retdetachats)..where((tbl) => tbl.num.equals(num))).go();

  // RETDEVENTES
  Future<List<Retdevente>> getAllRetdeventes() => select(retdeventes).get();
  Future<int> insertRetdevente(RetdeventesCompanion entry) => into(retdeventes).insert(entry);
  Future<bool> updateRetdevente(RetdeventesCompanion entry) => update(retdeventes).replace(entry);
  Future<int> deleteRetdevente(int num) => (delete(retdeventes)..where((tbl) => tbl.num.equals(num))).go();

  // RETVENTES
  Future<List<Retvente>> getAllRetventes() => select(retventes).get();
  Future<int> insertRetvente(RetventesCompanion entry) => into(retventes).insert(entry);
  Future<bool> updateRetvente(RetventesCompanion entry) => update(retventes).replace(entry);
  Future<int> deleteRetvente(int num) => (delete(retventes)..where((tbl) => tbl.num.equals(num))).go();

  // SINTRANT
  Future<List<SintrantData>> getAllSintrants() => select(sintrant).get();
  Future<int> insertSintrant(SintrantCompanion entry) => into(sintrant).insert(entry);
  Future<bool> updateSintrant(SintrantCompanion entry) => update(sintrant).replace(entry);
  Future<int> deleteSintrant(String des) => (delete(sintrant)..where((tbl) => tbl.des.equals(des))).go();

  // SPRODUIT
  Future<List<SproduitData>> getAllSproduits() => select(sproduit).get();
  Future<int> insertSproduit(SproduitCompanion entry) => into(sproduit).insert(entry);
  Future<bool> updateSproduit(SproduitCompanion entry) => update(sproduit).replace(entry);
  Future<int> deleteSproduit(String des) => (delete(sproduit)..where((tbl) => tbl.des.equals(des))).go();

  // TBLUNIT
  Future<List<TblunitData>> getAllTblunits() => select(tblunit).get();
  Future<int> insertTblunit(TblunitCompanion entry) => into(tblunit).insert(entry);
  Future<bool> updateTblunit(TblunitCompanion entry) => update(tblunit).replace(entry);
  Future<int> deleteTblunit(String lib) => (delete(tblunit)..where((tbl) => tbl.lib.equals(lib))).go();

  // TRANSF
  Future<List<TransfData>> getAllTransfs() => select(transf).get();
  Future<int> insertTransf(TransfCompanion entry) => into(transf).insert(entry);
  Future<bool> updateTransf(TransfCompanion entry) => update(transf).replace(entry);
  Future<int> deleteTransf(int num) => (delete(transf)..where((tbl) => tbl.num.equals(num))).go();

  // TRIBANQUE
  Future<List<TribanqueData>> getAllTribanques() => select(tribanque).get();
  Future<int> insertTribanque(TribanqueCompanion entry) => into(tribanque).insert(entry);
  Future<bool> updateTribanque(TribanqueCompanion entry) => update(tribanque).replace(entry);
  Future<int> deleteTribanque(String ref) => (delete(tribanque)..where((tbl) => tbl.ref.equals(ref))).go();

  // TRICAISSE
  Future<List<TricaisseData>> getAllTricaisses() => select(tricaisse).get();
  Future<int> insertTricaisse(TricaisseCompanion entry) => into(tricaisse).insert(entry);
  Future<bool> updateTricaisse(TricaisseCompanion entry) => update(tricaisse).replace(entry);
  Future<int> deleteTricaisse(String ref) => (delete(tricaisse)..where((tbl) => tbl.ref.equals(ref))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_magasin.db'));
    return NativeDatabase(file);
  });
}
