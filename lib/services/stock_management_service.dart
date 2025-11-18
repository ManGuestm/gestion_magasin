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
        lib: Value(mouvement.libelle ?? '${_getLibelleType(mouvement.type)} - ${mouvement.refArticle}'),
        refart: Value(mouvement.refArticle),
        depots: Value(mouvement.depot),
        cmup: Value(cmup),
        clt: Value(mouvement.client),
        frns: Value(mouvement.fournisseur),
        ue: Value(mouvement.uniteEntree),
        us: Value(mouvement.uniteSortie),
        numachats: Value(mouvement.type == TypeMouvement.entree ? mouvement.numeroDocument : null),
        numventes: Value(mouvement.type == TypeMouvement.sortie ? mouvement.numeroDocument : null),
        qe: Value(mouvement.type == TypeMouvement.entree ? mouvement.quantite : 0),
        entres: Value(mouvement.type == TypeMouvement.entree ? mouvement.quantite : 0),
        qs: Value(mouvement.type == TypeMouvement.sortie ? mouvement.quantite : 0),
        sortie: Value(mouvement.type == TypeMouvement.sortie ? mouvement.quantite : 0),
        pus: Value(mouvement.prixUnitaire),
        verification: Value(_getVerificationType(mouvement.type)),
      );
      
      await database.insertStock(stocksCompanion);
      
      // Mettre à jour les stocks dans depart et articles
      await _mettreAJourStockDepart(mouvement);
      await _mettreAJourStockArticle(mouvement);
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
    
    // Récupérer le stock actuel par dépôt
    final stockActuel = await database.customSelect(
      'SELECT * FROM depart WHERE designation = ? AND depots = ?',
      variables: [Variable(mouvement.refArticle), Variable(mouvement.depot)]
    ).getSingleOrNull();
    
    final nouveauStock = _calculerNouveauStock(
      stockActuel?.read<double?>('stocksu1') ?? 0, 
      mouvement
    );
    
    if (stockActuel == null) {
      // Créer nouveau stock par dépôt
      await database.customStatement(
        'INSERT INTO depart (designation, depots, stocksu1, stocksu2, stocksu3) VALUES (?, ?, ?, 0, 0)',
        [mouvement.refArticle, mouvement.depot, nouveauStock]
      );
    } else {
      // Mettre à jour stock existant
      await database.customStatement(
        'UPDATE depart SET stocksu1 = ? WHERE designation = ? AND depots = ?',
        [nouveauStock, mouvement.refArticle, mouvement.depot]
      );
    }
  }

  Future<void> _mettreAJourStockArticle(StockMovement mouvement) async {
    final database = _db.database;
    
    // Récupérer l'article
    final article = await database.getArticleByDesignation(mouvement.refArticle);
    if (article == null) return;
    
    // Calculer le nouveau stock global
    final stockActuel = article.stocksu1 ?? 0;
    final nouveauStock = _calculerNouveauStock(stockActuel, mouvement);
    
    // Calculer le nouveau CMUP si c'est une entrée
    double? nouveauCmup;
    if (mouvement.type == TypeMouvement.entree) {
      final ancienneValeur = stockActuel * (article.cmup ?? 0);
      final nouvelleValeur = mouvement.quantite * mouvement.prixUnitaire;
      final quantiteTotale = stockActuel + mouvement.quantite;
      
      if (quantiteTotale > 0) {
        nouveauCmup = (ancienneValeur + nouvelleValeur) / quantiteTotale;
      }
    }
    
    // Mettre à jour l'article
    await database.customStatement(
      'UPDATE articles SET stocksu1 = ?, cmup = ? WHERE designation = ?',
      [nouveauStock, nouveauCmup ?? article.cmup, mouvement.refArticle]
    );
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
    
    final result = await database.customSelect(
      'SELECT depots, stocksu1 FROM depart WHERE designation = ?',
      variables: [Variable(refArticle)]
    ).get();
    
    return {
      for (final row in result)
        row.read<String>('depots'): row.read<double?>('stocksu1') ?? 0
    };
  }

  Future<double> getStockDisponible(String refArticle, String depot) async {
    final database = _db.database;
    
    final result = await database.customSelect(
      'SELECT stocksu1 FROM depart WHERE designation = ? AND depots = ?',
      variables: [Variable(refArticle), Variable(depot)]
    ).getSingleOrNull();
    
    return result?.read<double?>('stocksu1') ?? 0;
  }

  Future<bool> verifierStockSuffisant(String refArticle, String depot, double quantiteDemandee) async {
    final stockDisponible = await getStockDisponible(refArticle, depot);
    return stockDisponible >= quantiteDemandee;
  }

  String _getLibelleType(TypeMouvement type) {
    switch (type) {
      case TypeMouvement.entree:
        return 'Entrée';
      case TypeMouvement.sortie:
        return 'Sortie';
      case TypeMouvement.transfert:
        return 'Transfert';
      case TypeMouvement.inventaire:
        return 'Inventaire';
    }
  }

  String _getVerificationType(TypeMouvement type) {
    switch (type) {
      case TypeMouvement.entree:
        return 'ENTREE';
      case TypeMouvement.sortie:
        return 'SORTIE';
      case TypeMouvement.transfert:
        return 'TRANSFERT';
      case TypeMouvement.inventaire:
        return 'INVENTAIRE';
    }
  }
}