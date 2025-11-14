import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../utils/stock_converter.dart';

/// Widget pour afficher les stocks avec conversion automatique
/// Affiche le format optimisé: "52 Ctn / 31 Grs / 3 Pcs"
class StockDisplayWidget extends StatelessWidget {
  final Article article;
  final double stockU1;
  final double stockU2;
  final double stockU3;
  final TextStyle? textStyle;
  final bool showTotal;

  const StockDisplayWidget({
    super.key,
    required this.article,
    required this.stockU1,
    required this.stockU2,
    required this.stockU3,
    this.textStyle,
    this.showTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Formater l'affichage
    final affichage = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    // Calculer le total si demandé
    String totalText = '';
    if (showTotal) {
      final total = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockU1,
        stockU2: stockU2,
        stockU3: stockU3,
      );
      totalText = ' (Total: ${total.toInt()} ${article.u3 ?? 'U3'})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          affichage,
          style: textStyle ?? const TextStyle(fontSize: 12),
        ),
        if (showTotal && totalText.isNotEmpty)
          Text(
            totalText,
            style: (textStyle ?? const TextStyle(fontSize: 12)).copyWith(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}

/// Widget pour afficher un stock simple en ligne
class InlineStockDisplay extends StatelessWidget {
  final Article article;
  final double stockU1;
  final double stockU2;
  final double stockU3;
  final TextStyle? textStyle;

  const InlineStockDisplay({
    super.key,
    required this.article,
    required this.stockU1,
    required this.stockU2,
    required this.stockU3,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final affichage = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    return Text(
      affichage,
      style: textStyle ?? const TextStyle(fontSize: 12),
    );
  }
}

/// Widget pour afficher les détails de conversion d'un achat
class ConversionAchatWidget extends StatelessWidget {
  final Article article;
  final String uniteAchat;
  final double quantiteAchat;
  final TextStyle? textStyle;

  const ConversionAchatWidget({
    super.key,
    required this.article,
    required this.uniteAchat,
    required this.quantiteAchat,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final conversion = StockConverter.convertirQuantiteAchat(
      article: article,
      uniteAchat: uniteAchat,
      quantiteAchat: quantiteAchat,
    );

    final affichageConversion = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: conversion['u1']!,
      stockU2: conversion['u2']!,
      stockU3: conversion['u3']!,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achat: ${quantiteAchat.toInt()} $uniteAchat',
            style: (textStyle ?? const TextStyle(fontSize: 12)).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conversion: $affichageConversion',
            style: textStyle ?? const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'état du stock (suffisant/insuffisant)
class StockStatusWidget extends StatelessWidget {
  final Article article;
  final double stockU1;
  final double stockU2;
  final double stockU3;
  final String uniteVente;
  final double quantiteVente;
  final TextStyle? textStyle;

  const StockStatusWidget({
    super.key,
    required this.article,
    required this.stockU1,
    required this.stockU2,
    required this.stockU3,
    required this.uniteVente,
    required this.quantiteVente,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final suffisant = StockConverter.verifierStockSuffisant(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
      uniteVente: uniteVente,
      quantiteVente: quantiteVente,
    );

    final stockTotal = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: suffisant ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: suffisant ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            suffisant ? Icons.check_circle : Icons.warning,
            size: 16,
            color: suffisant ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            suffisant ? 'Stock suffisant' : 'Stock insuffisant',
            style: (textStyle ?? const TextStyle(fontSize: 12)).copyWith(
              color: suffisant ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${stockTotal.toInt()} ${article.u3 ?? 'U3'} disponibles)',
            style: (textStyle ?? const TextStyle(fontSize: 12)).copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
