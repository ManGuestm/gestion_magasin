import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../utils/cmup_calculator.dart';
import '../utils/stock_converter.dart';

class AchatService {
  final DatabaseService _databaseService = DatabaseService();

  /// Traite un achat en mode BROUILLARD (sans mouvement de stock)
  Future<void> traiterAchatBrouillard({
    required String numAchats,
    required String? nFacture,
    required DateTime date,
    required String? fournisseur,
    required String? modePaiement,
    DateTime? echeance,
    required double totalTTC,
    required List<Map<String, dynamic>> lignesAchat,
  }) async {
    // 🔥 En mode CLIENT, envoyer au serveur via customStatement
    if (_databaseService.isNetworkMode) {
      await _traiterAchatBrouillardViaServeur(
        numAchats: numAchats,
        nFacture: nFacture,
        date: date,
        fournisseur: fournisseur,
        modePaiement: modePaiement,
        echeance: echeance,
        totalTTC: totalTTC,
        lignesAchat: lignesAchat,
      );
      return;
    }
    
    // Mode LOCAL/SERVER : enregistrer localement
    await _databaseService.database.transaction(() async {
      // 1. Insérer l'achat principal
      await _databaseService.database
          .into(_databaseService.database.achats)
          .insert(
            AchatsCompanion.insert(
              numachats: Value(numAchats),
              nfact: Value(nFacture),
              daty: Value(date),
              frns: Value(fournisseur),
              modepai: Value(modePaiement),
              echeance: Value(echeance),
              totalttc: Value(totalTTC),
              verification: const Value('BROUILLARD'),
            ),
          );

      // 2. Insérer les détails sans affecter les stocks
      for (final ligne in lignesAchat) {
        await _databaseService.database
            .into(_databaseService.database.detachats)
            .insert(
              DetachatsCompanion.insert(
                numachats: Value(numAchats),
                designation: Value(ligne['designation']),
                unites: Value(ligne['unite']),
                depots: Value(ligne['depot']),
                q: Value(ligne['quantite']),
                pu: Value(ligne['prixUnitaire']),
                daty: Value(date),
              ),
            );
      }
    });
  }
  
  /// Traite un achat brouillard via le serveur (mode CLIENT)
  Future<void> _traiterAchatBrouillardViaServeur({
    required String numAchats,
    required String? nFacture,
    required DateTime date,
    required String? fournisseur,
    required String? modePaiement,
    DateTime? echeance,
    required double totalTTC,
    required List<Map<String, dynamic>> lignesAchat,
  }) async {
    // 1. Insérer l'achat
    await _databaseService.customStatement(
      'INSERT INTO achats (numachats, nfact, daty, frns, modepai, echeance, totalttc, verification) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [numAchats, nFacture, date.toIso8601String(), fournisseur, modePaiement, echeance?.toIso8601String(), totalTTC, 'BROUILLARD'],
    );

    // 2. Insérer les détails
    for (final ligne in lignesAchat) {
      await _databaseService.customStatement(
        'INSERT INTO detachats (numachats, designation, unites, depots, q, pu, daty) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          numAchats,
          ligne['designation'],
          ligne['unite'],
          ligne['depot'],
          ligne['quantite'],
          ligne['prixUnitaire'],
          date.toIso8601String(),
        ],
      );
    }
    
    debugPrint('✅ Achat brouillard $numAchats envoyé au serveur');
  }

  /// Traite un achat complet en mode JOURNAL avec mouvements de stock
  Future<void> traiterAchatJournal({
    required String numAchats,
    required String? nFacture,
    required DateTime date,
    required String? fournisseur,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalTTC,
    required List<Map<String, dynamic>> lignesAchat,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Insérer l'achat principal
      await _insererAchat(
        numAchats: numAchats,
        nFacture: nFacture,
        date: date,
        fournisseur: fournisseur,
        modePaiement: modePaiement,
        echeance: echeance,
        totalTTC: totalTTC,
      );

      // 2. Traiter chaque ligne d'achat
      for (final ligne in lignesAchat) {
        await _traiterLigneAchat(numAchats: numAchats, ligne: ligne, date: date, fournisseur: fournisseur);
      }

      // 3. Ajuster compte fournisseur si crédit
      if (modePaiement == 'A crédit' && fournisseur != null && fournisseur.isNotEmpty) {
        await _ajusterCompteFournisseur(
          fournisseur: fournisseur,
          numAchats: numAchats,
          nFacture: nFacture,
          montant: totalTTC,
          date: date,
        );
      }

      // 4. Mouvement caisse si espèces
      if (modePaiement == 'Espèces') {
        await _mouvementCaisseAchat(
          numAchats: numAchats,
          montant: totalTTC,
          fournisseur: fournisseur,
          date: date,
        );
      }
    });
  }

  /// Insère l'achat principal
  Future<void> _insererAchat({
    required String numAchats,
    required String? nFacture,
    required DateTime date,
    required String? fournisseur,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalTTC,
  }) async {
    await _databaseService.database
        .into(_databaseService.database.achats)
        .insert(
          AchatsCompanion.insert(
            numachats: Value(numAchats),
            nfact: Value(nFacture),
            daty: Value(date),
            frns: Value(fournisseur),
            modepai: Value(modePaiement),
            echeance: Value(echeance),
            totalttc: Value(totalTTC),
            verification: const Value('JOURNAL'),
          ),
        );
  }

  /// Traite une ligne d'achat individuelle
  Future<void> _traiterLigneAchat({
    required String numAchats,
    required Map<String, dynamic> ligne,
    required DateTime date,
    required String? fournisseur,
  }) async {
    final designation = ligne['designation'] as String;
    final unite = ligne['unite'] as String;
    final depot = ligne['depot'] as String;
    final quantite = ligne['quantite'] as double;
    final prixUnitaire = ligne['prixUnitaire'] as double;

    // 1. Insérer détail achat
    await _databaseService.database
        .into(_databaseService.database.detachats)
        .insert(
          DetachatsCompanion.insert(
            numachats: Value(numAchats),
            designation: Value(designation),
            unites: Value(unite),
            depots: Value(depot),
            q: Value(quantite),
            pu: Value(prixUnitaire),
            daty: Value(date),
          ),
        );

    // 2. Récupérer l'article
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // 3. Augmenter stocks par dépôt
    await _augmenterStockDepot(article: article, depot: depot, unite: unite, quantite: quantite);

    // 4. Calculer et mettre à jour le CMUP
    final nouveauCMUP = await _calculerEtMettreAJourCMUP(
      article: article,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
    );

    // 5. Créer mouvement stock d'entrée avec le CMUP calculé
    await _creerMouvementStockAchat(
      numAchats: numAchats,
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      fournisseur: fournisseur,
      date: date,
      cmup: nouveauCMUP,
    );

    // 6. Ajuster stock global article
    await _ajusterStockGlobalArticleAchat(article: article, unite: unite, quantite: quantite);

    // 7. Mettre à jour fiche stock
    await _mettreAJourFicheStockAchat(designation: designation, unite: unite, quantite: quantite);
  }

  /// Augmente le stock dans la table depart
  Future<void> _augmenterStockDepot({
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
      final nouveauStockU1 = (stockActuel.stocksu1 ?? 0) + conversions['u1']!;
      final nouveauStockU2 = (stockActuel.stocksu2 ?? 0) + conversions['u2']!;
      final nouveauStockU3 = (stockActuel.stocksu3 ?? 0) + conversions['u3']!;

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
      // Créer nouveau stock si n'existe pas
      await _databaseService.database
          .into(_databaseService.database.depart)
          .insert(
            DepartCompanion.insert(
              designation: article.designation,
              depots: depot,
              stocksu1: Value(conversions['u1']),
              stocksu2: Value(conversions['u2']),
              stocksu3: Value(conversions['u3']),
            ),
          );
    }
  }

  /// Crée un mouvement de stock d'entrée
  Future<void> _creerMouvementStockAchat({
    required String numAchats,
    required Article article,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
    required String? fournisseur,
    required DateTime date,
    required double cmup,
  }) async {
    // Générer une référence unique avec délai pour éviter les doublons
    await Future.delayed(const Duration(milliseconds: 1));
    final cleanDesignation = article.designation.replaceAll(' ', '');
    final maxLength = cleanDesignation.length > 10 ? 10 : cleanDesignation.length;
    final ref = 'A-${DateTime.now().millisecondsSinceEpoch}-${cleanDesignation.substring(0, maxLength)}';

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
            lib: Value('Achat N° $numAchats'),
            numachats: Value(numAchats),
            refart: Value(article.designation),
            qe: Value(quantite),
            entres: Value(quantite * prixUnitaire),
            stocksu1: Value(conversions['u1']),
            stocksu2: Value(conversions['u2']),
            stocksu3: Value(conversions['u3']),
            depots: Value(depot),
            frns: Value(fournisseur),
            verification: const Value('ACHAT'),
            ue: Value(unite),
            pue: Value(prixUnitaire),
            pus: Value(prixUnitaire),
            cmup: Value(cmup),
          ),
        );
  }

  /// Ajuste le stock global de l'article
  Future<void> _ajusterStockGlobalArticleAchat({
    required Article article,
    required String unite,
    required double quantite,
  }) async {
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    final nouveauStockU1 = (article.stocksu1 ?? 0) + conversions['u1']!;
    final nouveauStockU2 = (article.stocksu2 ?? 0) + conversions['u2']!;
    final nouveauStockU3 = (article.stocksu3 ?? 0) + conversions['u3']!;

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

  /// Ajuste le compte fournisseur pour achat à crédit
  Future<void> _ajusterCompteFournisseur({
    required String fournisseur,
    required String numAchats,
    required String? nFacture,
    required double montant,
    required DateTime date,
  }) async {
    if (montant <= 0) return;

    // Générer une référence unique avec délai
    await Future.delayed(const Duration(milliseconds: 1));
    final ref = 'A-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database
        .into(_databaseService.database.comptefrns)
        .insert(
          ComptefrnsCompanion.insert(
            ref: ref,
            daty: Value(date),
            lib: Value('Achat N° $numAchats${nFacture != null ? ' - Facture $nFacture' : ''}'),
            numachats: Value(numAchats),
            nfact: Value(nFacture),
            entres: Value(montant),
            sortie: const Value(0.0),
            solde: Value(montant),
            frns: Value(fournisseur),
            verification: const Value('JOURNAL'),
          ),
        );

    // Mettre à jour le solde fournisseur
    final fournisseurData = await (_databaseService.database.select(
      _databaseService.database.frns,
    )..where((f) => f.rsoc.equals(fournisseur))).getSingleOrNull();

    if (fournisseurData != null) {
      final nouveauSolde = (fournisseurData.soldes ?? 0) + montant;
      await (_databaseService.database.update(_databaseService.database.frns)
            ..where((f) => f.rsoc.equals(fournisseur)))
          .write(FrnsCompanion(soldes: Value(nouveauSolde), datedernop: Value(date)));
    }
  }

  /// Crée un mouvement de caisse pour paiement espèces
  Future<void> _mouvementCaisseAchat({
    required String numAchats,
    required double montant,
    required String? fournisseur,
    required DateTime date,
  }) async {
    if (montant <= 0) return;

    final ref = 'A-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    await _databaseService.database
        .into(_databaseService.database.caisse)
        .insert(
          CaisseCompanion.insert(
            ref: ref,
            daty: Value(date),
            lib: Value('Achat N° $numAchats | Fournisseur: $fournisseur'),
            credit: Value(montant),
            frns: Value(fournisseur ?? ''),
            type: const Value("Règlement Fournisseur"),
            verification: const Value('JOURNAL'),
          ),
        );
  }

  /// Valide un achat brouillard vers journal
  Future<void> validerAchatBrouillard(String numAchats) async {
    // 🔥 En mode CLIENT, envoyer au serveur via customStatement
    if (_databaseService.isNetworkMode) {
      await _validerAchatBrouillardViaServeur(numAchats);
      return;
    }
    
    // Mode LOCAL/SERVER : traiter localement
    final achat = await (_databaseService.database.select(
      _databaseService.database.achats,
    )..where((a) => a.numachats.equals(numAchats))).getSingleOrNull();

    if (achat == null) {
      throw Exception('Achat non trouvé');
    }

    final details = await (_databaseService.database.select(
      _databaseService.database.detachats,
    )..where((d) => d.numachats.equals(numAchats))).get();

    await _databaseService.database.transaction(() async {
      // Mettre à jour le statut de l'achat
      await (_databaseService.database.update(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(numAchats)))
          .write(const AchatsCompanion(verification: Value('JOURNAL')));

      // Traiter chaque ligne pour créer SEULEMENT les mouvements de stock (pas réinsérer detachats)
      for (final detail in details) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          await _traiterLigneAchatSansDetail(
            numAchats: numAchats,
            ligne: {
              'designation': detail.designation!,
              'unite': detail.unites!,
              'depot': detail.depots!,
              'quantite': detail.q!,
              'prixUnitaire': detail.pu ?? 0.0,
            },
            date: achat.daty ?? DateTime.now(),
            fournisseur: achat.frns,
          );
        }
      }
      
      // Synchroniser les stocks globaux après traitement
      await _synchroniserStocksGlobauxAchat(details);

      // Ajuster compte fournisseur si crédit
      if (achat.modepai == 'A crédit' && achat.frns != null && achat.frns!.isNotEmpty) {
        await _ajusterCompteFournisseur(
          fournisseur: achat.frns!,
          numAchats: numAchats,
          nFacture: achat.nfact,
          montant: achat.totalttc ?? 0,
          date: achat.daty ?? DateTime.now(),
        );
      }

      // Mouvement caisse si espèces
      if (achat.modepai == 'Espèces') {
        await _mouvementCaisseAchat(
          numAchats: numAchats,
          montant: achat.totalttc ?? 0,
          fournisseur: achat.frns,
          date: achat.daty ?? DateTime.now(),
        );
      }
    });
  }

  /// Traite une ligne d'achat sans réinsérer le détail (pour validation brouillard)
  Future<void> _traiterLigneAchatSansDetail({
    required String numAchats,
    required Map<String, dynamic> ligne,
    required DateTime date,
    required String? fournisseur,
  }) async {
    final designation = ligne['designation'] as String;
    final unite = ligne['unite'] as String;
    final depot = ligne['depot'] as String;
    final quantite = ligne['quantite'] as double;
    final prixUnitaire = ligne['prixUnitaire'] as double;

    // Récupérer l'article
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // Augmenter stocks par dépôt
    await _augmenterStockDepot(article: article, depot: depot, unite: unite, quantite: quantite);

    // Calculer et mettre à jour le CMUP
    final nouveauCMUP = await _calculerEtMettreAJourCMUP(
      article: article,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
    );

    // Créer mouvement stock d'entrée avec le CMUP calculé
    await _creerMouvementStockAchat(
      numAchats: numAchats,
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      fournisseur: fournisseur,
      date: date,
      cmup: nouveauCMUP,
    );

    // Ajuster stock global article
    await _ajusterStockGlobalArticleAchat(article: article, unite: unite, quantite: quantite);

    // Mettre à jour fiche stock
    await _mettreAJourFicheStockAchat(designation: designation, unite: unite, quantite: quantite);
  }

  /// Calcule et met à jour le CMUP de l'article
  Future<double> _calculerEtMettreAJourCMUP({
    required Article article,
    required String unite,
    required double quantite,
    required double prixUnitaire,
  }) async {
    // Utiliser le calculateur CMUP amélioré qui gère correctement les unités
    return await CMUPCalculator.calculerEtMettreAJourCMUP(
      designation: article.designation,
      uniteAchat: unite,
      quantiteAchat: quantite,
      prixUnitaireAchat: prixUnitaire,
      article: article,
    );
  }

  /// Met à jour la fiche stock pour les achats
  Future<void> _mettreAJourFicheStockAchat({
    required String designation,
    required String unite,
    required double quantite,
  }) async {
    final ficheExiste = await (_databaseService.database.select(
      _databaseService.database.fstocks,
    )..where((f) => f.art.equals(designation))).getSingleOrNull();

    if (ficheExiste != null) {
      // Mettre à jour la fiche existante - pour les achats on augmente qe (entrées)
      double nouvelleQe = (ficheExiste.qe ?? 0) + quantite;

      await (_databaseService.database.update(
        _databaseService.database.fstocks,
      )..where((f) => f.art.equals(designation))).write(FstocksCompanion(qe: Value(nouvelleQe)));
    } else {
      // Créer nouvelle fiche avec référence unique
      // Ajouter un délai pour éviter les doublons de timestamp
      await Future.delayed(const Duration(milliseconds: 1));
      final ref = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database
          .into(_databaseService.database.fstocks)
          .insert(
            FstocksCompanion.insert(
              ref: ref,
              art: Value(designation),
              qe: Value(quantite),
              qs: const Value(0.0), // Pas de sortie pour un achat
              qst: const Value(0.0),
              ue: Value(unite),
            ),
          );
    }
  }

  /// Synchronise les stocks globaux dans la table articles après achat
  Future<void> _synchroniserStocksGlobauxAchat(List<Detachat> details) async {
    // Récupérer tous les articles concernés
    final articlesTraites = <String>{};
    for (final detail in details) {
      if (detail.designation != null) {
        articlesTraites.add(detail.designation!);
      }
    }
    
    // Recalculer le stock global pour chaque article
    for (final designation in articlesTraites) {
      await _recalculerStockGlobalArticleAchat(designation);
    }
  }
  
  /// Recalcule le stock global d'un article à partir des stocks par dépôt
  Future<void> _recalculerStockGlobalArticleAchat(String designation) async {
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

  /// Valide un achat brouillard via le serveur (mode CLIENT)
  Future<void> _validerAchatBrouillardViaServeur(String numAchats) async {
    // Mettre à jour le statut vers JOURNAL
    await _databaseService.customStatement(
      'UPDATE achats SET verification = ? WHERE numachats = ?',
      ['JOURNAL', numAchats],
    );
    
    debugPrint('✅ Achat brouillard $numAchats validé via serveur');
  }

  /// Contre-passe un achat brouillard (suppression définitive)
  Future<void> contrePasserAchatBrouillard(String numAchats) async {
    // 🔥 En mode CLIENT, envoyer au serveur via customStatement
    if (_databaseService.isNetworkMode) {
      await _contrePasserAchatBrouillardViaServeur(numAchats);
      return;
    }
    
    // Mode LOCAL/SERVER : traiter localement
    await _databaseService.database.transaction(() async {
      // Supprimer les détails
      await (_databaseService.database.delete(
        _databaseService.database.detachats,
      )..where((d) => d.numachats.equals(numAchats))).go();

      // Supprimer l'achat principal
      await (_databaseService.database.delete(
        _databaseService.database.achats,
      )..where((a) => a.numachats.equals(numAchats))).go();
    });
  }
  
  /// Contre-passe un achat brouillard via le serveur (mode CLIENT)
  Future<void> _contrePasserAchatBrouillardViaServeur(String numAchats) async {
    // Supprimer les détails
    await _databaseService.customStatement(
      'DELETE FROM detachats WHERE numachats = ?',
      [numAchats],
    );
    
    // Supprimer l'achat principal
    await _databaseService.customStatement(
      'DELETE FROM achats WHERE numachats = ?',
      [numAchats],
    );
    
    debugPrint('✅ Achat brouillard $numAchats supprimé via serveur');
  }

  /// Contre-passe un achat journalisé
  Future<void> contrePasserAchatJournal(String numAchats) async {
    // 🔥 En mode CLIENT, envoyer au serveur via customStatement
    if (_databaseService.isNetworkMode) {
      await _contrePasserAchatJournalViaServeur(numAchats);
      return;
    }
    
    // Mode LOCAL/SERVER : traiter localement
    final achat = await (_databaseService.database.select(
      _databaseService.database.achats,
    )..where((a) => a.numachats.equals(numAchats))).getSingleOrNull();

    if (achat == null) throw Exception('Achat non trouvé');
    if (achat.contre == '1') throw Exception('Achat déjà contre-passé');
    if (achat.verification != 'JOURNAL') {
      throw Exception('Seuls les achats journalisés peuvent être contre-passés');
    }

    // Récupérer les détails de l'achat pour ajuster les stocks
    final details = await (_databaseService.database.select(
      _databaseService.database.detachats,
    )..where((d) => d.numachats.equals(numAchats))).get();

    await _databaseService.database.transaction(() async {
      // 1. Marquer comme contre-passé
      await (_databaseService.database.update(
        _databaseService.database.achats,
      )..where((a) => a.numachats.equals(numAchats))).write(const AchatsCompanion(contre: Value('1')));

      // 2. Ajuster les stocks pour chaque ligne d'achat (diminuer les stocks)
      for (final detail in details) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          await _diminuerStocksContrePassement(
            designation: detail.designation!,
            depot: detail.depots!,
            unite: detail.unites!,
            quantite: detail.q!,
            prixUnitaire: detail.pu ?? 0.0,
          );
        }
      }

      // 3. Créer mouvement de stock de sortie pour contre-passement
      for (final detail in details) {
        if (detail.designation != null &&
            detail.depots != null &&
            detail.unites != null &&
            detail.q != null) {
          await _creerMouvementStockContrePassement(
            numAchats: numAchats,
            designation: detail.designation!,
            depot: detail.depots!,
            unite: detail.unites!,
            quantite: detail.q!,
            prixUnitaire: detail.pu ?? 0.0,
            fournisseur: achat.frns,
          );
        }
      }

      // 4. Ajuster compte fournisseur (sortie pour annuler l'entrée)
      if (achat.frns != null && achat.frns!.isNotEmpty) {
        final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';
        await _databaseService.database
            .into(_databaseService.database.comptefrns)
            .insert(
              ComptefrnsCompanion.insert(
                ref: ref,
                daty: Value(DateTime.now()),
                lib: Value('Contre-passement achat N° $numAchats'),
                numachats: Value(numAchats),
                sortie: Value(achat.totalttc ?? 0),
                solde: Value(-(achat.totalttc ?? 0)),
                frns: Value(achat.frns!),
                verification: const Value('JOURNAL'),
              ),
            );

        // Mettre à jour solde fournisseur
        final fournisseur = await (_databaseService.database.select(
          _databaseService.database.frns,
        )..where((f) => f.rsoc.equals(achat.frns!))).getSingleOrNull();
        if (fournisseur != null) {
          await (_databaseService.database.update(
            _databaseService.database.frns,
          )..where((f) => f.rsoc.equals(achat.frns!))).write(
            FrnsCompanion(
              soldes: Value((fournisseur.soldes ?? 0) - (achat.totalttc ?? 0)),
              datedernop: Value(DateTime.now()),
            ),
          );
        }
      }

      // 5. Mouvement caisse si paiement espèces (entrée pour récupérer l'argent)
      if (achat.modepai == 'Espèces') {
        final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';
        await _databaseService.database
            .into(_databaseService.database.caisse)
            .insert(
              CaisseCompanion.insert(
                ref: ref,
                daty: Value(DateTime.now()),
                lib: Value('Contre-passement achat N° $numAchats'),
                debit: Value(achat.totalttc ?? 0),
                frns: Value(achat.frns ?? ''),
                verification: const Value('JOURNAL'),
              ),
            );
      }
    });
  }

  /// Diminue les stocks lors du contre-passement d'un achat
  Future<void> _diminuerStocksContrePassement({
    required String designation,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
  }) async {
    // Récupérer l'article
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // Convertir la quantité à diminuer
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    // Diminuer stock global de l'article
    final nouveauStockU1 = ((article.stocksu1 ?? 0) - conversions['u1']!).clamp(0.0, double.infinity);
    final nouveauStockU2 = ((article.stocksu2 ?? 0) - conversions['u2']!).clamp(0.0, double.infinity);
    final nouveauStockU3 = ((article.stocksu3 ?? 0) - conversions['u3']!).clamp(0.0, double.infinity);

    await (_databaseService.database.update(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).write(
      ArticlesCompanion(
        stocksu1: Value(nouveauStockU1),
        stocksu2: Value(nouveauStockU2),
        stocksu3: Value(nouveauStockU3),
      ),
    );

    // Diminuer stock par dépôt
    final stockDepot = await (_databaseService.database.select(
      _databaseService.database.depart,
    )..where((d) => d.designation.equals(designation) & d.depots.equals(depot))).getSingleOrNull();

    if (stockDepot != null) {
      final nouveauStockDepotU1 = ((stockDepot.stocksu1 ?? 0) - conversions['u1']!).clamp(
        0.0,
        double.infinity,
      );
      final nouveauStockDepotU2 = ((stockDepot.stocksu2 ?? 0) - conversions['u2']!).clamp(
        0.0,
        double.infinity,
      );
      final nouveauStockDepotU3 = ((stockDepot.stocksu3 ?? 0) - conversions['u3']!).clamp(
        0.0,
        double.infinity,
      );

      await (_databaseService.database.update(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(designation) & d.depots.equals(depot))).write(
        DepartCompanion(
          stocksu1: Value(nouveauStockDepotU1),
          stocksu2: Value(nouveauStockDepotU2),
          stocksu3: Value(nouveauStockDepotU3),
        ),
      );
    }

    // Mettre à jour la fiche stock pour le contre-passement
    await _mettreAJourFicheStockContrePassement(designation: designation, unite: unite, quantite: quantite);

    // Recalculer le CMUP après diminution du stock
    await _recalculerCMUPApresContrePassement(article, quantite, prixUnitaire);
  }

  /// Crée un mouvement de stock de sortie pour le contre-passement
  Future<void> _creerMouvementStockContrePassement({
    required String numAchats,
    required String designation,
    required String depot,
    required String unite,
    required double quantite,
    required double prixUnitaire,
    required String? fournisseur,
  }) async {
    // Générer une référence unique avec délai
    await Future.delayed(const Duration(milliseconds: 1));
    final cleanDesignation = designation.replaceAll(' ', '');
    final maxLength = cleanDesignation.length > 10 ? 10 : cleanDesignation.length;
    final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}-${cleanDesignation.substring(0, maxLength)}';

    // Récupérer l'article pour les conversions
    final article = await (_databaseService.database.select(
      _databaseService.database.articles,
    )..where((a) => a.designation.equals(designation))).getSingleOrNull();

    if (article == null) return;

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
            lib: Value('Contre-passement achat N° $numAchats'),
            numachats: Value(numAchats),
            refart: Value(designation),
            qs: Value(quantite), // Sortie
            sortie: Value(quantite * prixUnitaire),
            stocksu1: Value(-conversions['u1']!), // Négatif pour sortie
            stocksu2: Value(-conversions['u2']!),
            stocksu3: Value(-conversions['u3']!),
            depots: Value(depot),
            frns: Value(fournisseur),
            verification: const Value('CP ACHAT'),
            us: Value(unite),
            pue: Value(prixUnitaire),
            pus: Value(prixUnitaire),
            cmup: Value(article.cmup ?? 0.0),
          ),
        );
  }

  /// Met à jour la fiche stock pour les contre-passements
  Future<void> _mettreAJourFicheStockContrePassement({
    required String designation,
    required String unite,
    required double quantite,
  }) async {
    final ficheExiste = await (_databaseService.database.select(
      _databaseService.database.fstocks,
    )..where((f) => f.art.equals(designation))).getSingleOrNull();

    if (ficheExiste != null) {
      // Mettre à jour la fiche existante - pour les contre-passements on augmente qs (sorties)
      double nouvelleQs = (ficheExiste.qs ?? 0) + quantite;

      await (_databaseService.database.update(
        _databaseService.database.fstocks,
      )..where((f) => f.art.equals(designation))).write(FstocksCompanion(qs: Value(nouvelleQs)));
    } else {
      // Créer nouvelle fiche avec sortie et référence unique
      // Ajouter un délai pour éviter les doublons de timestamp
      await Future.delayed(const Duration(milliseconds: 1));
      final ref = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database
          .into(_databaseService.database.fstocks)
          .insert(
            FstocksCompanion.insert(
              ref: ref,
              art: Value(designation),
              qe: const Value(0.0),
              qs: Value(quantite), // Sortie pour contre-passement
              qst: const Value(0.0),
              ue: Value(unite),
            ),
          );
    }
  }

  /// Recalcule le CMUP après contre-passement
  Future<void> _recalculerCMUPApresContrePassement(
    Article article,
    double quantiteRetiree,
    double prixUnitaireRetire,
  ) async {
    // Calculer le stock total actuel en unité de base (u3)
    double stockActuelU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: article.stocksu1 ?? 0,
      stockU2: article.stocksu2 ?? 0,
      stockU3: article.stocksu3 ?? 0,
    );

    double cmupActuel = article.cmup ?? 0.0;

    // Si plus de stock, conserver le CMUP actuel (pas de mise à jour)
    if (stockActuelU3 <= 0) {
      return; // Conserver le CMUP existant pour le prochain achat
    }

    // Calculer la valeur totale avant retrait
    double stockAvantRetrait = stockActuelU3 + quantiteRetiree;
    double valeurTotaleAvant = stockAvantRetrait * cmupActuel;
    double valeurRetiree = quantiteRetiree * prixUnitaireRetire;
    double nouvelleValeur = valeurTotaleAvant - valeurRetiree;

    // Nouveau CMUP
    double nouveauCMUP = nouvelleValeur / stockActuelU3;
    nouveauCMUP = nouveauCMUP.clamp(0.0, double.infinity);

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(cmup: Value(nouveauCMUP)));
  }
  
  /// Contre-passe un achat journalisé via le serveur (mode CLIENT)
  Future<void> _contrePasserAchatJournalViaServeur(String numAchats) async {
    // Marquer comme contre-passé
    await _databaseService.customStatement(
      'UPDATE achats SET contre = ? WHERE numachats = ?',
      ['1', numAchats],
    );
    
    debugPrint('✅ Achat journal $numAchats contre-passé via serveur');
  }
}
