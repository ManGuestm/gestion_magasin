import 'package:flutter/material.dart';

/// Gère centralement tous les focus nodes et la navigation clavier
/// Simplifie la gestion des 11 FocusNodes dispersés
class FocusNodeManager {
  late final FocusNode globalShortcuts;
  late final FocusNode client;
  late final FocusNode designation;
  late final FocusNode depot;
  late final FocusNode unite;
  late final FocusNode quantite;
  late final FocusNode prix;
  late final FocusNode ajouter;
  late final FocusNode annuler;
  late final FocusNode montantRecu;
  late final FocusNode montantARendre;
  late final FocusNode searchArticle;
  late final FocusNode keyboard;

  final List<VoidCallback> _listeners = [];

  FocusNodeManager() {
    _initializeFocusNodes();
  }

  void _initializeFocusNodes() {
    globalShortcuts = FocusNode();
    client = FocusNode();
    designation = FocusNode();
    depot = FocusNode();
    unite = FocusNode();
    quantite = FocusNode();
    prix = FocusNode();
    ajouter = FocusNode();
    annuler = FocusNode();
    montantRecu = FocusNode();
    montantARendre = FocusNode();
    searchArticle = FocusNode();
    keyboard = FocusNode();

    // Ajouter des listeners pour tracker les changements
    for (var node in _getAllNodes()) {
      node.addListener(_notifyListeners);
    }
  }

  List<FocusNode> _getAllNodes() => [
    globalShortcuts,
    client,
    designation,
    depot,
    unite,
    quantite,
    prix,
    ajouter,
    annuler,
    montantRecu,
    montantARendre,
    searchArticle,
    keyboard,
  ];

  /// Ajoute un listener global pour les changements de focus
  void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Demande le focus sur le champ client
  void focusOnClient() {
    client.requestFocus();
  }

  /// Demande le focus sur le champ désignation
  void focusOnDesignation() {
    designation.requestFocus();
  }

  /// Demande le focus sur le champ quantité
  void focusOnQuantite() {
    quantite.requestFocus();
  }

  /// Demande le focus sur le champ prix
  void focusOnPrix() {
    prix.requestFocus();
  }

  /// Demande le focus sur le bouton ajouter
  void focusOnAjouter() {
    ajouter.requestFocus();
  }

  /// Restaure le focus global des raccourcis
  void restoreGlobalFocus() {
    if (!globalShortcuts.hasFocus) {
      globalShortcuts.requestFocus();
    }
  }

  /// Vérifie si le champ client a le focus
  bool hasClientFocus() => client.hasFocus;

  /// Vérifie si le champ quantité a le focus
  bool hasQuantiteFocus() => quantite.hasFocus;

  /// Vérifie si le champ prix a le focus
  bool hasPrixFocus() => prix.hasFocus;

  /// Obtient le node actuellement focalisé
  FocusNode? getCurrentFocusedNode() {
    for (var node in _getAllNodes()) {
      if (node.hasFocus) {
        return node;
      }
    }
    return null;
  }

  /// Navigue au prochain champ
  void focusNext() {
    final current = getCurrentFocusedNode();
    if (current == null) {
      focusOnClient();
      return;
    }

    // Définir l'ordre de navigation
    const tabOrder = ['client', 'designation', 'depot', 'unite', 'quantite', 'prix', 'ajouter'];

    // Trouver l'index actuel et passer au suivant
    int currentIndex = -1;
    if (current == client) currentIndex = 0;
    if (current == designation) currentIndex = 1;
    if (current == depot) currentIndex = 2;
    if (current == unite) currentIndex = 3;
    if (current == quantite) currentIndex = 4;
    if (current == prix) currentIndex = 5;
    if (current == ajouter) currentIndex = 6;

    if (currentIndex >= 0 && currentIndex < tabOrder.length - 1) {
      final nextIndex = currentIndex + 1;
      _focusByIndex(nextIndex);
    }
  }

  /// Navigue au champ précédent
  void focusPrevious() {
    final current = getCurrentFocusedNode();
    if (current == null) return;

    int currentIndex = -1;
    if (current == client) currentIndex = 0;
    if (current == designation) currentIndex = 1;
    if (current == depot) currentIndex = 2;
    if (current == unite) currentIndex = 3;
    if (current == quantite) currentIndex = 4;
    if (current == prix) currentIndex = 5;
    if (current == ajouter) currentIndex = 6;

    if (currentIndex > 0) {
      final previousIndex = currentIndex - 1;
      _focusByIndex(previousIndex);
    }
  }

  void _focusByIndex(int index) {
    switch (index) {
      case 0:
        focusOnClient();
      case 1:
        focusOnDesignation();
      case 2:
        depot.requestFocus();
      case 3:
        unite.requestFocus();
      case 4:
        focusOnQuantite();
      case 5:
        focusOnPrix();
      case 6:
        focusOnAjouter();
    }
  }

  /// Libère tous les ressources
  void dispose() {
    for (var node in _getAllNodes()) {
      node.dispose();
    }
    _listeners.clear();
  }
}
