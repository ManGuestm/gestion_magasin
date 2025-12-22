import 'package:flutter/foundation.dart';

/// Représente les statistiques globales d'inventaire
///
/// Remplace le `Map<String, dynamic> _stats` original par une classe typée.
/// Offre:
/// - Type-safety garantie
/// - Propriétés dérivées
/// - Validation cohérence données
/// - Immuabilité
@immutable
class InventaireStats {
  /// Valeur monétaire totale du stock (en unité principale)
  final double valeurTotale;

  /// Nombre d'articles ayant du stock > 0
  final int articlesEnStock;

  /// Nombre d'articles avec stock == 0 (rupture)
  final int articlesRupture;

  /// Nombre d'articles à seul d'alerte dépassé
  /// (0 < stock <= seuil d'alerte)
  final int articlesAlerte;

  /// Nombre total d'articles (articles.length)
  final int totalArticles;

  /// Timestamp du calcul
  final DateTime calculatedAt;

  InventaireStats({
    required this.valeurTotale,
    required this.articlesEnStock,
    required this.articlesRupture,
    required this.articlesAlerte,
    required this.totalArticles,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  /// État initial avec toutes les stats à zéro
  factory InventaireStats.zero() {
    return InventaireStats(
      valeurTotale: 0.0,
      articlesEnStock: 0,
      articlesRupture: 0,
      articlesAlerte: 0,
      totalArticles: 0,
      calculatedAt: DateTime.now(),
    );
  }

  /// Factory depuis Map (compatibilité)
  factory InventaireStats.fromMap(Map<String, dynamic> map) {
    return InventaireStats(
      valeurTotale: (map['valeurTotale'] as num?)?.toDouble() ?? 0.0,
      articlesEnStock: (map['articlesEnStock'] as int?) ?? 0,
      articlesRupture: (map['articlesRupture'] as int?) ?? 0,
      articlesAlerte: (map['articlesAlerte'] as int?) ?? 0,
      totalArticles: (map['totalArticles'] as int?) ?? 0,
      calculatedAt: (map['calculatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  /// Convertir en Map
  Map<String, dynamic> toMap() => {
    'valeurTotale': valeurTotale,
    'articlesEnStock': articlesEnStock,
    'articlesRupture': articlesRupture,
    'articlesAlerte': articlesAlerte,
    'totalArticles': totalArticles,
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  /// Crée une copie avec modifications
  InventaireStats copyWith({
    double? valeurTotale,
    int? articlesEnStock,
    int? articlesRupture,
    int? articlesAlerte,
    int? totalArticles,
    DateTime? calculatedAt,
  }) {
    return InventaireStats(
      valeurTotale: valeurTotale ?? this.valeurTotale,
      articlesEnStock: articlesEnStock ?? this.articlesEnStock,
      articlesRupture: articlesRupture ?? this.articlesRupture,
      articlesAlerte: articlesAlerte ?? this.articlesAlerte,
      totalArticles: totalArticles ?? this.totalArticles,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  /// Propriétés dérivées

  /// Nombre d'articles sains (stock OK)
  int get articlesSains => articlesEnStock - articlesAlerte;

  /// Pourcentage d'articles en stock
  double get percentEnStock => totalArticles == 0 ? 0.0 : (articlesEnStock / totalArticles) * 100;

  /// Pourcentage d'articles en rupture
  double get percentRupture => totalArticles == 0 ? 0.0 : (articlesRupture / totalArticles) * 100;

  /// Pourcentage d'articles en alerte
  double get percentAlerte => totalArticles == 0 ? 0.0 : (articlesAlerte / totalArticles) * 100;

  /// Pourcentage d'articles sains (stock > seuil alerte)
  double get percentSains => totalArticles == 0 ? 0.0 : (articlesSains / totalArticles) * 100;

  /// Valeur moyenne par article (si articles > 0)
  double get valeurMoyenne => articlesEnStock == 0 ? 0.0 : valeurTotale / articlesEnStock;

  /// Santé globale: GREEN / ORANGE / RED
  String get sante {
    if (articlesRupture == 0 && articlesAlerte == 0) return 'EXCELLENT';
    if (percentRupture < 10 && percentAlerte < 20) return 'BON';
    if (percentRupture < 20 && percentAlerte < 30) return 'MOYEN';
    return 'MAUVAIS';
  }

  /// Couleur de santé pour UI
  /// À utiliser: Color.fromARGB(...) avec cette valeur
  /// EXCELLENT: 0xFF4CAF50 (Green)
  /// BON: 0xFF2196F3 (Blue)
  /// MOYEN: 0xFFFFC107 (Amber)
  /// MAUVAIS: 0xFFF44336 (Red)
  int get santeColor {
    switch (sante) {
      case 'EXCELLENT':
        return 0xFF4CAF50;
      case 'BON':
        return 0xFF2196F3;
      case 'MOYEN':
        return 0xFFFFC107;
      case 'MAUVAIS':
        return 0xFFF44336;
      default:
        return 0xFF9E9E9E;
    }
  }

  /// Âge du calcul en minutes
  int get ageMinutes => DateTime.now().difference(calculatedAt).inMinutes;

  /// Booléen: Stats obsolètes (> 30 min)?
  bool get isStale => ageMinutes > 30;

  /// Booléen: Stats valides?
  bool get isValid =>
      totalArticles > 0 && (articlesEnStock + articlesRupture + articlesAlerte) <= totalArticles;

  /// Résumé texte pour affichage rapide
  String get resumeTexte =>
      '$articlesEnStock / $totalArticles articles en stock\n'
      'Valeur totale: ${valeurTotale.toStringAsFixed(2)}';

  @override
  String toString() =>
      'InventaireStats(valeur=$valeurTotale, enStock=$articlesEnStock, rupture=$articlesRupture, alerte=$articlesAlerte, total=$totalArticles, sante=$sante)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventaireStats &&
          runtimeType == other.runtimeType &&
          valeurTotale == other.valeurTotale &&
          articlesEnStock == other.articlesEnStock &&
          articlesRupture == other.articlesRupture &&
          articlesAlerte == other.articlesAlerte &&
          totalArticles == other.totalArticles &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode =>
      valeurTotale.hashCode ^
      articlesEnStock.hashCode ^
      articlesRupture.hashCode ^
      articlesAlerte.hashCode ^
      totalArticles.hashCode ^
      calculatedAt.hashCode;
}

/// Workaround pour NullDateTimeValue (utilisé pour const constructor)
/// Valeur par défaut pour les dates utilisées dans les statistiques
/// Représente une valeur null pour les DateTime constants
class NullDateTimeValue {
  const NullDateTimeValue();

  DateTime toDateTime() => DateTime(2020);

  @override
  String toString() => 'NullDateTimeValue';

  @override
  bool operator ==(Object other) => identical(this, other) || other is NullDateTimeValue;

  @override
  int get hashCode => 'null_date_time'.hashCode;
}
