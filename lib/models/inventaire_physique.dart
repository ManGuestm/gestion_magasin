import 'package:flutter/foundation.dart';

/// Représente une saisie d'inventaire physique pour un article
///
/// Remplace le `Map<String, Map<String, double>>` original par une classe typée.
/// Offre:
/// - Type-safety
/// - Validation des données
/// - Calcul des écarts
/// - Immuabilité
@immutable
class InventairePhysique {
  /// Désignation de l'article (clé unique)
  final String designation;

  /// Quantité saisie en unité 1
  final double u1;

  /// Quantité saisie en unité 2
  final double u2;

  /// Quantité saisie en unité 3
  final double u3;

  /// Horodatage de la saisie
  final DateTime saisieAt;

  /// Notes optionnelles (ex: "Casse", "Erreur comptage")
  final String? notes;

  const InventairePhysique({
    required this.designation,
    required this.u1,
    required this.u2,
    required this.u3,
    required this.saisieAt,
    this.notes,
  });

  /// Factory depuis Map (pour compatibilité avec code existant)
  factory InventairePhysique.fromMap(String designation, Map<String, double> data) {
    return InventairePhysique(
      designation: designation,
      u1: data['u1'] ?? 0.0,
      u2: data['u2'] ?? 0.0,
      u3: data['u3'] ?? 0.0,
      saisieAt: DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  /// Convertir en Map (pour export/sérialisation)
  Map<String, dynamic> toMap() => {
    'designation': designation,
    'u1': u1,
    'u2': u2,
    'u3': u3,
    'saisieAt': saisieAt.toIso8601String(),
    'notes': notes,
  };

  /// Crée une copie avec modifications
  InventairePhysique copyWith({
    String? designation,
    double? u1,
    double? u2,
    double? u3,
    DateTime? saisieAt,
    String? notes,
  }) {
    return InventairePhysique(
      designation: designation ?? this.designation,
      u1: u1 ?? this.u1,
      u2: u2 ?? this.u2,
      u3: u3 ?? this.u3,
      saisieAt: saisieAt ?? this.saisieAt,
      notes: notes ?? this.notes,
    );
  }

  /// Propriétés dérivées

  /// Total physique en unité 3
  /// À utiliser avec StockConverter pour comparaison avec théorique
  double get totalU3 => u3 + (u2 * 10) + (u1 * 100); // Ratios exemple

  /// Booléen: Y a-t-il un écart par rapport à 0?
  /// (Utile pour coloration highlight)
  bool get isNotEmpty => u1 > 0 || u2 > 0 || u3 > 0;

  /// Booléen: Au moins une unité a été saisie
  bool get hasAnyQuantity => u1 > 0 || u2 > 0 || u3 > 0;

  /// Booléen: Cet inventaire a-t-il un écart significatif?
  /// (Dépend de la comparaison avec théorique - voir InventairePhysiqueEcart)
  bool get hasEcart => false; // À déterminer par InventairePhysiqueEcart

  /// Nombre de jours depuis la saisie
  int get daysSinceSaisie => DateTime.now().difference(saisieAt).inDays;

  @override
  String toString() => 'InventairePhysique(designation=$designation, u1=$u1, u2=$u2, u3=$u3)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventairePhysique &&
          runtimeType == other.runtimeType &&
          designation == other.designation &&
          u1 == other.u1 &&
          u2 == other.u2 &&
          u3 == other.u3 &&
          saisieAt == other.saisieAt &&
          notes == other.notes;

  @override
  int get hashCode =>
      designation.hashCode ^ u1.hashCode ^ u2.hashCode ^ u3.hashCode ^ saisieAt.hashCode ^ notes.hashCode;
}

/// Représente un inventaire physique avec ses écarts
///
/// Données composites: physique + théorique + écart calculé
@immutable
class InventairePhysiqueEcart {
  /// Données saisies en inventaire physique
  final InventairePhysique physique;

  /// Quantités théoriques (depuis DB)
  final InventaireTheorique theorique;

  /// Écarts calculés par unité
  final InventaireEcart ecart;

  const InventairePhysiqueEcart({required this.physique, required this.theorique, required this.ecart});

  /// Factory: calcule automatiquement l'écart
  factory InventairePhysiqueEcart.calculate({
    required InventairePhysique physique,
    required InventaireTheorique theorique,
  }) {
    final ecart = InventaireEcart(
      u1: physique.u1 - theorique.u1,
      u2: physique.u2 - theorique.u2,
      u3: physique.u3 - theorique.u3,
    );

    return InventairePhysiqueEcart(physique: physique, theorique: theorique, ecart: ecart);
  }

  /// Booléen: Cet inventaire détecte un écart?
  bool get hasEcart => ecart.u1 != 0 || ecart.u2 != 0 || ecart.u3 != 0;

  /// Magnitude totale de l'écart (en U3 normalisé)
  double get totalEcartMagnitude => (ecart.u1.abs() * 100) + (ecart.u2.abs() * 10) + ecart.u3.abs();

  /// Pourcentage d'écart par rapport au stock théorique
  double get ecartPercentage {
    final theoTotal = theorique.totalU3;
    if (theoTotal == 0) return 0.0;
    return (totalEcartMagnitude / theoTotal) * 100;
  }

  @override
  String toString() => 'InventairePhysiqueEcart(physique=$physique, ecart=$ecart)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventairePhysiqueEcart &&
          runtimeType == other.runtimeType &&
          physique == other.physique &&
          theorique == other.theorique &&
          ecart == other.ecart;

  @override
  int get hashCode => physique.hashCode ^ theorique.hashCode ^ ecart.hashCode;
}

/// Quantités théoriques depuis la base de données
@immutable
class InventaireTheorique {
  final double u1;
  final double u2;
  final double u3;

  const InventaireTheorique({required this.u1, required this.u2, required this.u3});

  /// Crée depuis DepartData ou Article
  factory InventaireTheorique.fromValues({required double u1, required double u2, required double u3}) =>
      InventaireTheorique(u1: u1, u2: u2, u3: u3);

  /// Total en unité 3 normalisé
  double get totalU3 => u3 + (u2 * 10) + (u1 * 100); // Ratios exemple

  @override
  String toString() => 'InventaireTheorique(u1=$u1, u2=$u2, u3=$u3)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventaireTheorique &&
          runtimeType == other.runtimeType &&
          u1 == other.u1 &&
          u2 == other.u2 &&
          u3 == other.u3;

  @override
  int get hashCode => u1.hashCode ^ u2.hashCode ^ u3.hashCode;
}

/// Écarts (Physique - Théorique)
@immutable
class InventaireEcart {
  final double u1;
  final double u2;
  final double u3;

  const InventaireEcart({required this.u1, required this.u2, required this.u3});

  /// Écart en U3 normalisé
  double get totalU3 => u3 + (u2 * 10) + (u1 * 100); // Ratios exemple

  /// Booléen: Au moins un écart détecté?
  bool get hasAnyEcart => u1 != 0 || u2 != 0 || u3 != 0;

  /// Booléen: Tous les écarts positifs (surplus)?
  bool get isAllPositive => u1 >= 0 && u2 >= 0 && u3 >= 0;

  /// Booléen: Tous les écarts négatifs (manquant)?
  bool get isAllNegative => u1 <= 0 && u2 <= 0 && u3 <= 0;

  /// Booléen: Écarts mixtes (surplus + manquant)?
  bool get isMixed => (u1 > 0 || u2 > 0 || u3 > 0) && (u1 < 0 || u2 < 0 || u3 < 0);

  /// Statut lisible: SURPLUS, MANQUANT, MIXTE, OK
  String get statut {
    if (!hasAnyEcart) return 'OK';
    if (isAllPositive) return 'SURPLUS';
    if (isAllNegative) return 'MANQUANT';
    return 'MIXTE';
  }

  @override
  String toString() => 'InventaireEcart(u1=$u1, u2=$u2, u3=$u3, statut=$statut)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventaireEcart &&
          runtimeType == other.runtimeType &&
          u1 == other.u1 &&
          u2 == other.u2 &&
          u3 == other.u3;

  @override
  int get hashCode => u1.hashCode ^ u2.hashCode ^ u3.hashCode;
}
