import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import 'prix_service.dart';
import 'rapport_service.dart';
import 'stock_service.dart';

/// Service principal orchestrant toutes les opérations métier
class BusinessService {
  static final BusinessService _instance = BusinessService._internal();
  factory BusinessService() => _instance;
  BusinessService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final StockService _stockService = StockService();
  final RapportService _rapportService = RapportService();
  final PrixService _prixService = PrixService();

  // Getters pour accéder aux services spécialisés
  StockService get stock => _stockService;
  RapportService get rapport => _rapportService;
  PrixService get prix => _prixService;
  DatabaseService get database => _databaseService;

  /// Initialise un nouvel article avec tous ses paramètres
  Future<void> creerArticleComplet({
    required String designation,
    String? u1,
    String? u2,
    String? u3,
    double? tu2u1,
    double? tu3u2,
    double? cmup,
    String? categorie,
    String? classification,
    Map<String, double>? stocksInitiaux,
    Map<String, double>? prixVente,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Créer l'article
      final articleCompanion = ArticlesCompanion(
        designation: Value(designation),
        u1: u1 != null ? Value(u1) : const Value.absent(),
        u2: u2 != null ? Value(u2) : const Value.absent(),
        u3: u3 != null ? Value(u3) : const Value.absent(),
        tu2u1: tu2u1 != null ? Value(tu2u1) : const Value.absent(),
        tu3u2: tu3u2 != null ? Value(tu3u2) : const Value.absent(),
        cmup: cmup != null ? Value(cmup) : const Value.absent(),
        categorie: categorie != null ? Value(categorie) : const Value.absent(),
        classification: classification != null ? Value(classification) : const Value.absent(),
        stocksu1: Value(stocksInitiaux?['u1'] ?? 0),
        stocksu2: Value(stocksInitiaux?['u2'] ?? 0),
        stocksu3: Value(stocksInitiaux?['u3'] ?? 0),
      );

      await _databaseService.database.insertArticle(articleCompanion);

      // 2. Initialiser les stocks dans tous les dépôts
      final article = await _databaseService.database.getArticleByDesignation(designation);
      if (article != null) {
        await _stockService.initialiserStocksNouvelArticle(article);
      }

      // 3. Configurer les prix de vente si fournis
      if (prixVente != null) {
        await _prixService.mettreAJourPrixVente(
          designation: designation,
          categorie: categorie,
          prixU1: prixVente['u1'],
          prixU2: prixVente['u2'],
          prixU3: prixVente['u3'],
        );
      } else if (cmup != null && article != null) {
        // Calculer automatiquement les prix
        final prixCalcules = await _prixService.calculerPrixAutomatiques(article: article);
        await _prixService.mettreAJourPrixVente(
          designation: designation,
          categorie: categorie,
          prixU1: prixCalcules['u1'],
          prixU2: prixCalcules['u2'],
          prixU3: prixCalcules['u3'],
        );
      }
    });
  }

  /// Effectue une réception de marchandises complète
  Future<void> effectuerReceptionMarchandises({
    required String numAchat,
    required String fournisseur,
    required List<Map<String, dynamic>> lignesReception,
    String? nFacture,
    DateTime? dateReception,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Créer l'achat principal
      final achatCompanion = AchatsCompanion(
        numachats: Value(numAchat),
        nfact: nFacture != null ? Value(nFacture) : const Value.absent(),
        daty: Value(dateReception ?? DateTime.now()),
        frns: Value(fournisseur),
        verification: const Value('Réceptionné'),
      );

      await _databaseService.database.insertAchat(achatCompanion);

      // 2. Traiter chaque ligne de réception
      for (var ligne in lignesReception) {
        String designation = ligne['designation'];
        String depot = ligne['depot'] ?? 'MAG';
        String unite = ligne['unite'];
        double quantite = ligne['quantite'];
        double prixUnitaire = ligne['prixUnitaire'];

        // Créer le détail d'achat
        final detailCompanion = DetachatsCompanion(
          numachats: Value(numAchat),
          designation: Value(designation),
          unites: Value(unite),
          depots: Value(depot),
          q: Value(quantite),
          pu: Value(prixUnitaire),
          daty: Value(dateReception ?? DateTime.now()),
        );

        await _databaseService.database.into(_databaseService.database.detachats).insert(detailCompanion);

        // Mettre à jour les stocks
        await _mettreAJourStocksReception(designation, depot, unite, quantite, prixUnitaire);
      }
    });
  }

  /// Met à jour les stocks lors d'une réception
  Future<void> _mettreAJourStocksReception(
    String designation,
    String depot,
    String unite,
    double quantite,
    double prixUnitaire,
  ) async {
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    // Convertir la quantité selon l'unité
    double quantiteU1 = 0, quantiteU2 = 0, quantiteU3 = 0;

    if (unite == article.u1) {
      quantiteU1 = quantite;
    } else if (unite == article.u2) {
      quantiteU2 = quantite;
    } else if (unite == article.u3) {
      quantiteU3 = quantite;
    }

    // Mettre à jour le stock dans le dépôt
    final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockDepart != null) {
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: Value((stockDepart.stocksu1 ?? 0) + quantiteU1),
        stocksu2: Value((stockDepart.stocksu2 ?? 0) + quantiteU2),
        stocksu3: Value((stockDepart.stocksu3 ?? 0) + quantiteU3),
      ));
    } else {
      await _databaseService.database.initialiserStockArticleDepot(
        designation,
        depot,
        stockU1: quantiteU1,
        stockU2: quantiteU2,
        stockU3: quantiteU3,
      );
    }

    // Mettre à jour le stock global et recalculer le CMUP
    await _recalculerCMUP(designation, quantite, prixUnitaire, unite);
  }

  /// Recalcule le CMUP après une réception
  Future<void> _recalculerCMUP(
      String designation, double quantiteRecue, double prixUnitaire, String unite) async {
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    // Convertir tout en unité de base (u3) pour le calcul
    double quantiteU3Recue = quantiteRecue;
    double prixU3 = prixUnitaire;

    if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      quantiteU3Recue = quantiteRecue * article.tu2u1! * article.tu3u2!;
      prixU3 = prixUnitaire / (article.tu2u1! * article.tu3u2!);
    } else if (unite == article.u2 && article.tu3u2 != null) {
      quantiteU3Recue = quantiteRecue * article.tu3u2!;
      prixU3 = prixUnitaire / article.tu3u2!;
    }

    // Calculer le nouveau CMUP
    double stockActuelU3 = (article.stocksu3 ?? 0) +
        ((article.stocksu2 ?? 0) * (article.tu3u2 ?? 1)) +
        ((article.stocksu1 ?? 0) * (article.tu2u1 ?? 1) * (article.tu3u2 ?? 1));

    double cmupActuel = article.cmup ?? 0;
    double valeurStockActuel = stockActuelU3 * cmupActuel;
    double valeurReception = quantiteU3Recue * prixU3;

    double nouveauStock = stockActuelU3 + quantiteU3Recue;
    double nouveauCMUP = nouveauStock > 0 ? (valeurStockActuel + valeurReception) / nouveauStock : 0;

    // Mettre à jour l'article
    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .write(ArticlesCompanion(
      cmup: Value(nouveauCMUP),
      stocksu1: Value((article.stocksu1 ?? 0) + (unite == article.u1 ? quantiteRecue : 0)),
      stocksu2: Value((article.stocksu2 ?? 0) + (unite == article.u2 ? quantiteRecue : 0)),
      stocksu3: Value((article.stocksu3 ?? 0) + (unite == article.u3 ? quantiteRecue : 0)),
    ));
  }

  /// Effectue un inventaire complet
  Future<Map<String, dynamic>> effectuerInventaire({String? depot}) async {
    final articles = await _databaseService.database.getActiveArticles();

    Map<String, dynamic> resultat = {
      'totalArticles': articles.length,
      'valeurTotale': 0.0,
      'articlesEnRupture': 0,
      'details': <Map<String, dynamic>>[],
    };

    double valeurTotale = 0;
    int articlesEnRupture = 0;

    for (var article in articles) {
      final stocksDepot =
          depot != null ? await _databaseService.database.getStockDetailleArticle(article.designation) : null;

      double stockTotal = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);

      if (stockTotal <= 0) articlesEnRupture++;

      double valeurArticle = stockTotal * (article.cmup ?? 0);
      valeurTotale += valeurArticle;

      resultat['details'].add({
        'designation': article.designation,
        'stockU1': article.stocksu1 ?? 0,
        'stockU2': article.stocksu2 ?? 0,
        'stockU3': article.stocksu3 ?? 0,
        'cmup': article.cmup ?? 0,
        'valeur': valeurArticle,
        'stocksDepot': stocksDepot,
      });
    }

    resultat['valeurTotale'] = valeurTotale;
    resultat['articlesEnRupture'] = articlesEnRupture;

    return resultat;
  }

  /// Génère le tableau de bord principal
  Future<Map<String, dynamic>> genererTableauBord() async {
    final maintenant = DateTime.now();
    final debutMois = DateTime(maintenant.year, maintenant.month, 1);

    return {
      'ventesJour': await _databaseService.database.getStatistiquesVentes(
        DateTime(maintenant.year, maintenant.month, maintenant.day),
        maintenant,
      ),
      'ventesMois': await _databaseService.database.getStatistiquesVentes(debutMois, maintenant),
      'stocksCritiques': await _stockService.genererRapportStockCritique(),
      'topArticles': await _databaseService.database.getTopArticlesVendus(5),
      'tableauCommercial':
          await _rapportService.genererTableauBordCommercial(debut: debutMois, fin: maintenant),
    };
  }
}
