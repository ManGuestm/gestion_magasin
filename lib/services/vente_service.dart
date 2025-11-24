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
            verification: Value('JOURNAL'),
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
      // Créer l'entrée de stock avec des valeurs négatives (vente à découvert)
      await _databaseService.database.into(_databaseService.database.depart).insert(
            DepartCompanion.insert(
              designation: Value(article.designation).toString(),
              depots: Value(depot).toString(),
              stocksu1: Value(-conversions['u1']!),
              stocksu2: Value(-conversions['u2']!),
              stocksu3: Value(-conversions['u3']!),
            ),
          );
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
            verification: Value('JOURNAL'),
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
            sorties: Value(0.0),
            solde: Value(montant),
            clt: Value(client),
            verification: Value('JOURNAL'),
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
            verification: Value('JOURNAL'),
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

  /// Vérifie le stock selon le type de dépôt et retourne le type de validation
  Future<Map<String, dynamic>> verifierStockSelonDepot({
    required String designation,
    required String depot,
    required String unite,
    required double quantite,
    required bool tousDepots,
  }) async {
    final stockSuffisant = await verifierDisponibiliteStock(
      designation: designation,
      depot: depot,
      unite: unite,
      quantite: quantite,
    );

    if (stockSuffisant) {
      return {'autorise': true, 'typeDialog': null};
    }

    // Stock insuffisant
    if (tousDepots) {
      // Tous dépôts: autoriser avec confirmation
      return {'autorise': false, 'typeDialog': 'confirmation'};
    } else {
      // MAG uniquement: bloquer
      return {'autorise': false, 'typeDialog': 'restriction'};
    }
  }

  /// Met à jour les métadonnées d'une vente brouillard existante
  Future<void> mettreAJourMetadonneesBrouillard({
    required String numVentes,
    required double totalHT,
    required double totalTTC,
    required double tva,
    required DateTime date,
  }) async {
    // Supprimer les anciennes métadonnées
    await (_databaseService.database.delete(_databaseService.database.detventes)
          ..where((d) => d.numventes.equals(numVentes) & d.designation.equals('__VENTE_METADATA__')))
        .go();

    // Créer les nouvelles métadonnées avec les totaux mis à jour
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
          ),
        );
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
    // Mettre à jour les métadonnées avant validation
    await mettreAJourMetadonneesBrouillard(
      numVentes: numVentes,
      totalHT: totalHT,
      totalTTC: totalTTC,
      tva: tva,
      date: DateTime.now(),
    );
    // Récupérer les détails (y compris métadonnées)
    final details = await (_databaseService.database.select(_databaseService.database.detventes)
          ..where((d) => d.numventes.equals(numVentes)))
        .get();

    if (details.isEmpty) {
      throw Exception('Vente brouillard non trouvée');
    }

    // Récupérer les métadonnées de la vente (prendre la plus récente si plusieurs)
    final metadataList = details.where((d) => d.designation == '__VENTE_METADATA__').toList();
    if (metadataList.isEmpty) {
      throw Exception('Métadonnées de vente non trouvées');
    }
    // Trier par date et prendre la plus récente
    metadataList.sort((a, b) => (b.daty ?? DateTime(0)).compareTo(a.daty ?? DateTime(0)));
    final metadata = metadataList.first;

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
              verification: Value('JOURNAL'),
              montantRecu: Value(montantRecu),
              monnaieARendre: Value(monnaieARendre),
            ),
          );

      // 2. Supprimer les métadonnées temporaires
      await (_databaseService.database.delete(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVentes) & d.designation.equals('__VENTE_METADATA__')))
          .go();

      // 3. Traiter chaque ligne pour créer les mouvements de stock (sans réinsérer dans detventes)
      for (final detail in lignesVente) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          // Récupérer l'article pour les conversions
          final article = await (_databaseService.database.select(_databaseService.database.articles)
                ..where((a) => a.designation.equals(detail.designation!)))
              .getSingleOrNull();

          if (article != null) {
            // Réduire stocks par dépôt
            await _reduireStockDepot(
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            // Créer mouvement stock de sortie
            await _creerMouvementStock(
              numVentes: numVentes,
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
              prixUnitaire: detail.pu ?? 0.0,
              client: client,
              date: metadata.daty ?? DateTime.now(),
            );

            // Ajuster stock global article
            await _ajusterStockGlobalArticle(
              article: article,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            // Mettre à jour fiche stock
            await _mettreAJourFicheStock(
              designation: detail.designation!,
              unite: detail.unites!,
              quantite: detail.q!,
            );
          }
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

  /// Enregistre une vente Brouillard -> Journal avec gestion complète
  Future<void> enregistrerVenteBrouillardVersJournal({
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
    required double? montantRecu,
    required double? monnaieARendre,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Traiter la vente en mode brouillard d'abord
      await traiterVenteBrouillard(
        numVentes: numVentes,
        nFacture: nFacture,
        date: date,
        client: client,
        modePaiement: modePaiement,
        totalHT: totalHT,
        totalTTC: totalTTC,
        tva: tva,
        avance: avance,
        commercial: commercial,
        commission: commission,
        remise: remise,
        lignesVente: lignesVente,
      );

      // 2. Valider immédiatement vers journal
      await validerVenteBrouillardAvecInfos(
        numVentes: numVentes,
        nFacture: nFacture,
        client: client,
        modePaiement: modePaiement,
        totalHT: totalHT,
        totalTTC: totalTTC,
        tva: tva,
        avance: avance,
        remise: remise,
        commission: commission,
        montantRecu: montantRecu,
        monnaieARendre: monnaieARendre,
      );
    });
  }

  /// Contre-passe une vente avec restauration complète
  Future<void> contrePasserVente(String numVentes) async {
    final vente = await (_databaseService.database.select(_databaseService.database.ventes)
          ..where((v) => v.numventes.equals(numVentes)))
        .getSingleOrNull();

    if (vente == null) throw Exception('Vente non trouvée');

    final details = await (_databaseService.database.select(_databaseService.database.detventes)
          ..where((d) => d.numventes.equals(numVentes)))
        .get();

    await _databaseService.database.transaction(() async {
      // 1. Restaurer stocks
      for (final detail in details) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          final article = await (_databaseService.database.select(_databaseService.database.articles)
                ..where((a) => a.designation.equals(detail.designation!)))
              .getSingleOrNull();

          if (article != null) {
            await _restaurerStockDepot(
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            await _restaurerStockGlobal(
              article: article,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            await _creerMouvementStockRestauration(
              numVentes: numVentes,
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
              prixUnitaire: detail.pu ?? 0.0,
              client: vente.clt,
            );
          }
        }
      }

      // 2. Ajuster compte client si crédit
      if (vente.modepai == 'A crédit' && vente.clt != null && vente.clt!.isNotEmpty) {
        final montant = (vente.totalttc ?? 0) - (vente.avance ?? 0);
        if (montant > 0) {
          await _ajusterCompteClientContrePassement(
            client: vente.clt!,
            numVentes: numVentes,
            montant: montant,
          );
        }
      }

      // 3. Décaissement si espèces
      if (vente.modepai == 'Espèces') {
        await _decaissement(
          numVentes: numVentes,
          montant: vente.totalttc ?? 0,
          client: vente.clt,
        );
      }

      // 4. Marquer la vente comme contre-passée
      await (_databaseService.database.update(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(numVentes)))
          .write(VentesCompanion(
        contre: Value("1"),
      ));
    });
  }

  /// Récupère les ventes en Journal (non contre-passées)
  Future<List<Vente>> getVentesJournal() async {
    return await (_databaseService.database.select(_databaseService.database.ventes)
          ..where((v) => v.verification.equals('JOURNAL') & (v.contre.isNull() | v.contre.equals("0"))))
        .get();
  }

  Future<void> _restaurerStockDepot({
    required Article article,
    required String depot,
    required String unite,
    required double quantite,
  }) async {
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    final stockActuel = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockActuel != null) {
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: Value((stockActuel.stocksu1 ?? 0) + conversions['u1']!),
        stocksu2: Value((stockActuel.stocksu2 ?? 0) + conversions['u2']!),
        stocksu3: Value((stockActuel.stocksu3 ?? 0) + conversions['u3']!),
      ));
    }
  }

  Future<void> _restaurerStockGlobal({
    required Article article,
    required String unite,
    required double quantite,
  }) async {
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(
      stocksu1: Value((article.stocksu1 ?? 0) + conversions['u1']!),
      stocksu2: Value((article.stocksu2 ?? 0) + conversions['u2']!),
      stocksu3: Value((article.stocksu3 ?? 0) + conversions['u3']!),
    ));
  }

  Future<void> _creerMouvementStockRestauration({
    required String numVentes,
    required Article article,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
    required String? client,
  }) async {
    final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}-${article.designation}';
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    await _databaseService.database.into(_databaseService.database.stocks).insert(
          StocksCompanion.insert(
            ref: Value(ref).toString(),
            daty: Value(DateTime.now()),
            lib: Value('Contre-passement vente N° $numVentes'),
            numventes: Value(numVentes),
            refart: Value(article.designation),
            qe: Value(quantite),
            entres: Value(quantite * prixUnitaire),
            stocksu1: Value(conversions['u1']),
            stocksu2: Value(conversions['u2']),
            stocksu3: Value(conversions['u3']),
            depots: Value(depot),
            clt: Value(client),
            verification: Value('JOURNAL'),
            ue: Value(unite),
          ),
        );
  }

  Future<void> _ajusterCompteClientContrePassement({
    required String client,
    required String numVentes,
    required double montant,
  }) async {
    final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.compteclt).insert(
          ComptecltCompanion.insert(
            ref: Value(ref).toString(),
            clt: Value(client),
            daty: Value(DateTime.now()),
            lib: Value('Contre-passement vente N° $numVentes'),
            entres: Value(0.0),
            sorties: Value(montant),
            solde: Value(-montant),
            verification: Value('JOURNAL'),
          ),
        );

    final clientData = await (_databaseService.database.select(_databaseService.database.clt)
          ..where((c) => c.rsoc.equals(client)))
        .getSingleOrNull();

    if (clientData != null) {
      await (_databaseService.database.update(_databaseService.database.clt)
            ..where((c) => c.rsoc.equals(client)))
          .write(CltCompanion(
        soldes: Value((clientData.soldes ?? 0) - montant),
        datedernop: Value(DateTime.now()),
      ));
    }
  }

  Future<void> _decaissement({
    required String numVentes,
    required double montant,
    required String? client,
  }) async {
    final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.caisse).insert(
          CaisseCompanion.insert(
            ref: Value(ref).toString(),
            daty: Value(DateTime.now()),
            lib: Value('Contre-passement vente N° $numVentes'),
            credit: Value(montant),
            clt: Value(client ?? ''),
            verification: const Value('JOURNAL'),
          ),
        );
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

    // Récupérer les métadonnées de la vente (prendre la plus récente si plusieurs)
    final metadataList = details.where((d) => d.designation == '__VENTE_METADATA__').toList();
    if (metadataList.isEmpty) {
      throw Exception('Métadonnées de vente non trouvées');
    }
    // Trier par date et prendre la plus récente
    metadataList.sort((a, b) => (b.daty ?? DateTime(0)).compareTo(a.daty ?? DateTime(0)));
    final metadata = metadataList.first;

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
