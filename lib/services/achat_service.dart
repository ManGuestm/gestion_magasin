import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';

class AchatService {
  static final AchatService _instance = AchatService._internal();
  factory AchatService() => _instance;
  AchatService._internal();

  final DatabaseService _db = DatabaseService();

  /// Enregistre un achat complet avec détails et mise à jour des stocks
  Future<void> enregistrerAchatComplet({
    required AchatsCompanion achat,
    required List<Map<String, dynamic>> lignesAchat,
  }) async {
    final database = _db.database;

    await database.transaction(() async {
      // 1. Insérer l'achat principal
      await database.insertAchat(achat);

      // 2. Insérer les détails d'achat
      for (var ligne in lignesAchat) {
        await database.customStatement(
            '''INSERT INTO detachats (numachats, designation, unites, q, pu, daty, depots, qe)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
            [
              achat.numachats.value,
              ligne['designation'],
              ligne['unites'],
              ligne['quantite'],
              ligne['prixUnitaire'],
              achat.daty.value?.toIso8601String(),
              ligne['depot'],
              ligne['quantite']
            ]);

        // 3. Mettre à jour les stocks
        await _mettreAJourStocksAchat(
          ligne['designation'],
          ligne['depot'],
          ligne['unites'],
          ligne['quantite'],
          ligne['prixUnitaire'],
          achat.numachats.value ?? '',
        );
      }

      // 4. Mettre à jour le solde fournisseur si nécessaire
      if (achat.frns.present && achat.totalttc.present && achat.regl.present) {
        await _mettreAJourSoldeFournisseur(
          achat.frns.value!,
          achat.totalttc.value! - (achat.regl.value ?? 0),
        );
      }
    });
  }

  /// Met à jour les stocks après un achat
  Future<void> _mettreAJourStocksAchat(
    String designation,
    String depot,
    String unite,
    double quantite,
    double prixUnitaire,
    String numAchat,
  ) async {
    final database = _db.database;

    // 1. Récupérer l'article pour les conversions
    final article = await database.getArticleByDesignation(designation);
    if (article == null) return;

    // 2. Convertir la quantité selon l'unité
    double quantiteU1 = 0, quantiteU2 = 0;

    if (unite == article.u1) {
      quantiteU1 = quantite;
    } else if (unite == article.u2 && article.tu2u1 != null) {
      quantiteU1 = quantite / article.tu2u1!;
      quantiteU2 = quantite;
    } else if (unite == article.u2) {
      quantiteU2 = quantite;
    }

    // 3. Mettre à jour le stock par dépôt (table depart)
    final stockDepart = await database.customSelect(
        'SELECT * FROM depart WHERE designation = ? AND depots = ?',
        variables: [Variable(designation), Variable(depot)]).getSingleOrNull();

    if (stockDepart == null) {
      // Créer nouveau stock par dépôt
      await database.customStatement(
          'INSERT INTO depart (designation, depots, stocksu1, stocksu2, stocksu3) VALUES (?, ?, ?, ?, 0)',
          [designation, depot, quantiteU1, quantiteU2]);
    } else {
      // Mettre à jour stock existant
      final stockU1Actuel = stockDepart.read<double?>('stocksu1') ?? 0;
      final stockU2Actuel = stockDepart.read<double?>('stocksu2') ?? 0;

      await database.customStatement(
          'UPDATE depart SET stocksu1 = ?, stocksu2 = ? WHERE designation = ? AND depots = ?',
          [stockU1Actuel + quantiteU1, stockU2Actuel + quantiteU2, designation, depot]);
    }

    // 4. Mettre à jour le stock global et CMUP (table articles)
    final stockGlobalU1Actuel = article.stocksu1 ?? 0;
    final stockGlobalU2Actuel = article.stocksu2 ?? 0;
    final cmupActuel = article.cmup ?? 0;

    // Calculer nouveau CMUP
    final ancienneValeur = stockGlobalU1Actuel * cmupActuel;
    final nouvelleValeur = quantiteU1 * prixUnitaire;
    final quantiteTotale = stockGlobalU1Actuel + quantiteU1;

    final nouveauCmup =
        quantiteTotale > 0 ? (ancienneValeur + nouvelleValeur) / quantiteTotale : prixUnitaire;

    await database.customStatement(
        'UPDATE articles SET stocksu1 = ?, stocksu2 = ?, cmup = ? WHERE designation = ?',
        [stockGlobalU1Actuel + quantiteU1, stockGlobalU2Actuel + quantiteU2, nouveauCmup, designation]);

    // 5. Créer un mouvement de stock
    await _creerMouvementStockAchat(
      designation: designation,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      numAchat: numAchat,
    );
  }

  /// Crée un mouvement de stock pour un achat
  Future<void> _creerMouvementStockAchat({
    required String designation,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
    required String numAchat,
  }) async {
    final database = _db.database;
    final ref = 'ACH${DateTime.now().millisecondsSinceEpoch}';

    await database.customStatement(
        '''INSERT INTO stocks (ref, daty, lib, refart, qe, entres, ue, depots, numachats, pus, verification)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          ref,
          DateTime.now().toIso8601String(),
          'ACHAT - $designation',
          designation,
          quantite,
          quantite,
          unite,
          depot,
          numAchat,
          prixUnitaire,
          'ACHAT'
        ]);
  }

  /// Met à jour le solde d'un fournisseur
  Future<void> _mettreAJourSoldeFournisseur(String rsocFournisseur, double montant) async {
    final database = _db.database;

    final fournisseur = await database.getFournisseurByRsoc(rsocFournisseur);
    if (fournisseur != null) {
      final nouveauSolde = (fournisseur.soldes ?? 0) + montant;

      await database.customStatement('UPDATE frns SET soldes = ?, datedernop = ? WHERE rsoc = ?',
          [nouveauSolde, DateTime.now().toIso8601String(), rsocFournisseur]);

      // Créer un mouvement dans comptefrns
      final ref = 'FRN${DateTime.now().millisecondsSinceEpoch}';
      await database.customStatement('''INSERT INTO comptefrns (ref, daty, lib, entres, sortie, solde, frns)
           VALUES (?, ?, ?, ?, ?, ?, ?)''', [
        ref,
        DateTime.now().toIso8601String(),
        'Achat à crédit',
        montant > 0 ? montant : 0,
        montant < 0 ? -montant : 0,
        nouveauSolde,
        rsocFournisseur
      ]);
    }
  }

  /// Génère un numéro d'achat unique
  Future<String> genererNumeroAchat() async {
    final database = _db.database;

    final result = await database.customSelect(
        'SELECT COUNT(*) as count FROM achats WHERE DATE(daty) = DATE(?)',
        variables: [Variable(DateTime.now().toIso8601String())]).getSingle();

    final count = result.read<int>('count') + 1;
    final dateStr = DateTime.now().toString().substring(0, 10).replaceAll('-', '');

    return 'ACH$dateStr${count.toString().padLeft(3, '0')}';
  }

  /// Récupère les achats par période
  Future<List<Map<String, dynamic>>> getAchatsParPeriode(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT a.*, f.rsoc as nom_fournisseur 
         FROM achats a 
         LEFT JOIN frns f ON a.frns = f.rsoc 
         WHERE a.daty BETWEEN ? AND ? 
         ORDER BY a.daty DESC''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).get();

    return result
        .map((row) => {
              'num': row.read<int>('num'),
              'numachats': row.read<String?>('numachats'),
              'daty': row.read<DateTime?>('daty'),
              'frns': row.read<String?>('frns'),
              'nom_fournisseur': row.read<String?>('nom_fournisseur'),
              'totalttc': row.read<double?>('totalttc'),
              'modepai': row.read<String?>('modepai'),
            })
        .toList();
  }

  /// Récupère les détails d'un achat
  Future<List<Map<String, dynamic>>> getDetailsAchat(String numAchat) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT da.*, a.designation as nom_article 
         FROM detachats da 
         LEFT JOIN articles a ON da.designation = a.designation 
         WHERE da.numachats = ? 
         ORDER BY da.num''', variables: [Variable(numAchat)]).get();

    return result
        .map((row) => {
              'num': row.read<int>('num'),
              'designation': row.read<String?>('designation'),
              'nom_article': row.read<String?>('nom_article'),
              'unites': row.read<String?>('unites'),
              'q': row.read<double?>('q'),
              'pu': row.read<double?>('pu'),
              'depots': row.read<String?>('depots'),
            })
        .toList();
  }

  /// Calcule les statistiques d'achats
  Future<Map<String, dynamic>> getStatistiquesAchats(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           COUNT(*) as nombre_achats,
           COALESCE(SUM(totalnt), 0) as total_ht,
           COALESCE(SUM(totalttc), 0) as total_ttc,
           COALESCE(AVG(totalttc), 0) as moyenne_achat
         FROM achats 
         WHERE daty BETWEEN ? AND ?''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).getSingle();

    return {
      'nombre_achats': result.read<int>('nombre_achats'),
      'total_ht': result.read<double>('total_ht'),
      'total_ttc': result.read<double>('total_ttc'),
      'moyenne_achat': result.read<double>('moyenne_achat'),
    };
  }
}
