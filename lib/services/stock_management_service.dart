import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';

enum TypeMouvement { entree, sortie, transfert, inventaire }

class StockMovement {
  final String refArticle;
  final String depot;
  final TypeMouvement type;
  final double quantite;
  final double prixUnitaire;
  final String? numeroDocument;
  final String? client;
  final String? fournisseur;
  final String? libelle;
  final String uniteEntree;
  final String uniteSortie;

  StockMovement({
    required this.refArticle,
    required this.depot,
    required this.type,
    required this.quantite,
    required this.prixUnitaire,
    this.numeroDocument,
    this.client,
    this.fournisseur,
    this.libelle,
    this.uniteEntree = 'U1',
    this.uniteSortie = 'U1',
  });
}

class StockManagementService {
  static final StockManagementService _instance = StockManagementService._internal();
  factory StockManagementService() => _instance;
  StockManagementService._internal();

  final DatabaseService _db = DatabaseService();

  Future<void> enregistrerMouvement(StockMovement mouvement) async {
    final database = _db.database;
    
    await database.transaction(() async {
      // Générer référence unique
      final ref = await _genererReference(mouvement.type);
      
      // Calculer CMUP si nécessaire
      final cmup = await _calculerCMUP(mouvement.refArticle, mouvement.depot);
      
      // Créer l'enregistrement stock
      final stocksCompanion = StocksCompanion.insert(
        ref: ref,
        daty: Value(DateTime.now()),
        lib: Value(mouvement.libelle),
        refart: Value(mouvement.refArticle),
        depots: Value(mouvement.depot),
        cmup: Value(cmup),
        clt: Value(mouvement.client),
        frns: Value(mouvement.fournisseur),
        ue: Value(mouvement.uniteEntree),
        us: Value(mouvement.uniteSortie),
        numachats: Value(mouvement.type == TypeMouvement.entree ? mouvement.numeroDocument : null),
        numventes: Value(mouvement.type == TypeMouvement.sortie ? mouvement.numeroDocument : null),
        nfact: Value(mouvement.numeroDocument),
        qe: Value(mouvement.type == TypeMouvement.entree ? mouvement.quantite : null),
        entres: Value(mouvement.type == TypeMouvement.entree ? mouvement.quantite : null),
        qs: Value(mouvement.type == TypeMouvement.sortie ? mouvement.quantite : null),
        sortie: Value(mouvement.type == TypeMouvement.sortie ? mouvement.quantite : null),
        pus: Value(mouvement.prixUnitaire),
        verification: const Value('AUTO'),
      );
      
      await database.into(database.stocks).insert(stocksCompanion);
      
      // Mettre à jour les stocks dans depart
      await _mettreAJourStockDepart(mouvement);
    });
  }

  Future<String> _genererReference(TypeMouvement type) async {
    final prefix = _getPrefixeType(type);
    final database = _db.database;
    
    final count = await (database.selectOnly(database.stocks)
      ..addColumns([database.stocks.ref.count()])
      ..where(database.stocks.ref.like('$prefix%')))
      .getSingle();
    
    final numero = (count.read(database.stocks.ref.count()) ?? 0) + 1;
    return '$prefix${numero.toString().padLeft(6, '0')}';
  }

  String _getPrefixeType(TypeMouvement type) {
    switch (type) {
      case TypeMouvement.entree:
        return 'ENT';
      case TypeMouvement.sortie:
        return 'SOR';
      case TypeMouvement.transfert:
        return 'TRF';
      case TypeMouvement.inventaire:
        return 'INV';
    }
  }

  Future<double> _calculerCMUP(String refArticle, String depot) async {
    final database = _db.database;
    
    // Récupérer les entrées pour calculer le CMUP
    final entrees = await (database.select(database.stocks)
      ..where((s) => s.refart.equals(refArticle) & s.depots.equals(depot) & s.qe.isNotNull())
      ..orderBy([(s) => OrderingTerm.asc(s.daty)]))
      .get();
    
    if (entrees.isEmpty) return 0.0;
    
    double totalQuantite = 0;
    double totalValeur = 0;
    
    for (final entree in entrees) {
      final qte = entree.qe ?? 0;
      final prix = entree.pus ?? 0;
      totalQuantite += qte;
      totalValeur += qte * prix;
    }
    
    return totalQuantite > 0 ? totalValeur / totalQuantite : 0.0;
  }

  Future<void> _mettreAJourStockDepart(StockMovement mouvement) async {
    final database = _db.database;
    
    // Récupérer le stock actuel
    final stockActuel = await (database.select(database.depart)
      ..where((d) => d.designation.equals(mouvement.refArticle) & d.depots.equals(mouvement.depot)))
      .getSingleOrNull();
    
    if (stockActuel == null) {
      // Créer nouveau stock
      await database.into(database.depart).insert(DepartCompanion.insert(
        designation: mouvement.refArticle,
        depots: mouvement.depot,
        stocksu1: Value(_calculerNouveauStock(0, mouvement)),
        stocksu2: const Value(0),
        stocksu3: const Value(0),
      ));
    } else {
      // Mettre à jour stock existant
      final nouveauStock = _calculerNouveauStock(stockActuel.stocksu1 ?? 0, mouvement);
      
      await (database.update(database.depart)
        ..where((d) => d.designation.equals(mouvement.refArticle) & d.depots.equals(mouvement.depot)))
        .write(DepartCompanion(
          stocksu1: Value(nouveauStock),
        ));
    }
  }

  double _calculerNouveauStock(double stockActuel, StockMovement mouvement) {
    switch (mouvement.type) {
      case TypeMouvement.entree:
        return stockActuel + mouvement.quantite;
      case TypeMouvement.sortie:
        return stockActuel - mouvement.quantite;
      case TypeMouvement.transfert:
        return stockActuel - mouvement.quantite; // Pour le dépôt source
      case TypeMouvement.inventaire:
        return mouvement.quantite; // Remplace le stock
    }
  }

  Future<List<Stock>> getHistoriqueStock(String refArticle, [String? depot]) async {
    final database = _db.database;
    
    final query = database.select(database.stocks)
      ..where((s) => s.refart.equals(refArticle))
      ..orderBy([(s) => OrderingTerm.desc(s.daty)]);
    
    if (depot != null) {
      query.where((s) => s.depots.equals(depot));
    }
    
    return await query.get();
  }

  Future<Map<String, double>> getStockParDepot(String refArticle) async {
    final database = _db.database;
    
    final stocks = await (database.select(database.depart)
      ..where((d) => d.designation.equals(refArticle)))
      .get();
    
    return {
      for (final stock in stocks)
        stock.depots: stock.stocksu1 ?? 0
    };
  }

  Future<double> getStockDisponible(String refArticle, String depot) async {
    final database = _db.database;
    
    final stock = await (database.select(database.depart)
      ..where((d) => d.designation.equals(refArticle) & d.depots.equals(depot)))
      .getSingleOrNull();
    
    return stock?.stocksu1 ?? 0;
  }

  Future<bool> verifierStockSuffisant(String refArticle, String depot, double quantiteDemandee) async {
    final stockDisponible = await getStockDisponible(refArticle, depot);
    return stockDisponible >= quantiteDemandee;
  }
}