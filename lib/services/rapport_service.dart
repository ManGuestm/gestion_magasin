import 'package:drift/drift.dart';

import '../database/database_service.dart';

/// Service spécialisé pour la génération de rapports et statistiques
class RapportService {
  final DatabaseService _databaseService = DatabaseService();

  /// Génère le rapport de ventes par période
  Future<Map<String, dynamic>> genererRapportVentes({
    required DateTime debut,
    required DateTime fin,
    String? client,
    String? commercial,
  }) async {
    final stats = await _databaseService.database.getStatistiquesVentes(debut, fin);
    final topArticles = await _databaseService.database.getTopArticlesVendus(10, debut: debut, fin: fin);

    // Statistiques par client si spécifié
    Map<String, dynamic>? statsClient;
    if (client != null) {
      statsClient = await _genererStatsClient(client, debut, fin);
    }

    // Statistiques par commercial si spécifié
    Map<String, dynamic>? statsCommercial;
    if (commercial != null) {
      statsCommercial = await _genererStatsCommercial(commercial, debut, fin);
    }

    return {
      'periode': {'debut': debut, 'fin': fin},
      'statistiques': stats,
      'topArticles': topArticles,
      'client': statsClient,
      'commercial': statsCommercial,
    };
  }

  /// Génère les statistiques pour un client spécifique
  Future<Map<String, dynamic>> _genererStatsClient(String client, DateTime debut, DateTime fin) async {
    const query = '''SELECT 
        COUNT(*) as nombre_commandes,
        SUM(totalttc) as chiffre_affaires,
        AVG(totalttc) as panier_moyen,
        SUM(avance) as total_avances,
        SUM(totalttc - COALESCE(avance, 0)) as total_credit
      FROM ventes 
      WHERE clt = ? AND daty BETWEEN ? AND ?''';

    final result = await _databaseService.database.customSelect(
      query,
      variables: [
        Variable.withString(client),
        Variable.withDateTime(debut),
        Variable.withDateTime(fin),
      ],
    ).getSingle();

    return {
      'nombreCommandes': result.read<int>('nombre_commandes'),
      'chiffreAffaires': result.read<double>('chiffre_affaires'),
      'panierMoyen': result.read<double>('panier_moyen'),
      'totalAvances': result.read<double>('total_avances'),
      'totalCredit': result.read<double>('total_credit'),
    };
  }

  /// Génère les statistiques pour un commercial spécifique
  Future<Map<String, dynamic>> _genererStatsCommercial(
      String commercial, DateTime debut, DateTime fin) async {
    const query = '''SELECT 
        COUNT(*) as nombre_ventes,
        SUM(totalttc) as chiffre_affaires,
        SUM(commission) as total_commissions,
        AVG(totalttc) as vente_moyenne
      FROM ventes 
      WHERE commerc = ? AND daty BETWEEN ? AND ?''';

    final result = await _databaseService.database.customSelect(
      query,
      variables: [
        Variable.withString(commercial),
        Variable.withDateTime(debut),
        Variable.withDateTime(fin),
      ],
    ).getSingle();

    return {
      'nombreVentes': result.read<int>('nombre_ventes'),
      'chiffreAffaires': result.read<double>('chiffre_affaires'),
      'totalCommissions': result.read<double>('total_commissions'),
      'venteMoyenne': result.read<double>('vente_moyenne'),
    };
  }

  /// Génère le rapport de marges par article
  Future<List<Map<String, dynamic>>> genererRapportMarges({DateTime? debut, DateTime? fin}) async {
    var query = '''SELECT 
        dv.designation,
        a.cmup,
        AVG(dv.pu) as prix_vente_moyen,
        SUM(dv.q) as quantite_vendue,
        SUM(dv.q * dv.pu) as chiffre_affaires,
        SUM(dv.q * a.cmup) as cout_total,
        (SUM(dv.q * dv.pu) - SUM(dv.q * a.cmup)) as marge_brute,
        ((SUM(dv.q * dv.pu) - SUM(dv.q * a.cmup)) / SUM(dv.q * dv.pu) * 100) as taux_marge
      FROM detventes dv
      JOIN articles a ON dv.designation = a.designation
      JOIN ventes v ON dv.numventes = v.numventes''';

    List<Variable> variables = [];
    if (debut != null && fin != null) {
      query += ' WHERE v.daty BETWEEN ? AND ?';
      variables.addAll([Variable.withDateTime(debut), Variable.withDateTime(fin)]);
    }

    query += '''
      GROUP BY dv.designation, a.cmup
      ORDER BY marge_brute DESC''';

    final result = await _databaseService.database.customSelect(query, variables: variables).get();

    return result
        .map((row) => {
              'designation': row.read<String>('designation'),
              'cmup': row.read<double>('cmup'),
              'prixVenteMoyen': row.read<double>('prix_vente_moyen'),
              'quantiteVendue': row.read<double>('quantite_vendue'),
              'chiffreAffaires': row.read<double>('chiffre_affaires'),
              'coutTotal': row.read<double>('cout_total'),
              'margeBrute': row.read<double>('marge_brute'),
              'tauxMarge': row.read<double>('taux_marge'),
            })
        .toList();
  }

  /// Génère le rapport de rotation des stocks
  Future<List<Map<String, dynamic>>> genererRapportRotationStock({DateTime? debut, DateTime? fin}) async {
    final articles = await _databaseService.database.getActiveArticles();
    List<Map<String, dynamic>> rotations = [];

    for (var article in articles) {
      // Calculer les ventes sur la période
      var queryVentes = '''SELECT SUM(q) as quantite_vendue
        FROM detventes dv
        JOIN ventes v ON dv.numventes = v.numventes
        WHERE dv.designation = ?''';

      List<Variable> variables = [Variable.withString(article.designation)];

      if (debut != null && fin != null) {
        queryVentes += ' AND v.daty BETWEEN ? AND ?';
        variables.addAll([Variable.withDateTime(debut), Variable.withDateTime(fin)]);
      }

      final resultVentes = await _databaseService.database
          .customSelect(
            queryVentes,
            variables: variables,
          )
          .getSingle();

      double quantiteVendue = resultVentes.read<double>('quantite_vendue');

      // Calculer le stock moyen (approximation avec stock actuel)
      double stockMoyen = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);

      double rotationStock = stockMoyen > 0 ? quantiteVendue / stockMoyen : 0;

      rotations.add({
        'designation': article.designation,
        'quantiteVendue': quantiteVendue,
        'stockMoyen': stockMoyen,
        'rotationStock': rotationStock,
        'classification': _classifierRotation(rotationStock),
      });
    }

    // Trier par rotation décroissante
    rotations.sort((a, b) => (b['rotationStock'] as double).compareTo(a['rotationStock'] as double));

    return rotations;
  }

  String _classifierRotation(double rotation) {
    if (rotation >= 12) return 'RAPIDE';
    if (rotation >= 6) return 'NORMALE';
    if (rotation >= 2) return 'LENTE';
    return 'TRÈS LENTE';
  }

  /// Génère le rapport de créances clients
  Future<List<Map<String, dynamic>>> genererRapportCreances() async {
    const query = '''SELECT 
        c.rsoc,
        c.soldes,
        c.datedernop,
        c.delai,
        c.plafon,
        CASE 
          WHEN c.delai IS NOT NULL AND c.datedernop IS NOT NULL 
          THEN julianday('now') - julianday(c.datedernop) - c.delai
          ELSE 0
        END as jours_retard
      FROM clt c
      WHERE c.soldes > 0
      ORDER BY c.soldes DESC''';

    final result = await _databaseService.database.customSelect(query).get();

    return result
        .map((row) => {
              'client': row.read<String>('rsoc'),
              'solde': row.read<double>('soldes'),
              'dateDernierePaiement': row.read<DateTime?>('datedernop'),
              'delaiPaiement': row.read<int?>('delai'),
              'plafond': row.read<double?>('plafon'),
              'joursRetard': row.read<double>('jours_retard'),
              'statut': _determinerStatutCreance(
                row.read<double>('jours_retard'),
                row.read<double>('soldes'),
                row.read<double?>('plafon'),
              ),
            })
        .toList();
  }

  String _determinerStatutCreance(double joursRetard, double solde, double? plafond) {
    if (joursRetard > 90) return 'CONTENTIEUX';
    if (joursRetard > 60) return 'TRÈS EN RETARD';
    if (joursRetard > 30) return 'EN RETARD';
    if (plafond != null && solde > plafond) return 'DÉPASSEMENT PLAFOND';
    return 'NORMAL';
  }

  /// Génère le tableau de bord commercial
  Future<Map<String, dynamic>> genererTableauBordCommercial({DateTime? debut, DateTime? fin}) async {
    final statsVentes = await _databaseService.database.getStatistiquesVentes(
      debut ?? DateTime.now().subtract(const Duration(days: 30)),
      fin ?? DateTime.now(),
    );

    final topArticles = await _databaseService.database.getTopArticlesVendus(5, debut: debut, fin: fin);
    final rapportMarges = await genererRapportMarges(debut: debut, fin: fin);
    final creances = await genererRapportCreances();

    // Calculer les totaux de créances
    double totalCreances = creances.fold(0, (sum, item) => sum + (item['solde'] as double));
    int clientsEnRetard = creances.where((c) => (c['joursRetard'] as double) > 0).length;

    return {
      'ventes': statsVentes,
      'topArticles': topArticles.take(5).toList(),
      'marges': {
        'margeMoyenne': rapportMarges.isNotEmpty
            ? rapportMarges.map((m) => m['tauxMarge'] as double).reduce((a, b) => a + b) /
                rapportMarges.length
            : 0,
        'margeTotale': rapportMarges.fold(0.0, (sum, item) => sum + (item['margeBrute'] as double)),
      },
      'creances': {
        'total': totalCreances,
        'clientsEnRetard': clientsEnRetard,
        'totalClients': creances.length,
      },
    };
  }
}
