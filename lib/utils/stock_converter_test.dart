import 'package:flutter/material.dart';

import '../database/database.dart';
import 'stock_converter.dart';

/// Classe de test pour démontrer les conversions automatiques
/// Utilise l'exemple "Good Look Maintso" fourni
class StockConverterTest {
  /// Crée un article de test avec les paramètres de "Good Look Maintso"
  /// u1 = Ctn (Carton), u2 = Grs (Gros), u3 = Pcs (Pièces)
  /// 1 Ctn = 50 Grs, 1 Grs = 10 Pcs
  static Article creerArticleTest() {
    return const Article(
      designation: 'Good Look Maintso',
      u1: 'Ctn', // Carton
      u2: 'Grs', // Gros
      u3: 'Pcs', // Pièces
      tu2u1: 50.0, // 1 Ctn = 50 Grs
      tu3u2: 10.0, // 1 Grs = 10 Pcs
      stocksu1: 48.0, // Stock initial: 48 Ctn
      stocksu2: 0.0, // 0 Grs
      stocksu3: 0.0, // 0 Pcs
      cmup: 100.0, // CMUP exemple
      dep: 'MAG', // Dépôt principal
    );
  }

  /// Test du scénario complet de l'exemple
  static void testerScenarioComplet() {
    final article = creerArticleTest();

    debugPrint('=== TEST CONVERSIONS AUTOMATIQUES ===');
    debugPrint('Article: ${article.designation}');
    debugPrint('Unités: ${article.u1} / ${article.u2} / ${article.u3}');
    debugPrint(
        'Conversions: 1 ${article.u1} = ${article.tu2u1} ${article.u2}, 1 ${article.u2} = ${article.tu3u2} ${article.u3}');
    debugPrint('');

    // État initial
    debugPrint('1. ÉTAT INITIAL:');
    String affichageInitial = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: article.stocksu1!,
      stockU2: article.stocksu2!,
      stockU3: article.stocksu3!,
    );
    debugPrint(
        'Stock réel: ${article.stocksu1!.toInt()} ${article.u1}, ${article.stocksu2!.toInt()} ${article.u2}, ${article.stocksu3!.toInt()} ${article.u3}');
    debugPrint('Affichage: $affichageInitial');
    debugPrint('');

    // Achat de 230 Grs
    debugPrint('2. APRÈS ACHAT DE 230 ${article.u2}:');
    final conversionAchat1 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: article.u2!,
      quantiteAchat: 230.0,
    );

    debugPrint(
        'Conversion achat: 230 ${article.u2} = ${conversionAchat1['u1']!.toInt()} ${article.u1} + ${conversionAchat1['u2']!.toInt()} ${article.u2} + ${conversionAchat1['u3']!.toInt()} ${article.u3}');

    final stocksApresAchat1 = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: article.stocksu1! + conversionAchat1['u1']!,
      quantiteU2: article.stocksu2! + conversionAchat1['u2']!,
      quantiteU3: article.stocksu3! + conversionAchat1['u3']!,
    );

    String affichageApresAchat1 = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stocksApresAchat1['u1']!,
      stockU2: stocksApresAchat1['u2']!,
      stockU3: stocksApresAchat1['u3']!,
    );

    debugPrint(
        'Stock: ${stocksApresAchat1['u1']!.toInt()} ${article.u1}, ${stocksApresAchat1['u2']!.toInt()} ${article.u2}, ${stocksApresAchat1['u3']!.toInt()} ${article.u3}');
    debugPrint('Affichage: $affichageApresAchat1');
    debugPrint('');

    // Achat de 13 Pcs
    debugPrint('3. APRÈS ACHAT DE 13 ${article.u3}:');
    final conversionAchat2 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: article.u3!,
      quantiteAchat: 13.0,
    );

    debugPrint(
        'Conversion achat: 13 ${article.u3} = ${conversionAchat2['u1']!.toInt()} ${article.u1} + ${conversionAchat2['u2']!.toInt()} ${article.u2} + ${conversionAchat2['u3']!.toInt()} ${article.u3}');

    final stocksApresAchat2 = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: stocksApresAchat1['u1']! + conversionAchat2['u1']!,
      quantiteU2: stocksApresAchat1['u2']! + conversionAchat2['u2']!,
      quantiteU3: stocksApresAchat1['u3']! + conversionAchat2['u3']!,
    );

    String affichageApresAchat2 = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stocksApresAchat2['u1']!,
      stockU2: stocksApresAchat2['u2']!,
      stockU3: stocksApresAchat2['u3']!,
    );

    debugPrint(
        'Stock: ${stocksApresAchat2['u1']!.toInt()} ${article.u1}, ${stocksApresAchat2['u2']!.toInt()} ${article.u2}, ${stocksApresAchat2['u3']!.toInt()} ${article.u3}');
    debugPrint('Affichage: $affichageApresAchat2');
    debugPrint('');

    // Vérification des résultats attendus
    debugPrint('4. VÉRIFICATION:');
    bool resultatCorrect = stocksApresAchat2['u1']!.toInt() == 52 &&
        stocksApresAchat2['u2']!.toInt() == 31 &&
        stocksApresAchat2['u3']!.toInt() == 3;

    debugPrint('Résultat attendu: 52 ${article.u1} / 31 ${article.u2} / 3 ${article.u3}');
    debugPrint('Résultat obtenu: $affichageApresAchat2');
    debugPrint('Test ${resultatCorrect ? "RÉUSSI ✓" : "ÉCHOUÉ ✗"}');
    debugPrint('');

    // Test de vente
    debugPrint('5. TEST DE VENTE (15 ${article.u2}):');
    bool stockSuffisant = StockConverter.verifierStockSuffisant(
      article: article,
      stockU1: stocksApresAchat2['u1']!,
      stockU2: stocksApresAchat2['u2']!,
      stockU3: stocksApresAchat2['u3']!,
      uniteVente: article.u2!,
      quantiteVente: 15.0,
    );

    debugPrint('Stock suffisant pour vendre 15 ${article.u2}: ${stockSuffisant ? "OUI" : "NON"}');

    if (stockSuffisant) {
      final deduction = StockConverter.decomposerVentePourDeduction(
        article: article,
        stockU1: stocksApresAchat2['u1']!,
        stockU2: stocksApresAchat2['u2']!,
        stockU3: stocksApresAchat2['u3']!,
        uniteVente: article.u2!,
        quantiteVente: 15.0,
      );

      debugPrint(
          'Déduction: ${deduction['u1']!.toInt()} ${article.u1}, ${deduction['u2']!.toInt()} ${article.u2}, ${deduction['u3']!.toInt()} ${article.u3}');

      final stocksApresVente = StockConverter.convertirStockOptimal(
        article: article,
        quantiteU1: stocksApresAchat2['u1']! - deduction['u1']!,
        quantiteU2: stocksApresAchat2['u2']! - deduction['u2']!,
        quantiteU3: stocksApresAchat2['u3']! - deduction['u3']!,
      );

      String affichageApresVente = StockConverter.formaterAffichageStock(
        article: article,
        stockU1: stocksApresVente['u1']!,
        stockU2: stocksApresVente['u2']!,
        stockU3: stocksApresVente['u3']!,
      );

      debugPrint('Stock après vente: $affichageApresVente');
    }

    debugPrint('');
    debugPrint('=== FIN DU TEST ===');
  }

  /// Test des conversions individuelles
  static void testerConversionsIndividuelles() {
    final article = creerArticleTest();

    debugPrint('=== TEST CONVERSIONS INDIVIDUELLES ===');

    // Test conversion 230 Grs
    debugPrint('Test 1: 230 ${article.u2}');
    final conv1 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: article.u2!,
      quantiteAchat: 230.0,
    );
    debugPrint(
        'Résultat: ${conv1['u1']!.toInt()} ${article.u1} + ${conv1['u2']!.toInt()} ${article.u2} + ${conv1['u3']!.toInt()} ${article.u3}');
    debugPrint('Attendu: 4 ${article.u1} + 30 ${article.u2} + 0 ${article.u3}');
    debugPrint('');

    // Test conversion 13 Pcs
    debugPrint('Test 2: 13 ${article.u3}');
    final conv2 = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: article.u3!,
      quantiteAchat: 13.0,
    );
    debugPrint(
        'Résultat: ${conv2['u1']!.toInt()} ${article.u1} + ${conv2['u2']!.toInt()} ${article.u2} + ${conv2['u3']!.toInt()} ${article.u3}');
    debugPrint('Attendu: 0 ${article.u1} + 1 ${article.u2} + 3 ${article.u3}');
    debugPrint('');

    // Test stock total
    debugPrint('Test 3: Calcul stock total');
    final total = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: 52.0,
      stockU2: 31.0,
      stockU3: 3.0,
    );
    debugPrint('Stock: 52 ${article.u1} + 31 ${article.u2} + 3 ${article.u3}');
    debugPrint('Total en ${article.u3}: ${total.toInt()}');
    debugPrint('Attendu: ${(52 * 50 * 10 + 31 * 10 + 3).toInt()}');
    debugPrint('');
  }
}
