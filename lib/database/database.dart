import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

@DriftDatabase(tables: [Soc])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<SocData>> getAllSoc() => select(soc).get();
  Future<SocData?> getSocByRef(String ref) => (select(soc)..where((tbl) => tbl.ref.equals(ref))).getSingleOrNull();
  Future<int> insertSoc(SocCompanion entry) => into(soc).insert(entry);
  Future<bool> updateSoc(SocCompanion entry) => update(soc).replace(entry);
  Future<int> deleteSoc(String ref) => (delete(soc)..where((tbl) => tbl.ref.equals(ref))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_magasin.db'));
    return NativeDatabase(file);
  });
}