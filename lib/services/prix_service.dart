import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';

/// Service spécialisé pour la gestion des prix de vente
class PrixService {
  final DatabaseService _databaseService = DatabaseService();

  /// Met à jour les prix de vente d'un article
  Future<void> mettreAJourPrixVente({
    required String designation,
    String? categorie,
    double? prixU1,
    double? prixU2,
    double? prixU3,
  }) async {
    final prixExistant = await (_databaseService.database.select(_databaseService.database.pv)
          ..where((p) => p.designation.equals(designation)))
        .getSingleOrNull();

    final companion = PvCompanion(
      designation: Value(designation),
      categorie: categorie != null ? Value(categorie) : const Value.absent(),
      pvu1: prixU1 != null ? Value(prixU1) : const Value.absent(),
      pvu2: prixU2 != null ? Value(prixU2) : const Value.absent(),
      pvu3: prixU3 != null ? Value(prixU3) : const Value.absent(),
    );

    if (prixExistant != null) {
      await (_databaseService.database.update(_databaseService.database.pv)
            ..where((p) => p.designation.equals(designation)))
          .write(companion);
    } else {
      await _databaseService.database.into(_databaseService.database.pv).insert(companion);
    }
  }

  /// Calcule automatiquement les prix de vente basés sur le CMUP et les marges
  Future<Map<String, double>> calculerPrixAutomatiques({
    required Article article,
    double margeU1 = 1.2,
    double margeU2 = 1.2,
    double margeU3 = 1.2,
  }) async {
    double cmup = article.cmup ?? 0;

    if (cmup == 0) {
      return {'u1': 0, 'u2': 0, 'u3': 0};
    }

    // Calculer les prix selon les conversions
    double prixU3 = cmup * margeU3;
    double prixU2 = prixU3 * (article.tu3u2 ?? 1) * margeU2;
    double prixU1 = prixU2 * (article.tu2u1 ?? 1) * margeU1;

    return {
      'u1': prixU1,
      'u2': prixU2,
      'u3': prixU3,
    };
  }

  /// Applique une marge globale à tous les articles d'une catégorie
  Future<void> appliquerMargeCategorie({
    required String categorie,
    required double pourcentageMarge,
  }) async {
    final articles = await (_databaseService.database.select(_databaseService.database.articles)
          ..where((a) => a.categorie.equals(categorie)))
        .get();

    for (var article in articles) {
      if (article.cmup != null && article.cmup! > 0) {
        final nouveauxPrix = await calculerPrixAutomatiques(
          article: article,
          margeU1: pourcentageMarge,
          margeU2: pourcentageMarge,
          margeU3: pourcentageMarge,
        );

        await mettreAJourPrixVente(
          designation: article.designation,
          categorie: categorie,
          prixU1: nouveauxPrix['u1'],
          prixU2: nouveauxPrix['u2'],
          prixU3: nouveauxPrix['u3'],
        );
      }
    }
  }

  /// Génère une grille de prix pour un article
  Future<Map<String, dynamic>> genererGrillePrix(String designation) async {
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return {};

    final prixVente = await (_databaseService.database.select(_databaseService.database.pv)
          ..where((p) => p.designation.equals(designation)))
        .getSingleOrNull();

    // Prix de vente configurés
    Map<String, double> prixConfigures = {
      'u1': prixVente?.pvu1 ?? 0,
      'u2': prixVente?.pvu2 ?? 0,
      'u3': prixVente?.pvu3 ?? 0,
    };

    // Prix calculés automatiquement
    Map<String, double> prixCalcules = await calculerPrixAutomatiques(article: article);

    // Marges actuelles
    Map<String, double> marges = {};
    if (article.cmup != null && article.cmup! > 0) {
      double cmupU3 = article.cmup!;
      double cmupU2 = cmupU3 * (article.tu3u2 ?? 1);
      double cmupU1 = cmupU2 * (article.tu2u1 ?? 1);

      marges['u1'] = prixConfigures['u1']! > 0 ? (prixConfigures['u1']! / cmupU1 - 1) * 100 : 0;
      marges['u2'] = prixConfigures['u2']! > 0 ? (prixConfigures['u2']! / cmupU2 - 1) * 100 : 0;
      marges['u3'] = prixConfigures['u3']! > 0 ? (prixConfigures['u3']! / cmupU3 - 1) * 100 : 0;
    }

    return {
      'article': {
        'designation': article.designation,
        'cmup': article.cmup,
        'unites': {
          'u1': article.u1,
          'u2': article.u2,
          'u3': article.u3,
        },
        'conversions': {
          'tu2u1': article.tu2u1,
          'tu3u2': article.tu3u2,
        },
      },
      'prixConfigures': prixConfigures,
      'prixCalcules': prixCalcules,
      'marges': marges,
    };
  }

  /// Compare les prix avec la concurrence (simulation)
  Future<Map<String, dynamic>> comparerPrixConcurrence(String designation) async {
    final grille = await genererGrillePrix(designation);

    // Simulation de prix concurrents (à remplacer par de vraies données)
    Map<String, double> prixConcurrents = {
      'u1': (grille['prixConfigures']['u1'] as double) *
          (0.9 + (0.2 * (DateTime.now().millisecond % 100) / 100)),
      'u2': (grille['prixConfigures']['u2'] as double) *
          (0.9 + (0.2 * (DateTime.now().millisecond % 100) / 100)),
      'u3': (grille['prixConfigures']['u3'] as double) *
          (0.9 + (0.2 * (DateTime.now().millisecond % 100) / 100)),
    };

    Map<String, String> positionnement = {};
    Map<String, double> ecarts = {};

    for (var unite in ['u1', 'u2', 'u3']) {
      double prixNos = grille['prixConfigures'][unite] as double;
      double prixConcurrent = prixConcurrents[unite]!;

      ecarts[unite] = ((prixNos - prixConcurrent) / prixConcurrent) * 100;

      if (ecarts[unite]! > 10) {
        positionnement[unite] = 'CHER';
      } else if (ecarts[unite]! < -10) {
        positionnement[unite] = 'COMPÉTITIF';
      } else {
        positionnement[unite] = 'ALIGNÉ';
      }
    }

    return {
      'grillePrix': grille,
      'prixConcurrents': prixConcurrents,
      'ecarts': ecarts,
      'positionnement': positionnement,
    };
  }

  /// Suggère des ajustements de prix basés sur les ventes
  Future<Map<String, dynamic>> suggererAjustementsPrix(String designation) async {
    // Analyser les ventes des 3 derniers mois
    final finPeriode = DateTime.now();
    final debutPeriode = finPeriode.subtract(const Duration(days: 90));

    const query = '''SELECT 
        dv.unites,
        COUNT(*) as nombre_ventes,
        SUM(dv.q) as quantite_totale,
        AVG(dv.pu) as prix_moyen,
        MIN(dv.pu) as prix_min,
        MAX(dv.pu) as prix_max
      FROM detventes dv
      JOIN ventes v ON dv.numventes = v.numventes
      WHERE dv.designation = ? AND v.daty BETWEEN ? AND ?
      GROUP BY dv.unites''';

    final result = await _databaseService.database.customSelect(
      query,
      variables: [
        Variable.withString(designation),
        Variable.withDateTime(debutPeriode),
        Variable.withDateTime(finPeriode),
      ],
    ).get();

    Map<String, Map<String, dynamic>> analysesVentes = {};

    for (var row in result) {
      String unite = row.read<String>('unites');
      analysesVentes[unite] = {
        'nombreVentes': row.read<int>('nombre_ventes'),
        'quantiteTotale': row.read<double>('quantite_totale'),
        'prixMoyen': row.read<double>('prix_moyen'),
        'prixMin': row.read<double>('prix_min'),
        'prixMax': row.read<double>('prix_max'),
      };
    }

    // Générer des suggestions
    List<Map<String, dynamic>> suggestions = [];

    for (var entry in analysesVentes.entries) {
      String unite = entry.key;
      Map<String, dynamic> stats = entry.value;

      int nombreVentes = stats['nombreVentes'];
      double variationPrix = stats['prixMax'] - stats['prixMin'];

      if (nombreVentes < 5) {
        suggestions.add({
          'unite': unite,
          'type': 'BAISSE_PRIX',
          'raison': 'Faibles ventes - considérer une baisse de prix',
          'suggestion': 'Réduire de 5-10%',
        });
      } else if (variationPrix > stats['prixMoyen'] * 0.1) {
        suggestions.add({
          'unite': unite,
          'type': 'STABILISER_PRIX',
          'raison': 'Prix trop variables',
          'suggestion': 'Fixer un prix stable autour de ${stats['prixMoyen'].toStringAsFixed(0)}',
        });
      } else if (nombreVentes > 20) {
        suggestions.add({
          'unite': unite,
          'type': 'AUGMENTATION_POSSIBLE',
          'raison': 'Bonnes ventes - marge d\'augmentation possible',
          'suggestion': 'Tester une augmentation de 3-5%',
        });
      }
    }

    return {
      'periode': {'debut': debutPeriode, 'fin': finPeriode},
      'analysesVentes': analysesVentes,
      'suggestions': suggestions,
    };
  }

  /// Exporte la liste de prix au format CSV
  Future<String> exporterListePrix({String? categorie}) async {
    var query = '''SELECT 
        a.designation,
        a.categorie,
        a.cmup,
        a.u1, a.u2, a.u3,
        p.pvu1, p.pvu2, p.pvu3
      FROM articles a
      LEFT JOIN pv p ON a.designation = p.designation''';

    List<Variable> variables = [];
    if (categorie != null) {
      query += ' WHERE a.categorie = ?';
      variables.add(Variable.withString(categorie));
    }

    query += ' ORDER BY a.designation';

    final result = await _databaseService.database.customSelect(query, variables: variables).get();

    StringBuffer csv = StringBuffer();
    csv.writeln('Designation,Categorie,CMUP,Unite1,Prix1,Unite2,Prix2,Unite3,Prix3');

    for (var row in result) {
      csv.writeln([
        row.read<String>('designation'),
        row.read<String?>('categorie') ?? '',
        row.read<double?>('cmup')?.toStringAsFixed(2) ?? '0.00',
        row.read<String?>('u1') ?? '',
        row.read<double?>('pvu1')?.toStringAsFixed(2) ?? '0.00',
        row.read<String?>('u2') ?? '',
        row.read<double?>('pvu2')?.toStringAsFixed(2) ?? '0.00',
        row.read<String?>('u3') ?? '',
        row.read<double?>('pvu3')?.toStringAsFixed(2) ?? '0.00',
      ].join(','));
    }

    return csv.toString();
  }
}
