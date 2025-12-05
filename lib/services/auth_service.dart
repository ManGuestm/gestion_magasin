import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../database/database.dart';
import '../database/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get currentUserRole => _currentUser?.role ?? '';

  /// Authentifie un utilisateur avec cryptage du mot de passe
  Future<bool> login(String username, String password) async {
    try {
      final db = DatabaseService().database;
      // Crypter le mot de passe pour la comparaison
      final hashedPassword = _hashPassword(password);
      final user = await db.authenticateUser(username, hashedPassword);

      if (user != null) {
        _currentUser = user;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crypte un mot de passe avec SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Déconnecte l'utilisateur actuel
  void logout() {
    _currentUser = null;
  }

  /// Met à jour les données de l'utilisateur actuel
  void updateCurrentUser(User user) {
    _currentUser = user;
  }

  /// Vérifie si l'utilisateur a le rôle requis
  bool hasRole(String requiredRole) {
    if (_currentUser == null) return false;

    // L'administrateur a accès à tout
    if (_currentUser!.role == 'Administrateur') return true;

    return _currentUser!.role == requiredRole;
  }

  /// Vérifie si l'utilisateur peut accéder à une fonctionnalité
  bool canAccess(String feature) {
    if (_currentUser == null) return false;

    switch (_currentUser!.role) {
      case 'Administrateur':
        return true; // Accès total
      case 'Caisse':
        return _caissePermissions.contains(feature);
      case 'Vendeur':
        return _vendeurPermissions.contains(feature);
      default:
        return false;
    }
  }

  /// Permissions pour le rôle Caisse
  static const List<String> _caissePermissions = [
    'ventes',
    'clients',
    'articles_view',
    'stocks_view',
    'caisse',
    'etats_ventes',
  ];

  /// Permissions pour le rôle Vendeur
  static const List<String> _vendeurPermissions = [
    'ventes',
    'clients',
    'articles_view',
    'stocks_view',
  ];

  /// Vérifie si un vendeur peut accéder à un modal spécifique
  bool isVendeurRestrictedModal(String modalName) {
    if (_currentUser?.role != 'Vendeur') return false;

    const restrictedModals = [
      'Encaissements',
      'Décaissements',
      'Suivi différence prix',
      'Journal de caisse',
      'Journal des banques',
      'Comptes fournisseurs',
      'Achats',
      'Fournisseurs',
      'Liste des achats',
      'Liste des ventes',
      'Sur Ventes',
      'Retours achats',
      'Information sur la société',
      'Réinitialiser les données',
      'Informations sur la société',
    ];

    return restrictedModals.contains(modalName);
  }

  /// Initialise le service d'authentification
  Future<void> initialize() async {
    try {
      final db = DatabaseService().database;
      await db.createDefaultAdmin();
    } catch (e) {
      // Ignorer les erreurs d'initialisation
    }
  }
}
