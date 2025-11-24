import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';
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
    required double totalHT,
    required double totalTTC,
    required double tva,
    required List<Map<String, dynamic>> lignesAchat,
  }) async {
    await _databaseService.database.transaction(() async {
      // 1. Insérer l'achat principal
      await _databaseService.database.into(_databaseService.database.achats).insert(
            AchatsCompanion.insert(
              numachats: Value(numAchats),
              nfact: Value(nFacture),
              daty: Value(date),
              frns: Value(fournisseur),
              modepai: Value(modePaiement),
              totalnt: Value(totalHT),
              totalttc: Value(totalTTC),
              tva: Value(tva),
              verification: const Value('BROUILLARD'),
            ),
          );

      // 2. Insérer les détails sans affecter les stocks
      for (final ligne in lignesAchat) {
        await _databaseService.database.into(_databaseService.database.detachats).insert(
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

  /// Traite un achat complet en mode JOURNAL avec mouvements de stock
  Future<void> traiterAchatJournal({
    required String numAchats,
    required String? nFacture,
    required DateTime date,
    required String? fournisseur,
    required String? modePaiement,
    required DateTime? echeance,
    required double totalHT,
    required double totalTTC,
    required double tva,
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
        totalHT: totalHT,
        totalTTC: totalTTC,
        tva: tva,
      );

      // 2. Traiter chaque ligne d'achat
      for (final ligne in lignesAchat) {
        await _traiterLigneAchat(
          numAchats: numAchats,
          ligne: ligne,
          date: date,
          fournisseur: fournisseur,
        );
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
    required double totalHT,
    required double totalTTC,
    required double tva,
  }) async {
    await _databaseService.database.into(_databaseService.database.achats).insert(
          AchatsCompanion.insert(
            numachats: Value(numAchats),
            nfact: Value(nFacture),
            daty: Value(date),
            frns: Value(fournisseur),
            modepai: Value(modePaiement),
            echeance: Value(echeance),
            totalnt: Value(totalHT),
            totalttc: Value(totalTTC),
            tva: Value(tva),
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
    await _databaseService.database.into(_databaseService.database.detachats).insert(
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
    final article = await (_databaseService.database.select(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // 3. Augmenter stocks par dépôt
    await _augmenterStockDepot(
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
    );

    // 4. Créer mouvement stock d'entrée
    await _creerMouvementStockAchat(
      numAchats: numAchats,
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      fournisseur: fournisseur,
      date: date,
    );

    // 5. Calculer et mettre à jour le CMUP
    await _calculerEtMettreAJourCMUP(
      article: article,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
    );

    // 6. Ajuster stock global article
    await _ajusterStockGlobalArticleAchat(
      article: article,
      unite: unite,
      quantite: quantite,
    );

    // 7. Mettre à jour fiche stock
    await _mettreAJourFicheStockAchat(
      designation: designation,
      unite: unite,
      quantite: quantite,
    );
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

    final stockActuel = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (stockActuel != null) {
      final nouveauStockU1 = (stockActuel.stocksu1 ?? 0) + conversions['u1']!;
      final nouveauStockU2 = (stockActuel.stocksu2 ?? 0) + conversions['u2']!;
      final nouveauStockU3 = (stockActuel.stocksu3 ?? 0) + conversions['u3']!;

      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: Value(nouveauStockU1),
        stocksu2: Value(nouveauStockU2),
        stocksu3: Value(nouveauStockU3),
      ));
    } else {
      // Créer nouveau stock si n'existe pas
      await _databaseService.database.into(_databaseService.database.depart).insert(
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
  }) async {
    final ref = 'A-${DateTime.now().millisecondsSinceEpoch}-${article.designation}';

    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    await _databaseService.database.into(_databaseService.database.stocks).insert(
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
            verification: const Value('JOURNAL'),
            ue: Value(unite),
            pus: Value(prixUnitaire),
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

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(
      stocksu1: Value(nouveauStockU1),
      stocksu2: Value(nouveauStockU2),
      stocksu3: Value(nouveauStockU3),
    ));
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

    final ref = 'A-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.comptefrns).insert(
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
    final fournisseurData = await (_databaseService.database.select(_databaseService.database.frns)
          ..where((f) => f.rsoc.equals(fournisseur)))
        .getSingleOrNull();

    if (fournisseurData != null) {
      final nouveauSolde = (fournisseurData.soldes ?? 0) + montant;
      await (_databaseService.database.update(_databaseService.database.frns)
            ..where((f) => f.rsoc.equals(fournisseur)))
          .write(FrnsCompanion(
        soldes: Value(nouveauSolde),
        datedernop: Value(date),
      ));
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

    final ref = 'A-${DateTime.now().millisecondsSinceEpoch}';

    await _databaseService.database.into(_databaseService.database.caisse).insert(
          CaisseCompanion.insert(
            ref: ref,
            daty: Value(date),
            lib: Value('Achat N° $numAchats | Fournisseur: $fournisseur'),
            credit: Value(montant),
            frns: Value(fournisseur ?? ''),
            type: Value("Règlement Fournisseur"),
            verification: const Value('JOURNAL'),
          ),
        );
  }

  /// Valide un achat brouillard vers journal
  Future<void> validerAchatBrouillard(String numAchats) async {
    final achat = await (_databaseService.database.select(_databaseService.database.achats)
          ..where((a) => a.numachats.equals(numAchats)))
        .getSingleOrNull();

    if (achat == null) {
      throw Exception('Achat non trouvé');
    }

    final details = await (_databaseService.database.select(_databaseService.database.detachats)
          ..where((d) => d.numachats.equals(numAchats)))
        .get();

    await _databaseService.database.transaction(() async {
      // Mettre à jour le statut de l'achat
      await (_databaseService.database.update(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(numAchats)))
          .write(const AchatsCompanion(
        verification: Value('JOURNAL'),
      ));

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
    final article = await (_databaseService.database.select(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .getSingleOrNull();

    if (article == null) {
      throw Exception('Article $designation non trouvé');
    }

    // Augmenter stocks par dépôt
    await _augmenterStockDepot(
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
    );

    // Créer mouvement stock d'entrée
    await _creerMouvementStockAchat(
      numAchats: numAchats,
      article: article,
      depot: depot,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      fournisseur: fournisseur,
      date: date,
    );

    // Calculer et mettre à jour le CMUP
    await _calculerEtMettreAJourCMUP(
      article: article,
      unite: unite,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
    );

    // Ajuster stock global article
    await _ajusterStockGlobalArticleAchat(
      article: article,
      unite: unite,
      quantite: quantite,
    );

    // Mettre à jour fiche stock
    await _mettreAJourFicheStockAchat(
      designation: designation,
      unite: unite,
      quantite: quantite,
    );
  }

  /// Calcule et met à jour le CMUP de l'article
  Future<void> _calculerEtMettreAJourCMUP({
    required Article article,
    required String unite,
    required double quantite,
    required double prixUnitaire,
  }) async {
    // Convertir la quantité d'achat en unité de base (u3) pour le calcul CMUP
    final conversions = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: unite,
      quantiteAchat: quantite,
    );

    final quantiteU3 = conversions['u3']!;

    // Calculer le nouveau CMUP
    final stockActuelU3 = article.stocksu3 ?? 0;
    final cmupActuel = article.cmup ?? 0;

    double nouveauCMUP;
    if (stockActuelU3 == 0) {
      // Premier achat : CMUP = prix d'achat
      nouveauCMUP = prixUnitaire;
    } else {
      // CMUP pondéré : (stock_actuel * CMUP_actuel + quantité_achat * prix_achat) / (stock_actuel + quantité_achat)
      final valeurStockActuel = stockActuelU3 * cmupActuel;
      final valeurAchat = quantiteU3 * prixUnitaire;
      final stockTotal = stockActuelU3 + quantiteU3;

      nouveauCMUP = stockTotal > 0 ? (valeurStockActuel + valeurAchat) / stockTotal : prixUnitaire;
    }

    // Mettre à jour le CMUP dans la table articles
    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(
      cmup: Value(nouveauCMUP),
    ));
  }

  /// Met à jour la fiche stock pour les achats
  Future<void> _mettreAJourFicheStockAchat({
    required String designation,
    required String unite,
    required double quantite,
  }) async {
    final ficheExiste = await (_databaseService.database.select(_databaseService.database.fstocks)
          ..where((f) => f.art.equals(designation)))
        .getSingleOrNull();

    if (ficheExiste != null) {
      // Mettre à jour la fiche existante - pour les achats on augmente qe (entrées)
      double nouvelleQe = (ficheExiste.qe ?? 0) + quantite;

      await (_databaseService.database.update(_databaseService.database.fstocks)
            ..where((f) => f.art.equals(designation)))
          .write(FstocksCompanion(
        qe: Value(nouvelleQe),
      ));
    } else {
      // Créer nouvelle fiche
      final ref = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database.into(_databaseService.database.fstocks).insert(
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

  /// Contre-passe un achat journalisé
  Future<void> contrePasserAchatJournal(String numAchats) async {
    final achat = await (_databaseService.database.select(_databaseService.database.achats)
          ..where((a) => a.numachats.equals(numAchats)))
        .getSingleOrNull();

    if (achat == null) throw Exception('Achat non trouvé');
    if (achat.contre == '1') throw Exception('Achat déjà contre-passé');
    if (achat.verification != 'JOURNAL') {
      throw Exception('Seuls les achats journalisés peuvent être contre-passés');
    }

    await _databaseService.database.transaction(() async {
      // 1. Marquer comme contre-passé
      await (_databaseService.database.update(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(numAchats)))
          .write(const AchatsCompanion(contre: Value('1')));

      // 2. Ajuster compte fournisseur (sortie pour annuler l'entrée)
      if (achat.frns != null && achat.frns!.isNotEmpty) {
        final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';
        await _databaseService.database.into(_databaseService.database.comptefrns).insert(
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
        final fournisseur = await (_databaseService.database.select(_databaseService.database.frns)
              ..where((f) => f.rsoc.equals(achat.frns!)))
            .getSingleOrNull();
        if (fournisseur != null) {
          await (_databaseService.database.update(_databaseService.database.frns)
                ..where((f) => f.rsoc.equals(achat.frns!)))
              .write(FrnsCompanion(
            soldes: Value((fournisseur.soldes ?? 0) - (achat.totalttc ?? 0)),
            datedernop: Value(DateTime.now()),
          ));
        }
      }

      // 3. Mouvement caisse si paiement espèces (entrée pour récupérer l'argent)
      if (achat.modepai == 'Espèces') {
        final ref = 'CP-${DateTime.now().millisecondsSinceEpoch}';
        await _databaseService.database.into(_databaseService.database.caisse).insert(
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
}
