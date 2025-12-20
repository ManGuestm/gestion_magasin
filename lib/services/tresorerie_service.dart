import 'package:drift/drift.dart';

import '../database/database_service.dart';

class TresorerieService {
  static final TresorerieService _instance = TresorerieService._internal();
  factory TresorerieService() => _instance;
  TresorerieService._internal();

  final DatabaseService _db = DatabaseService();

  /// Enregistre une opération de caisse
  Future<void> enregistrerOperationCaisse({
    required String libelle,
    required double montant,
    required String type, // 'ENTREE' ou 'SORTIE'
    String? client,
    String? fournisseur,
    String? compte,
  }) async {
    final database = _db.database;
    final ref = 'CAI${DateTime.now().millisecondsSinceEpoch}';

    // Récupérer le solde actuel de caisse
    final soldeActuel = await _getSoldeCaisse();
    final nouveauSolde = type == 'ENTREE' ? soldeActuel + montant : soldeActuel - montant;

    await database.customStatement(
      '''INSERT INTO caisse (ref, daty, lib, debit, credit, soldes, type, clt, frns, comptes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        ref,
        DateTime.now().toIso8601String(),
        libelle,
        type == 'SORTIE' ? montant : 0,
        type == 'ENTREE' ? montant : 0,
        nouveauSolde,
        type,
        client,
        fournisseur,
        compte,
      ],
    );
  }

  /// Enregistre une opération bancaire
  Future<void> enregistrerOperationBanque({
    required String libelle,
    required double montant,
    required String type, // 'ENTREE' ou 'SORTIE'
    required String codeBanque,
    String? client,
    String? fournisseur,
    String? compte,
  }) async {
    final database = _db.database;
    final ref = 'BQ${DateTime.now().millisecondsSinceEpoch}';

    // Récupérer le solde actuel de la banque
    final soldeActuel = await _getSoldeBanque(codeBanque);
    final nouveauSolde = type == 'ENTREE' ? soldeActuel + montant : soldeActuel - montant;

    await database.customStatement(
      '''INSERT INTO banque (ref, daty, lib, debit, credit, soldes, code, type, clt, frns, comptes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        ref,
        DateTime.now().toIso8601String(),
        libelle,
        type == 'SORTIE' ? montant : 0,
        type == 'ENTREE' ? montant : 0,
        nouveauSolde,
        codeBanque,
        type,
        client,
        fournisseur,
        compte,
      ],
    );

    // Mettre à jour le solde de la banque configurée
    await database.customStatement('UPDATE bq SET soldes = ? WHERE code = ?', [nouveauSolde, codeBanque]);
  }

  /// Enregistre un chèque
  Future<void> enregistrerCheque({
    required String numeroCheque,
    required String tire,
    required String banqueTire,
    required double montant,
    required DateTime dateCheque,
    DateTime? dateReception,
    String? action,
    String? numVente,
  }) async {
    final database = _db.database;

    await database.customStatement(
      '''INSERT INTO chequier (ncheq, tire, bqtire, montant, datechq, daterecep, action, numventes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        numeroCheque,
        tire,
        banqueTire,
        montant,
        dateCheque.toIso8601String(),
        dateReception?.toIso8601String(),
        action ?? 'EN_ATTENTE',
        numVente,
      ],
    );
  }

  /// Encaisse un chèque
  Future<void> encaisserCheque(String numeroCheque, String codeBanque) async {
    final database = _db.database;

    await database.transaction(() async {
      // Récupérer le chèque
      final cheque = await database
          .customSelect('SELECT * FROM chequier WHERE ncheq = ?', variables: [Variable(numeroCheque)])
          .getSingleOrNull();

      if (cheque == null) throw Exception('Chèque introuvable');

      final montant = cheque.read<double>('montant');

      // Marquer le chèque comme encaissé
      await database.customStatement('UPDATE chequier SET action = ?, daterecep = ? WHERE ncheq = ?', [
        'ENCAISSE',
        DateTime.now().toIso8601String(),
        numeroCheque,
      ]);

      // Enregistrer l'opération bancaire
      await enregistrerOperationBanque(
        libelle: 'Encaissement chèque $numeroCheque',
        montant: montant,
        type: 'ENTREE',
        codeBanque: codeBanque,
      );
    });
  }

  /// Effectue un virement interne entre comptes
  Future<void> effectuerVirementInterne({
    required String compteSource,
    required String compteDestination,
    required double montant,
    required String libelle,
  }) async {
    final database = _db.database;

    await database.transaction(() async {
      // Sortie du compte source
      if (compteSource.startsWith('CAI')) {
        await enregistrerOperationCaisse(
          libelle: 'Virement vers $compteDestination - $libelle',
          montant: montant,
          type: 'SORTIE',
        );
      } else {
        await enregistrerOperationBanque(
          libelle: 'Virement vers $compteDestination - $libelle',
          montant: montant,
          type: 'SORTIE',
          codeBanque: compteSource,
        );
      }

      // Entrée dans le compte destination
      if (compteDestination.startsWith('CAI')) {
        await enregistrerOperationCaisse(
          libelle: 'Virement de $compteSource - $libelle',
          montant: montant,
          type: 'ENTREE',
        );
      } else {
        await enregistrerOperationBanque(
          libelle: 'Virement de $compteSource - $libelle',
          montant: montant,
          type: 'ENTREE',
          codeBanque: compteDestination,
        );
      }
    });
  }

  /// Récupère le solde de caisse
  Future<double> _getSoldeCaisse() async {
    final database = _db.database;

    final result = await database
        .customSelect('SELECT COALESCE(SUM(credit - debit), 0) as solde FROM caisse', variables: [])
        .getSingle();

    return result.read<double>('solde');
  }

  /// Récupère le solde d'une banque
  Future<double> _getSoldeBanque(String codeBanque) async {
    final database = _db.database;

    final result = await database
        .customSelect(
          'SELECT COALESCE(SUM(credit - debit), 0) as solde FROM banque WHERE code = ?',
          variables: [Variable(codeBanque)],
        )
        .getSingle();

    return result.read<double>('solde');
  }

  /// Récupère le journal de caisse
  Future<List<Map<String, dynamic>>> getJournalCaisse(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database
        .customSelect(
          '''SELECT * FROM caisse 
         WHERE daty BETWEEN ? AND ? 
         ORDER BY daty DESC, ref DESC''',
          variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())],
        )
        .get();

    return result
        .map(
          (row) => {
            'ref': row.read<String>('ref'),
            'daty': row.read<DateTime?>('daty'),
            'lib': row.read<String?>('lib'),
            'debit': row.read<double?>('debit'),
            'credit': row.read<double?>('credit'),
            'soldes': row.read<double?>('soldes'),
            'type': row.read<String?>('type'),
          },
        )
        .toList();
  }

  /// Récupère le journal de banque
  Future<List<Map<String, dynamic>>> getJournalBanque(String codeBanque, DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database
        .customSelect(
          '''SELECT * FROM banque 
         WHERE code = ? AND daty BETWEEN ? AND ? 
         ORDER BY daty DESC, ref DESC''',
          variables: [
            Variable(codeBanque),
            Variable(debut.toIso8601String()),
            Variable(fin.toIso8601String()),
          ],
        )
        .get();

    return result
        .map(
          (row) => {
            'ref': row.read<String>('ref'),
            'daty': row.read<DateTime?>('daty'),
            'lib': row.read<String?>('lib'),
            'debit': row.read<double?>('debit'),
            'credit': row.read<double?>('credit'),
            'soldes': row.read<double?>('soldes'),
            'type': row.read<String?>('type'),
          },
        )
        .toList();
  }

  /// Récupère les chèques en attente
  Future<List<Map<String, dynamic>>> getChequesEnAttente() async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT * FROM chequier 
         WHERE action = 'EN_ATTENTE' OR action IS NULL 
         ORDER BY datechq DESC''').get();

    return result
        .map(
          (row) => {
            'ncheq': row.read<String?>('ncheq'),
            'tire': row.read<String?>('tire'),
            'bqtire': row.read<String?>('bqtire'),
            'montant': row.read<double?>('montant'),
            'datechq': row.read<DateTime?>('datechq'),
            'daterecep': row.read<DateTime?>('daterecep'),
            'numventes': row.read<String?>('numventes'),
          },
        )
        .toList();
  }

  /// Récupère les soldes de tous les comptes
  Future<Map<String, double>> getSoldesComptes() async {
    final database = _db.database;

    // Solde caisse
    final soldeCaisse = await _getSoldeCaisse();

    // Soldes banques
    final banques = await database.customSelect('SELECT code, intitule, soldes FROM bq').get();

    Map<String, double> soldes = {'CAISSE': soldeCaisse};

    for (final banque in banques) {
      final code = banque.read<String>('code');
      final solde = banque.read<double?>('soldes') ?? 0;
      soldes[code] = solde;
    }

    return soldes;
  }

  /// Calculates the total treasury value
  Future<double> calculateTotalTreasury() async {
    final accountBalances = await getSoldesComptes();
    return accountBalances.values.reduce((sum, balance) => sum + balance);
  }

  /// Récupère les statistiques de trésorerie
  Future<Map<String, dynamic>> getStatistiquesTresorerie(DateTime debut, DateTime fin) async {
    final database = _db.database;

    // Entrées et sorties de caisse
    final caisseStats = await database
        .customSelect(
          '''SELECT 
           COALESCE(SUM(credit), 0) as entrees_caisse,
           COALESCE(SUM(debit), 0) as sorties_caisse
         FROM caisse 
         WHERE daty BETWEEN ? AND ?''',
          variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())],
        )
        .getSingle();

    // Entrées et sorties de banque
    final banqueStats = await database
        .customSelect(
          '''SELECT 
           COALESCE(SUM(credit), 0) as entrees_banque,
           COALESCE(SUM(debit), 0) as sorties_banque
         FROM banque 
         WHERE daty BETWEEN ? AND ?''',
          variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())],
        )
        .getSingle();

    final tresorerieTotal = await calculateTotalTreasury();

    return {
      'entrees_caisse': caisseStats.read<double>('entrees_caisse'),
      'sorties_caisse': caisseStats.read<double>('sorties_caisse'),
      'entrees_banque': banqueStats.read<double>('entrees_banque'),
      'sorties_banque': banqueStats.read<double>('sorties_banque'),
      'tresorerie_totale': tresorerieTotal,
    };
  }
}
