import 'package:drift/drift.dart';

import '../constants/vente_types.dart';
import '../database/database.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../services/mode_paiement_service.dart';

class VenteService {
  static final VenteService _instance = VenteService._internal();
  factory VenteService() => _instance;
  VenteService._internal();

  final DatabaseService _db = DatabaseService();

  /// Génère le prochain numéro BL selon le type de vente
  Future<String> genererNumeroBL(VenteType type) async {
    final prefix = type.prefix;
    
    final result = await _db.database.customSelect(
      'SELECT MAX(CAST(SUBSTR(nfact, 4) AS INTEGER)) as max_num FROM ventes WHERE nfact LIKE ?',
      variables: [Variable('$prefix%')]
    ).getSingleOrNull();
    
    final lastNum = result?.read<int?>('max_num') ?? 0;
    final nextNum = lastNum + 1;
    
    return '$prefix$nextNum';
  }

  /// Filtre les ventes par type
  Future<List<dynamic>> getVentesByType(VenteType type) async {
    return await _db.database.customSelect(
      'SELECT * FROM ventes WHERE nfact LIKE ? ORDER BY daty DESC',
      variables: [Variable('${type.prefix}%')]
    ).get();
  }

  /// Filtre les clients par type de vente
  Future<List<dynamic>> getClientsByType(VenteType type) async {
    final categorie = type == VenteType.magasin ? 'Magasin' : 'Tous Dépôts';
    return await _db.database.customSelect(
      'SELECT * FROM clt WHERE categorie = ? ORDER BY rsoc',
      variables: [Variable(categorie)]
    ).get();
  }

  /// Détermine le type de vente selon le rôle utilisateur
  VenteType getTypeVenteParRole() {
    return AuthService().hasRole('Vendeur') ? VenteType.magasin : VenteType.tousDepots;
  }

  /// Récupère les modes de paiement disponibles
  Future<List<String>> getModesPaiement() async {
    return await ModePaiementService().getAllModesPaiement();
  }

  /// Enregistre une vente en brouillard
  Future<void> enregistrerVenteBrouillard({
    required VenteType type,
    required String client,
    required String modePaiement,
    required double totalTTC,
    required List<Map<String, dynamic>> lignes,
  }) async {
    await _db.database.transaction(() async {
      final numeroBL = await genererNumeroBL(type);
      final numVente = 'V${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Insérer la vente en brouillard
      await _db.database.customStatement('''
        INSERT INTO ventes (numventes, nfact, daty, clt, modepai, totalttc, verification)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        numVente, numeroBL, DateTime.now().toIso8601String(),
        client, modePaiement, totalTTC, StatutVente.brouillard.value
      ]);
      
      // 2. Insérer les détails
      for (final ligne in lignes) {
        await _db.database.customStatement('''
          INSERT INTO detventes (numventes, designation, unites, depots, q, pu, daty)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', [
          numVente, ligne['designation'], ligne['unite'], ligne['depot'],
          ligne['quantite'], ligne['prix'], DateTime.now().toIso8601String()
        ]);
      }
    });
  }

  /// Valide une vente brouillard vers journal avec mouvement de stock
  Future<void> validerVenteBrouillard(String numVente) async {
    await _db.database.transaction(() async {
      // 1. Vérifier que la vente existe et est en brouillard
      final vente = await (_db.database.select(_db.database.ventes)
            ..where((v) => v.numventes.equals(numVente)))
          .getSingleOrNull();
      
      if (vente == null) {
        throw Exception('Vente non trouvée');
      }
      
      if (vente.verification != StatutVente.brouillard.value) {
        throw Exception('Cette vente n\'est pas en brouillard');
      }

      // 2. Récupérer les détails de la vente
      final details = await (_db.database.select(_db.database.detventes)
            ..where((d) => d.numventes.equals(numVente)))
          .get();

      // 3. Créer les mouvements de stock et mettre à jour les quantités
      for (final detail in details) {
        if (detail.designation != null && detail.depots != null && detail.q != null) {
          await _creerMouvementStock(
            designation: detail.designation!,
            depot: detail.depots!,
            quantite: detail.q!,
            unite: detail.unites ?? 'Pce',
            numVente: numVente,
          );
          
          await _mettreAJourStocks(
            detail.designation!,
            detail.depots!,
            detail.q!,
            detail.unites ?? 'Pce',
          );
        }
      }

      // 4. Mettre à jour le statut vers journal
      await (_db.database.update(_db.database.ventes)
            ..where((v) => v.numventes.equals(numVente)))
          .write(VentesCompanion(
        verification: Value(StatutVente.journal.value),
      ));
    });
  }

  /// Crée un mouvement de stock
  Future<void> _creerMouvementStock({
    required String designation,
    required String depot,
    required double quantite,
    required String unite,
    required String numVente,
  }) async {
    final ref = 'VTE${DateTime.now().millisecondsSinceEpoch}';
    
    await _db.database.customStatement(
      '''INSERT INTO stocks (ref, daty, lib, numventes, refart, qs, sortie, depots, us, verification)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        ref,
        DateTime.now().toIso8601String(),
        'VENTE - $designation',
        numVente,
        designation,
        quantite,
        quantite,
        depot,
        unite,
        'VENTE'
      ]
    );
  }

  /// Met à jour les stocks après validation
  Future<void> _mettreAJourStocks(String designation, String depot, double quantite, String unite) async {
    // Récupérer l'article pour les conversions d'unités
    final article = await _db.database.getArticleByDesignation(designation);
    if (article == null) return;

    // Convertir la quantité vendue vers les unités de stock
    final conversionStock = _convertirQuantiteVente(
      article: article,
      uniteVente: unite,
      quantiteVente: quantite,
    );

    // Mettre à jour stock dépôt
    final stockDepart = await _db.database.customSelect(
      'SELECT * FROM depart WHERE designation = ? AND depots = ?',
      variables: [Variable(designation), Variable(depot)]
    ).getSingleOrNull();
    
    if (stockDepart != null) {
      final stockU1Actuel = stockDepart.read<double?>('stocksu1') ?? 0;
      final stockU2Actuel = stockDepart.read<double?>('stocksu2') ?? 0;
      final stockU3Actuel = stockDepart.read<double?>('stocksu3') ?? 0;
      
      await _db.database.customStatement(
        'UPDATE depart SET stocksu1 = ?, stocksu2 = ?, stocksu3 = ? WHERE designation = ? AND depots = ?',
        [
          stockU1Actuel - conversionStock['u1']!,
          stockU2Actuel - conversionStock['u2']!,
          stockU3Actuel - conversionStock['u3']!,
          designation,
          depot
        ]
      );
    }
    
    // Mettre à jour stock global article
    final stockGlobalU1 = (article.stocksu1 ?? 0) - conversionStock['u1']!;
    final stockGlobalU2 = (article.stocksu2 ?? 0) - conversionStock['u2']!;
    final stockGlobalU3 = (article.stocksu3 ?? 0) - conversionStock['u3']!;
    
    await _db.database.customStatement(
      'UPDATE articles SET stocksu1 = ?, stocksu2 = ?, stocksu3 = ? WHERE designation = ?',
      [stockGlobalU1, stockGlobalU2, stockGlobalU3, designation]
    );
  }

  /// Convertit une quantité de vente vers les unités de stock
  Map<String, double> _convertirQuantiteVente({
    required Article article,
    required String uniteVente,
    required double quantiteVente,
  }) {
    double quantiteU1 = 0;
    double quantiteU2 = 0;
    double quantiteU3 = 0;

    if (uniteVente == article.u1) {
      quantiteU1 = quantiteVente;
    } else if (uniteVente == article.u2) {
      quantiteU2 = quantiteVente;
    } else if (uniteVente == article.u3) {
      quantiteU3 = quantiteVente;
    }

    return {
      'u1': quantiteU1,
      'u2': quantiteU2,
      'u3': quantiteU3,
    };
  }
}