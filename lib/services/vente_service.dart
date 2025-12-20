import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../utils/stock_converter.dart';

class VenteService {
  final DatabaseService _databaseService = DatabaseService();

  /// Enregistre une vente en mode BROUILLARD
  Future<void> enregistrerVenteBrouillard({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required double totalTTC,
    required double? avance,
    required String? commercial,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
    String? heure,
  }) async {
    // 🔥 En mode CLIENT, envoyer au serveur via customStatement
    if (_databaseService.isNetworkMode) {
      await _enregistrerVenteBrouillardViaServeur(
        numVentes: numVentes,
        nFacture: nFacture,
        date: date,
        client: client,
        modePaiement: modePaiement,
        totalTTC: totalTTC,
        avance: avance,
        commercial: commercial,
        remise: remise,
        lignesVente: lignesVente,
        heure: heure,
      );
      return;
    }
    
    // Mode LOCAL/SERVER : enregistrer localement
    await _databaseService.database.transaction(() async {
      // 1. Insérer la vente en mode BROUILLARD
      await _databaseService.database
          .into(_databaseService.database.ventes)
          .insert(
            VentesCompanion.insert(
              numventes: Value(numVentes),
              nfact: Value(nFacture),
              daty: Value(date),
              clt: Value(client),
              modepai: Value(modePaiement),
              totalttc: Value(totalTTC),
              avance: Value(avance),
              commerc: Value(commercial),
              remise: Value(remise),
              verification: const Value('BROUILLARD'),
              heure: Value(heure),
            ),
          );

      // 2. Insérer les détails sans affecter les stocks
      for (final ligne in lignesVente) {
        await _databaseService.database
            .into(_databaseService.database.detventes)
            .insert(
              DetventesCompanion.insert(
                numventes: Value(numVentes),
                designation: Value(ligne['designation']),
                unites: Value(ligne['unite']),
                depots: Value(ligne['depot']),
                q: Value(ligne['quantite']),
                pu: Value(ligne['prixUnitaire']),
                daty: Value(date),
                diffPrix: Value((ligne['diffPrix'] ?? 0.0) * ligne['quantite']),
              ),
            );
      }
    });
  }
  
  /// Enregistre une vente brouillard via le serveur (mode CLIENT)
  Future<void> _enregistrerVenteBrouillardViaServeur({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required double totalTTC,
    required double? avance,
    required String? commercial,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
    String? heure,
  }) async {
    // 1. Insérer la vente
    await _databaseService.customStatement(
      'INSERT INTO ventes (numventes, nfact, daty, clt, modepai, totalttc, avance, commerc, remise, verification, heure) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [numVentes, nFacture, date.toIso8601String(), client, modePaiement, totalTTC, avance, commercial, remise, 'BROUILLARD', heure],
    );

    // 2. Insérer les détails
    for (final ligne in lignesVente) {
      await _databaseService.customStatement(
        'INSERT INTO detventes (numventes, designation, unites, depots, q, pu, daty, diffPrix) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          numVentes,
          ligne['designation'],
          ligne['unite'],
          ligne['depot'],
          ligne['quantite'],
          ligne['prixUnitaire'],
          date.toIso8601String(),
          (ligne['diffPrix'] ?? 0.0) * ligne['quantite'],
        ],
      );
    }
    
    debugPrint('✅ Vente brouillard $numVentes envoyée au serveur');
  }

  /// Traite une vente complète en mode JOURNAL avec toutes les opérations nécessaires
  Future<void> traiterVenteJournal({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalTTC,
    required double? avance,
    required String? commercial,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
    String? heure,
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
        totalTTC: totalTTC,
        avance: avance,
        commercial: commercial,
        remise: remise,
        heure: heure,
      );

      // 2. Traiter chaque ligne de vente
      for (final ligne in lignesVente) {
        await _traiterLigneVente(numVentes: numVentes, ligne: ligne, date: date, client: client);
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
        await _mouvementCaisse(numVentes: numVentes, montant: totalTTC, client: client, date: date);
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
    required double totalTTC,
    required double? avance,
    required String? commercial,
    required double? remise,
    String? heure,
  }) async {
    await _databaseService.database
        .into(_databaseService.database.ventes)
        .insert(
          VentesCompanion.insert(
            numventes: Value(numVentes),
            nfact: Value(nFacture),
            daty: Value(date),
            clt: Value(client),
            modepai: Value(modePaiement),
            echeance: Value(echeance),
            totalttc: Value(totalTTC),
            avance: Value(avance),
            commerc: Value(commercial),
            remise: Value(remise),
            verification: const Value('JOURNAL'),
            heure: Value(heure),
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
    await _databaseService.database
        .into(_databaseService.database.detventes)
        .insert(
          DetventesCompanion.insert(
            numventes: Value(numVentes),
            designation: Value(designation),
            unites: Value(unite),
            depots: Value(depot),
            q: Value(quantite),
            pu: Value(prixUnitaire),
            daty: Value(date),
            diffPrix: Value((diffPrix ?? 0.0) * quantite),
          ),
        );

    // 2. Récupérer l'article pour les conversions
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // 3. Réduire stocks par dépôt
    await _reduireStockDepot(article: article, depot: depot, unite: unite, quantite: quantite);

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
    await _ajusterStockGlobalArticle(article: article, unite: unite, quantite: quantite);

    // 6. Mettre à jour fiche stock
    await _mettreAJourFicheStock(designation: designation, unite: unite, quantite: quantite);
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
    final stockActuel = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

    if (stockActuel != null) {
      // Calculer nouveaux stocks
      final nouveauStockU1 = (stockActuel.stocksu1 ?? 0) - conversions['u1']!;
      final nouveauStockU2 = (stockActuel.stocksu2 ?? 0) - conversions['u2']!;
      final nouveauStockU3 = (stockActuel.stocksu3 ?? 0) - conversions['u3']!;

      // Mettre à jour
      await (_databaseService.database.update(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).write(
        DepartCompanion(
          stocksu1: Value(nouveauStockU1),
          stocksu2: Value(nouveauStockU2),
          stocksu3: Value(nouveauStockU3),
        ),
      );
    } else {
      // Créer l'entrée de stock avec des valeurs négatives (vente à découvert)
      await _databaseService.database
          .into(_databaseService.database.depart)
          .insert(
            DepartCompanion.insert(
              designation: article.designation,
              depots: depot,
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

    await _databaseService.database
        .into(_databaseService.database.stocks)
        .insert(
          StocksCompanion.insert(
            ref: ref,
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
            verification: const Value('VENTE'),
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
    await (_databaseService.database.update(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(article.designation))).write(
      ArticlesCompanion(
        stocksu1: Value(nouveauStockU1),
        stocksu2: Value(nouveauStockU2),
        stocksu3: Value(nouveauStockU3),
      ),
    );
  }

  /// Met à jour la fiche stock
  Future<void> _mettreAJourFicheStock({
    required String designation,
    required String unite,
    required double quantite,
  }) async {
    final ficheExiste = await (_databaseService.database.select(
      _databaseService.database.fstocks,
    )..where((f) => f.art.equals(designation))).getSingleOrNull();

    if (ficheExiste != null) {
      // Mettre à jour la fiche existante
      double nouvelleQs = (ficheExiste.qs ?? 0) + quantite;
      double nouvelleQst = (ficheExiste.qst ?? 0) + quantite;

      await (_databaseService.database.update(_databaseService.database.fstocks)
            ..where((f) => f.art.equals(designation)))
          .write(FstocksCompanion(qs: Value(nouvelleQs), qst: Value(nouvelleQst)));
    } else {
      // Créer nouvelle fiche
      final ref = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database
          .into(_databaseService.database.fstocks)
          .insert(
            FstocksCompanion.insert(
              ref: ref,
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

    await _databaseService.database
        .into(_databaseService.database.compteclt)
        .insert(
          ComptecltCompanion.insert(
            ref: ref,
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
    final clientData = await (_databaseService.database.select(
      _databaseService.database.clt,
    )..where((c) => c.rsoc.equals(client))).getSingleOrNull();

    if (clientData != null) {
      final nouveauSolde = (clientData.soldes ?? 0) + montant;
      await (_databaseService.database.update(_databaseService.database.clt)
            ..where((c) => c.rsoc.equals(client)))
          .write(CltCompanion(soldes: Value(nouveauSolde), datedernop: Value(date)));
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

    // Récupérer le dernier solde de caisse
    final dernierMouvement =
        await (_databaseService.database.select(_databaseService.database.caisse)
              ..orderBy([(c) => OrderingTerm.desc(c.daty)])
              ..limit(1))
            .getSingleOrNull();

    final dernierSolde = dernierMouvement?.soldes ?? 0.0;
    final nouveauSolde = dernierSolde + montant;

    final ref = 'V-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database
        .into(_databaseService.database.caisse)
        .insert(
          CaisseCompanion.insert(
            ref: ref,
            daty: Value(date),
            lib: Value('Vente N° $numVentes - Client: $client'),
            credit: Value(montant),
            soldes: Value(nouveauSolde),
            clt: Value(client ?? ''),
            type: const Value('Vente au comptant'),
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
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) return false;

    final stockDepot = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(designation) & d.depots.equals(depot))).getSingleOrNull();

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

  /// Valide une vente brouillard vers journal
  Future<void> validerVenteBrouillardVersJournal({
    required String numVentes,
    required String? nFacture,
    required String? client,
    required String? modePaiement,
    required double totalTTC,
    required double? avance,
    required double? remise,
  }) async {
    await _databaseService.database.transaction(() async {
      final currentUser = AuthService().currentUser;
      final validateur = currentUser?.nom ?? '';

      // Récupérer le vendeur original de la vente brouillard
      final venteBrouillard = await (_databaseService.database.select(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(numVentes))).getSingleOrNull();

      if (venteBrouillard == null) {
        throw Exception('Vente brouillard N° $numVentes non trouvée');
      }

      final vendeurOriginal = venteBrouillard.commerc ?? '';

      // Créer le champ commercial combiné : Vendeur + Validateur
      String commercialCombine;
      if (vendeurOriginal.isNotEmpty && vendeurOriginal != validateur) {
        commercialCombine = '$vendeurOriginal/$validateur';
      } else {
        commercialCombine = validateur;
      }

      // 1. Mettre à jour la vente vers JOURNAL
      await (_databaseService.database.update(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(numVentes))).write(
        VentesCompanion(
          nfact: Value(nFacture),
          clt: Value(client),
          modepai: Value(modePaiement),
          totalttc: Value(totalTTC),
          avance: Value(avance),
          remise: Value(remise),
          commerc: Value(commercialCombine),
          verification: const Value('JOURNAL'),
        ),
      );

      // 2. Récupérer les détails de vente
      final details = await (_databaseService.database.select(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(numVentes))).get();

      if (details.isEmpty) {
        throw Exception('Aucune ligne de vente trouvée pour N° $numVentes');
      }

      // 3. Traiter chaque ligne pour créer les mouvements de stock
      int ligneTraitee = 0;
      for (final detail in details) {
        try {
          if (detail.designation != null &&
              detail.depots != null &&
              detail.unites != null &&
              detail.q != null) {
            final article = await (_databaseService.database.select(
              _databaseService.database.articles,
            )..where((a) => a.designation.equals(detail.designation!))).getSingleOrNull();

            if (article == null) {
              throw Exception('Article ${detail.designation} non trouvé');
            }

            // Traiter la ligne de manière séquentielle pour éviter les conflits
            await _reduireStockDepot(
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            await _creerMouvementStock(
              numVentes: numVentes,
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
              prixUnitaire: detail.pu ?? 0.0,
              client: client,
              date: detail.daty ?? DateTime.now(),
            );

            // Recharger l'article pour avoir les stocks à jour
            final articleActuel = await (_databaseService.database.select(
              _databaseService.database.articles,
            )..where((a) => a.designation.equals(detail.designation!))).getSingleOrNull();
            
            if (articleActuel != null) {
              await _ajusterStockGlobalArticle(
                article: articleActuel, 
                unite: detail.unites!, 
                quantite: detail.q!,
              );
            }

            await _mettreAJourFicheStock(
              designation: detail.designation!,
              unite: detail.unites!,
              quantite: detail.q!,
            );
            
            ligneTraitee++;
          }
        } catch (e) {
          throw Exception('Erreur lors du traitement de la ligne ${ligneTraitee + 1} (${detail.designation}): $e');
        }
      }

      // Vérifier que toutes les lignes ont été traitées
      if (ligneTraitee != details.length) {
        throw Exception('Toutes les lignes n\'ont pas été traitées correctement ($ligneTraitee/${details.length})');
      }
      
      // Synchroniser les stocks globaux après traitement
      await _synchroniserStocksGlobaux(details);

      // 4. Ajuster compte client si crédit
      if (modePaiement == 'A crédit' && client != null && client.isNotEmpty) {
        await _ajusterCompteClient(
          client: client,
          numVentes: numVentes,
          nFacture: nFacture,
          montant: totalTTC - (avance ?? 0),
          date: DateTime.now(),
        );
      }

      // 5. Mouvement caisse si espèces
      if (modePaiement == 'Espèces') {
        await _mouvementCaisse(
          numVentes: numVentes, 
          montant: totalTTC, 
          client: client, 
          date: DateTime.now(),
        );
      }
    });
  }

  /// Enregistre une vente directement en mode JOURNAL
  Future<void> enregistrerVenteDirecteJournal({
    required String numVentes,
    required String? nFacture,
    required DateTime date,
    required String? client,
    required String? modePaiement,
    required double totalTTC,
    required double? avance,
    required String? commercial,
    required double? remise,
    required List<Map<String, dynamic>> lignesVente,
    String? heure,
  }) async {
    await traiterVenteJournal(
      numVentes: numVentes,
      nFacture: nFacture,
      date: date,
      client: client,
      modePaiement: modePaiement,
      echeance: null,
      totalTTC: totalTTC,
      avance: avance,
      commercial: commercial,
      remise: remise,
      lignesVente: lignesVente,
      heure: heure,
    );
  }

  /// Contre-passe une vente avec restauration complète
  Future<void> contrePasserVente(String numVentes) async {
    final vente = await (_databaseService.database.select(
      _databaseService.database.ventes,
    )..where((v) => v.numventes.equals(numVentes))).getSingleOrNull();

    if (vente == null) throw Exception('Vente non trouvée');

    final details = await (_databaseService.database.select(
      _databaseService.database.detventes,
    )..where((d) => d.numventes.equals(numVentes))).get();

    await _databaseService.database.transaction(() async {
      // 1. Restaurer stocks
      for (final detail in details) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          final article = await (_databaseService.database.select(
            _databaseService.database.articles,
          )..where((a) => a.designation.equals(detail.designation!))).getSingleOrNull();

          if (article != null) {
            await _restaurerStockDepot(
              article: article,
              depot: detail.depots!,
              unite: detail.unites!,
              quantite: detail.q!,
            );

            await _restaurerStockGlobal(article: article, unite: detail.unites!, quantite: detail.q!);

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
        await _decaissement(numVentes: numVentes, montant: vente.totalttc ?? 0, client: vente.clt);
      }

      // 4. Marquer la vente comme contre-passée
      await (_databaseService.database.update(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(numVentes))).write(const VentesCompanion(contre: Value("1")));
    });
  }

  /// Récupère les ventes en Journal (non contre-passées)
  Future<List<Vente>> getVentesJournal() async {
    return await (_databaseService.database.select(
      _databaseService.database.ventes,
    )..where((v) => v.verification.equals('JOURNAL') & (v.contre.isNull() | v.contre.equals("0")))).get();
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

    final stockActuel = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

    if (stockActuel != null) {
      await (_databaseService.database.update(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).write(
        DepartCompanion(
          stocksu1: Value((stockActuel.stocksu1 ?? 0) + conversions['u1']!),
          stocksu2: Value((stockActuel.stocksu2 ?? 0) + conversions['u2']!),
          stocksu3: Value((stockActuel.stocksu3 ?? 0) + conversions['u3']!),
        ),
      );
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

    await (_databaseService.database.update(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(article.designation))).write(
      ArticlesCompanion(
        stocksu1: Value((article.stocksu1 ?? 0) + conversions['u1']!),
        stocksu2: Value((article.stocksu2 ?? 0) + conversions['u2']!),
        stocksu3: Value((article.stocksu3 ?? 0) + conversions['u3']!),
      ),
    );
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

    await _databaseService.database
        .into(_databaseService.database.stocks)
        .insert(
          StocksCompanion.insert(
            ref: ref,
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
            verification: const Value('CP VENTE'),
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

    await _databaseService.database
        .into(_databaseService.database.compteclt)
        .insert(
          ComptecltCompanion.insert(
            ref: ref,
            clt: Value(client),
            daty: Value(DateTime.now()),
            lib: Value('Contre-passement vente N° $numVentes'),
            entres: const Value(0.0),
            sorties: Value(montant),
            solde: Value(-montant),
            verification: const Value('JOURNAL'),
          ),
        );

    final clientData = await (_databaseService.database.select(
      _databaseService.database.clt,
    )..where((c) => c.rsoc.equals(client))).getSingleOrNull();

    if (clientData != null) {
      await (_databaseService.database.update(
        _databaseService.database.clt,
      )..where((c) => c.rsoc.equals(client))).write(
        CltCompanion(soldes: Value((clientData.soldes ?? 0) - montant), datedernop: Value(DateTime.now())),
      );
    }
  }

  Future<void> _decaissement({
    required String numVentes,
    required double montant,
    required String? client,
  }) async {
    // Récupérer le dernier solde de caisse
    final dernierMouvement =
        await (_databaseService.database.select(_databaseService.database.caisse)
              ..orderBy([(c) => OrderingTerm.desc(c.daty)])
              ..limit(1))
            .getSingleOrNull();

    final dernierSolde = dernierMouvement?.soldes ?? 0.0;
    final nouveauSolde = dernierSolde - montant;

    final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database
        .into(_databaseService.database.caisse)
        .insert(
          CaisseCompanion.insert(
            ref: ref,
            daty: Value(DateTime.now()),
            lib: Value('Contre-passement vente N° $numVentes'),
            debit: Value(montant),
            soldes: Value(nouveauSolde),
            type: const Value("CP. Vente"),
            clt: Value(client ?? ''),
            verification: const Value('JOURNAL'),
          ),
        );
  }

  /// Synchronise les stocks globaux dans la table articles
  Future<void> _synchroniserStocksGlobaux(List<Detvente> details) async {
    // Récupérer tous les articles concernés
    final articlesTraites = <String>{};
    for (final detail in details) {
      if (detail.designation != null) {
        articlesTraites.add(detail.designation!);
      }
    }
    
    // Recalculer le stock global pour chaque article
    for (final designation in articlesTraites) {
      await _recalculerStockGlobalArticle(designation);
    }
  }
  
  /// Recalcule le stock global d'un article à partir des stocks par dépôt
  Future<void> _recalculerStockGlobalArticle(String designation) async {
    // Récupérer tous les stocks par dépôt pour cet article
    final stocksDepots = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(designation))).get();
    
    // Calculer les totaux
    double totalU1 = 0;
    double totalU2 = 0;
    double totalU3 = 0;
    
    for (final stock in stocksDepots) {
      totalU1 += stock.stocksu1 ?? 0;
      totalU2 += stock.stocksu2 ?? 0;
      totalU3 += stock.stocksu3 ?? 0;
    }
    
    // Mettre à jour l'article avec les totaux calculés
    await (_databaseService.database.update(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).write(
      ArticlesCompanion(
        stocksu1: Value(totalU1),
        stocksu2: Value(totalU2),
        stocksu3: Value(totalU3),
      ),
    );
  }

  /// Contre-passe une vente brouillard (suppression définitive)
  Future<void> contrePasserVenteBrouillard(String numVentes) async {
    final vente = await (_databaseService.database.select(
      _databaseService.database.ventes,
    )..where((v) => v.numventes.equals(numVentes) & v.verification.equals('BROUILLARD'))).getSingleOrNull();

    if (vente == null) throw Exception('Vente brouillard non trouvée');

    await _databaseService.database.transaction(() async {
      // 1. Supprimer les détails de vente
      await (_databaseService.database.delete(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(numVentes))).go();

      // 2. Supprimer la vente
      await (_databaseService.database.delete(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(numVentes))).go();
    });
  }

  /// Récupère les ventes brouillard
  Future<List<Vente>> getVentesBrouillard() async {
    return await (_databaseService.database.select(
      _databaseService.database.ventes,
    )..where((v) => v.verification.equals('BROUILLARD'))).get();
  }
}
