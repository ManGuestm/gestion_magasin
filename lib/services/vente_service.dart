import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../utils/stock_converter.dart';

class VenteService {
  final DatabaseService _databaseService = DatabaseService();

  /// Traite une vente en mode BROUILLARD (seulement détails, pas dans table ventes)
  Future<void> traiterVenteBrouillard({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required double totalHT,
    required double totalTTC,
    required double tva,
    required double? avance,
    required String? commercial,
    required double? commission,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
  }) async {
    await _databaseService.database.transaction(() async {
      // Stocker les informations de vente temporairement dans detventes avec métadonnées
      // La première ligne contiendra les métadonnées de la vente
      if (lignesVente.isNotEmpty) {
        await _databaseService.database.into(_databaseService.database.detventes).insert(
              DetventesCompanion.insert(
                numventes: Value(numVentes),
                designation: Value('__VENTE_METADATA__'),
                unites: Value('BROUILLARD'),
                depots: Value('TEMP'),
                q: Value(totalTTC),
                pu: Value(totalHT),
                daty: Value(date),
                diffPrix: Value(tva),
                // Stocker les autres infos dans des champs disponibles
              ),
            );
      }

      // Insérer les détails sans affecter les stocks
      for (final ligne in lignesVente) {
        await _databaseService.database.into(_databaseService.database.detventes).insert(
              DetventesCompanion.insert(
                numventes: Value(numVentes),
                designation: Value(ligne['designation']),
                unites: Value(ligne['unite']),
                depots: Value(ligne['depot']),
                q: Value(ligne['quantite']),
                pu: Value(ligne['prixUnitaire']),
                daty: Value(date),
                diffPrix: Value(ligne['diffPrix']),
              ),
            );
      }
    });
  }

  /// Traite une vente complète en mode JOURNAL avec toutes les opérations nécessaires
  Future<void> traiterVenteJournal({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalHT,
    required double totalTTC,
    required double tva,
    required double? avance,
    required String? commercial,
    required double? commission,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
    required double? montantRecu,
    required double? monnaieARendre,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Insérer la vente principale
      await _insererVente(
        numVentes: numVentes,
        nFacture: nFacture,
        date: date,
        client: client,
        modePaiement: modePaiement,
        echeance: echeance,
        totalHT: totalHT,
        totalTTC: totalTTC,
        tva: tva,
        avance: avance,
        commercial: commercial,
        commission: commission,
        remise: remise,
        montantRecu: montantRecu,
        monnaieARendre: monnaieARendre,
      );

      // 2. Traiter chaque ligne de vente
      for (final ligne in lignesVente) {
        await _traiterLigneVente(
          numVentes: numVentes,
          ligne: ligne,
          date: date,
          client: client,
        );
      }

      // 3. Ajuster compte client si crédit
      if (modePaiement == 'A crédit' && client != null && client.isNotEmpty) {
        await _ajusterCompteClient(
          client: client,
          numVentes: numVentes,
          nFacture: nFacture,
          montant: totalTTC - (avance ?? 0),
          date: date,
        );
      }

      // 4. Mouvement caisse si espèces
      if (modePaiement == 'Espèces') {
        await _mouvementCaisse(
          numVentes: numVentes,
          montant: totalTTC,
          client: client,
          date: date,
        );
      }
    });
  }

  /// Insère la vente principale dans la table ventes
  Future<void> _insererVente({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalHT,
    required double totalTTC,
    required double tva,
    required double? avance,
    required String? commercial,
    required double? commission,
    required double? remise,
    required double? montantRecu,
    required double? monnaieARendre,
  }) async {
    await _databaseService.database.into(_databaseService.database.ventes).insert(
          VentesCompanion.insert(
            numventes: Value(numVentes),
            nfact: Value(nFacture),
            daty: Value(date),
            clt: Value(client),
            modepai: Value(modePaiement),
            echeance: Value(echeance),
            totalnt: Value(totalHT),
            totalttc: Value(totalTTC),
            tva: Value(tva),
            avance: Value(avance),
            commerc: Value(commercial),
            commission: Value(commission),
            remise: Value(remise),
            verification: const Value('JOURNAL'),
            montantRecu: Value(montantRecu),
            monnaieARendre: Value(monnaieARendre),
          ),
        );
  }

  /// Traite une ligne de vente individuelle (privée pour usage interne)
  Future<void> _traiterLigneVente({
    required String numVentes,
    required Map<String, dynamic> ligne,
    required DateTime date,
    required String? client,
  }) async {
    final designation = ligne['designation'] as String;
    final unite = ligne['unite'] as String;
    final depot = ligne['depot'] as String;
    final quantite = ligne['quantite'] as double;
    final prixUnitaire = ligne['prixUnitaire'] as double;
    final diffPrix = ligne['diffPrix'] as double?;

    // 1. Insérer détail vente (pour mode JOURNAL)
    await _databaseService.database.into(_databaseService.database.detventes).insert(
          DetventesCompanion.insert(
            numventes: Value(numVentes),
            designation: Value(designation),
            unites: Value(unite),
            depots: Value(depot),
            q: Value(quantite),
            pu: Value(prixUnitaire),
            daty: Value(date),
            diffPrix: Value(diffPrix),
          ),
        );

    // 2. Récupérer l'article pour les conversions
    final article = await (_databaseService.database.select(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // 3. Réduire stocks par dépôt
    await _reduireStockDepot(
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
    );

    // 4. Créer mouvement stock de sortie
    await _creerMouvementStock(
      numVentes: numVentes,
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      client: client,
      date: date,
    );

    // 5. Ajuster stock global article
    await _ajusterStockGlobalArticle(
      article: article,
      unite: unite,
      quantite: quantite,
    );

    // 6. Mettre à jour fiche stock
    await _mettreAJourFicheStock(
      designation: designation,
      unite: unite,
      quantite: quantite,
    );
  }

  /// Réduit le stock dans la table depart
  Future<void> _reduireStockDepot({
    required Article article,
    required String depot,
    required String unite,
    required double quantite,
  }) async {
    // Convertir la quantité vers toutes les unités
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    // Récupérer le stock actuel
    final stockActuel = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockActuel != null) {
      // Calculer nouveaux stocks
      final nouveauStockU1 = (stockActuel.stocksu1 ?? 0) - conversions['u1']!;
      final nouveauStockU2 = (stockActuel.stocksu2 ?? 0) - conversions['u2']!;
      final nouveauStockU3 = (stockActuel.stocksu3 ?? 0) - conversions['u3']!;

      // Mettre à jour
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: Value(nouveauStockU1),
        stocksu2: Value(nouveauStockU2),
        stocksu3: Value(nouveauStockU3),
      ));
    } else {
      throw Exception('Stock non trouvé pour ${article.designation} dans le dépôt $depot');
    }
  }

  /// Crée un mouvement de stock de sortie
  Future<void> _creerMouvementStock({
    required String numVentes,
    required Article article,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
    required String? client,
    required DateTime date,
  }) async {
    final ref = 'V-${DateTime.now().millisecondsSinceEpoch}-${article.designation}';

    // Convertir la quantité vers toutes les unités pour le stock
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    await _databaseService.database.into(_databaseService.database.stocks).insert(
          StocksCompanion.insert(
            ref: Value(ref).toString(),
            daty: Value(date),
            lib: Value('Vente N° $numVentes'),
            numventes: Value(numVentes),
            refart: Value(article.designation),
            qs: Value(quantite),
            sortie: Value(quantite * prixUnitaire),
            stocksu1: Value(conversions['u1']),
            stocksu2: Value(conversions['u2']),
            stocksu3: Value(conversions['u3']),
            depots: Value(depot),
            clt: Value(client),
            verification: const Value('JOURNAL'),
            us: Value(unite),
            pus: Value(prixUnitaire),
          ),
        );
  }

  /// Ajuste le stock global de l'article
  Future<void> _ajusterStockGlobalArticle({
    required Article article,
    required String unite,
    required double quantite,
  }) async {
    // Convertir la quantité vers toutes les unités
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    // Calculer nouveaux stocks globaux
    final nouveauStockU1 = (article.stocksu1 ?? 0) - conversions['u1']!;
    final nouveauStockU2 = (article.stocksu2 ?? 0) - conversions['u2']!;
    final nouveauStockU3 = (article.stocksu3 ?? 0) - conversions['u3']!;

    // Mettre à jour l'article
    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(
      stocksu1: Value(nouveauStockU1),
      stocksu2: Value(nouveauStockU2),
      stocksu3: Value(nouveauStockU3),
    ));
  }

  /// Met à jour la fiche stock
  Future<void> _mettreAJourFicheStock({
    required String designation,
    required String unite,
    required double quantite,
  }) async {
    final ficheExiste = await (_databaseService.database.select(_databaseService.database.fstocks)
          ..where((f) => f.art.equals(designation)))
        .getSingleOrNull();

    if (ficheExiste != null) {
      // Mettre à jour la fiche existante
      double nouvelleQs = (ficheExiste.qs ?? 0) + quantite;
      double nouvelleQst = (ficheExiste.qst ?? 0) + quantite;

      await (_databaseService.database.update(_databaseService.database.fstocks)
            ..where((f) => f.art.equals(designation)))
          .write(FstocksCompanion(
        qs: Value(nouvelleQs),
        qst: Value(nouvelleQst),
      ));
    } else {
      // Créer nouvelle fiche
      final ref = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database.into(_databaseService.database.fstocks).insert(
            FstocksCompanion.insert(
              ref: Value(ref).toString(),
              art: Value(designation),
              qs: Value(quantite),
              qst: Value(quantite),
              ue: Value(unite),
            ),
          );
    }
  }

  /// Ajuste le compte client pour vente à crédit
  Future<void> _ajusterCompteClient({
    required String client,
    required String numVentes,
    required String? nFacture,
    required double montant,
    required DateTime date,
  }) async {
    if (montant <= 0) return;

    final ref = 'V-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.compteclt).insert(
          ComptecltCompanion.insert(
            ref: Value(ref).toString(),
            daty: Value(date),
            lib: Value('Vente N° $numVentes${nFacture != null ? ' - Facture $nFacture' : ''}'),
            numventes: Value(numVentes),
            nfact: Value(nFacture),
            entres: Value(montant),
            sorties: const Value(0.0),
            solde: Value(montant),
            clt: Value(client),
            verification: const Value('JOURNAL'),
          ),
        );

    // Mettre à jour le solde client
    final clientData = await (_databaseService.database.select(_databaseService.database.clt)
          ..where((c) => c.rsoc.equals(client)))
        .getSingleOrNull();

    if (clientData != null) {
      final nouveauSolde = (clientData.soldes ?? 0) + montant;
      await (_databaseService.database.update(_databaseService.database.clt)
            ..where((c) => c.rsoc.equals(client)))
          .write(CltCompanion(
        soldes: Value(nouveauSolde),
        datedernop: Value(date),
      ));
    }
  }

  /// Crée un mouvement de caisse pour paiement espèces
  Future<void> _mouvementCaisse({
    required String numVentes,
    required double montant,
    required String? client,
    required DateTime date,
  }) async {
    if (montant <= 0) return;

    final ref = 'V-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.caisse).insert(
          CaisseCompanion.insert(
            ref: Value(ref).toString(),
            daty: Value(date),
            lib: Value('Vente N° $numVentes'),
            debit: Value(montant),
            clt: Value(client ?? ''),
            verification: const Value('JOURNAL'),
          ),
        );
  }

  /// Vérifie la disponibilité du stock avant vente
  Future<bool> verifierDisponibiliteStock({
    required String designation,
    required String depot,
    required String unite,
    required double quantite,
  }) async {
    final article = await (_databaseService.database.select(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .getSingleOrNull();

    if (article == null) return false;

    final stockDepot = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockDepot == null) return false;

    // Convertir la quantité demandée vers l'unité de base (u1)
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    // Vérifier si le stock est suffisant en u1
    return (stockDepot.stocksu1 ?? 0) >= conversions['u1']!;
  }

  /// Valide une vente brouillard vers journal avec informations complètes
  Future<void> validerVenteBrouillardAvecInfos({
    required String numVentes,
    required String? nFacture,
    required String? client,
    required String? modePaiement,
    required double totalHT,
    required double totalTTC,
    required double tva,
    required double? avance,
    required double? remise,
    required double? commission,
    required double? montantRecu,
    required double? monnaieARendre,
  }) async {
    // Récupérer les détails (y compris métadonnées)
    final details = await (_databaseService.database.select(_databaseService.database.detventes)
          ..where((d) => d.numventes.equals(numVentes)))
        .get();

    if (details.isEmpty) {
      throw Exception('Vente brouillard non trouvée');
    }

    // Récupérer les métadonnées de la vente
    final metadata = details.where((d) => d.designation == '__VENTE_METADATA__').firstOrNull;
    if (metadata == null) {
      throw Exception('Métadonnées de vente non trouvées');
    }

    final lignesVente = details.where((d) => d.designation != '__VENTE_METADATA__').toList();
    final currentUser = AuthService().currentUser;
    final commercialName = currentUser?.nom ?? '';

    await _databaseService.database.transaction(() async {
      // 1. Créer l'enregistrement dans la table ventes
      await _databaseService.database.into(_databaseService.database.ventes).insert(
            VentesCompanion.insert(
              numventes: Value(numVentes),
              nfact: Value(nFacture),
              daty: Value(metadata.daty ?? DateTime.now()),
              clt: Value(client),
              modepai: Value(modePaiement),
              totalnt: Value(totalHT),
              totalttc: Value(totalTTC),
              tva: Value(tva),
              avance: Value(avance),
              remise: Value(remise),
              commission: Value(commission),
              commerc: Value(commercialName),
              verification: const Value('JOURNAL'),
              montantRecu: Value(montantRecu),
              monnaieARendre: Value(monnaieARendre),
            ),
          );

      // 2. Supprimer les métadonnées temporaires
      await (_databaseService.database.delete(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVentes) & d.designation.equals('__VENTE_METADATA__')))
          .go();

      // 3. Traiter chaque ligne pour créer les mouvements de stock
      for (final detail in lignesVente) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          await _traiterLigneVente(
            numVentes: numVentes,
            ligne: {
              'designation': detail.designation!,
              'unite': detail.unites!,
              'depot': detail.depots!,
              'quantite': detail.q!,
              'prixUnitaire': detail.pu ?? 0.0,
              'diffPrix': detail.diffPrix ?? 0.0,
            },
            date: metadata.daty ?? DateTime.now(),
            client: client,
          );
        }
      }

      // 4. Ajuster compte client si crédit
      if (modePaiement == 'A crédit' && client != null && client.isNotEmpty) {
        await _ajusterCompteClient(
          client: client,
          numVentes: numVentes,
          nFacture: nFacture,
          montant: totalTTC - (avance ?? 0),
          date: metadata.daty ?? DateTime.now(),
        );
      }

      // 5. Mouvement caisse si espèces
      if (modePaiement == 'Espèces') {
        await _mouvementCaisse(
          numVentes: numVentes,
          montant: totalTTC,
          client: client,
          date: metadata.daty ?? DateTime.now(),
        );
      }
    });
  }

  /// Valide une vente brouillard vers journal (ancienne méthode)
  Future<void> validerVenteBrouillard(String numVentes) async {
    // Récupérer les détails (y compris métadonnées)
    final details = await (_databaseService.database.select(_databaseService.database.detventes)
          ..where((d) => d.numventes.equals(numVentes)))
        .get();

    if (details.isEmpty) {
      throw Exception('Vente brouillard non trouvée');
    }

    // Récupérer les métadonnées de la vente
    final metadata = details.where((d) => d.designation == '__VENTE_METADATA__').firstOrNull;
    if (metadata == null) {
      throw Exception('Métadonnées de vente non trouvées');
    }

    final lignesVente = details.where((d) => d.designation != '__VENTE_METADATA__').toList();

    await _databaseService.database.transaction(() async {
      // 1. Créer l'enregistrement dans la table ventes
      await _databaseService.database.into(_databaseService.database.ventes).insert(
            VentesCompanion.insert(
              numventes: Value(numVentes),
              nfact: Value(''), // À récupérer depuis le modal
              daty: Value(metadata.daty ?? DateTime.now()),
              clt: Value(''), // À récupérer depuis le modal
              modepai: Value('A crédit'), // À récupérer depuis le modal
              totalnt: Value(metadata.pu ?? 0), // totalHT stocké dans pu
              totalttc: Value(metadata.q ?? 0), // totalTTC stocké dans q
              tva: Value(metadata.diffPrix ?? 0), // tva stocké dans diffPrix
              verification: const Value('JOURNAL'),
            ),
          );

      // 2. Supprimer les métadonnées temporaires
      await (_databaseService.database.delete(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVentes) & d.designation.equals('__VENTE_METADATA__')))
          .go();

      // 3. Traiter chaque ligne pour créer les mouvements de stock
      for (final detail in lignesVente) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          await _traiterLigneVente(
            numVentes: numVentes,
            ligne: {
              'designation': detail.designation!,
              'unite': detail.unites!,
              'depot': detail.depots!,
              'quantite': detail.q!,
              'prixUnitaire': detail.pu ?? 0.0,
              'diffPrix': detail.diffPrix ?? 0.0,
            },
            date: metadata.daty ?? DateTime.now(),
            client: '', // Client sera récupéré depuis le modal
          );
        }
      }
    });
  }
}
