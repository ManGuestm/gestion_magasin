import 'package:flutter/material.dart';

import '../constants/vente_types.dart';
import '../database/database.dart';

/// État centralisé pour les ventes
/// Remplace les 30+ variables d'état dispersées
class VenteState {
  // Données de la vente
  final String numVentes;
  final DateTime date;
  final String numBL;
  final String? clientName;
  final StatutVente statut;
  final String modePaiement;

  // Sélections courantes
  final Article? selectedArticle;
  final String? selectedUnite;
  final String? selectedDepot;
  final int? selectedRowIndex;

  // Données de modification
  final bool isExistingPurchase;
  final bool isModifyingLine;
  final int? modifyingLineIndex;
  final Map<String, dynamic>? originalLineData;

  // Lignes de vente
  final List<Map<String, dynamic>> lignesVente;

  // Stocks et disponibilités
  final double stockDisponible;
  final bool stockInsuffisant;
  final String uniteAffichage;

  // Solde client
  final double soldeAnterieur;

  // Contrôleurs (nécessaires pour la gestion d'état)
  final TextEditingController quantiteController;
  final TextEditingController prixController;
  final TextEditingController montantController;
  final TextEditingController remiseController;
  final TextEditingController totalTTCController;
  final TextEditingController avanceController;
  final TextEditingController resteController;
  final TextEditingController nouveauSoldeController;

  VenteState({
    required this.numVentes,
    required this.date,
    required this.numBL,
    this.clientName,
    required this.statut,
    this.modePaiement = 'A crédit',
    this.selectedArticle,
    this.selectedUnite,
    this.selectedDepot,
    this.selectedRowIndex,
    this.isExistingPurchase = false,
    this.isModifyingLine = false,
    this.modifyingLineIndex,
    this.originalLineData,
    this.lignesVente = const [],
    this.stockDisponible = 0.0,
    this.stockInsuffisant = false,
    this.uniteAffichage = '',
    this.soldeAnterieur = 0.0,
    required this.quantiteController,
    required this.prixController,
    required this.montantController,
    required this.remiseController,
    required this.totalTTCController,
    required this.avanceController,
    required this.resteController,
    required this.nouveauSoldeController,
  });

  /// Crée une copie avec modifications
  VenteState copyWith({
    String? numVentes,
    DateTime? date,
    String? numBL,
    String? clientName,
    StatutVente? statut,
    String? modePaiement,
    Article? selectedArticle,
    String? selectedUnite,
    String? selectedDepot,
    int? selectedRowIndex,
    bool? isExistingPurchase,
    bool? isModifyingLine,
    int? modifyingLineIndex,
    Map<String, dynamic>? originalLineData,
    List<Map<String, dynamic>>? lignesVente,
    double? stockDisponible,
    bool? stockInsuffisant,
    String? uniteAffichage,
    double? soldeAnterieur,
  }) {
    return VenteState(
      numVentes: numVentes ?? this.numVentes,
      date: date ?? this.date,
      numBL: numBL ?? this.numBL,
      clientName: clientName ?? this.clientName,
      statut: statut ?? this.statut,
      modePaiement: modePaiement ?? this.modePaiement,
      selectedArticle: selectedArticle ?? this.selectedArticle,
      selectedUnite: selectedUnite ?? this.selectedUnite,
      selectedDepot: selectedDepot ?? this.selectedDepot,
      selectedRowIndex: selectedRowIndex ?? this.selectedRowIndex,
      isExistingPurchase: isExistingPurchase ?? this.isExistingPurchase,
      isModifyingLine: isModifyingLine ?? this.isModifyingLine,
      modifyingLineIndex: modifyingLineIndex ?? this.modifyingLineIndex,
      originalLineData: originalLineData ?? this.originalLineData,
      lignesVente: lignesVente ?? this.lignesVente,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      stockInsuffisant: stockInsuffisant ?? this.stockInsuffisant,
      uniteAffichage: uniteAffichage ?? this.uniteAffichage,
      soldeAnterieur: soldeAnterieur ?? this.soldeAnterieur,
      quantiteController: quantiteController,
      prixController: prixController,
      montantController: montantController,
      remiseController: remiseController,
      totalTTCController: totalTTCController,
      avanceController: avanceController,
      resteController: resteController,
      nouveauSoldeController: nouveauSoldeController,
    );
  }

  /// Vérifie si un client est sélectionné
  bool get isClientSelected => clientName != null && clientName!.isNotEmpty;

  /// Vérifie si les données de modification sont valides
  bool get isModificationValid => isModifyingLine && modifyingLineIndex != null;

  /// Réinitialise l'état de modification
  VenteState resetModification() {
    return copyWith(isModifyingLine: false, modifyingLineIndex: null, originalLineData: null);
  }

  /// Ajoute une ligne de vente
  VenteState addLine(Map<String, dynamic> ligne) {
    final newLignes = [...lignesVente, ligne];
    return copyWith(lignesVente: newLignes);
  }

  /// Supprime une ligne de vente
  VenteState removeLine(int index) {
    if (index < 0 || index >= lignesVente.length) return this;
    final newLignes = [...lignesVente]..removeAt(index);
    return copyWith(lignesVente: newLignes);
  }

  /// Remplace une ligne de vente
  VenteState updateLine(int index, Map<String, dynamic> ligne) {
    if (index < 0 || index >= lignesVente.length) return this;
    final newLignes = [...lignesVente];
    newLignes[index] = ligne;
    return copyWith(lignesVente: newLignes);
  }

  /// Vide les lignes de vente
  VenteState clearLines() {
    return copyWith(lignesVente: []);
  }

  /// Réinitialise l'état complet
  VenteState reset({required String newNumVentes, required String newNumBL, required DateTime newDate}) {
    quantiteController.clear();
    prixController.clear();
    montantController.clear();
    remiseController.text = '0';
    totalTTCController.text = '0';
    avanceController.text = '0';
    resteController.text = '0';
    nouveauSoldeController.text = '0';

    return VenteState(
      numVentes: newNumVentes,
      date: newDate,
      numBL: newNumBL,
      statut: StatutVente.brouillard,
      modePaiement: 'A crédit',
      lignesVente: [],
      selectedArticle: null,
      selectedUnite: null,
      selectedDepot: null,
      clientName: null,
      isExistingPurchase: false,
      isModifyingLine: false,
      quantiteController: quantiteController,
      prixController: prixController,
      montantController: montantController,
      remiseController: remiseController,
      totalTTCController: totalTTCController,
      avanceController: avanceController,
      resteController: resteController,
      nouveauSoldeController: nouveauSoldeController,
    );
  }
}
