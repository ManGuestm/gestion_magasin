import '../database/database.dart';
import '../database/database_service.dart';
import 'audit_service.dart';
import 'security_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get currentUserRole => _currentUser?.role ?? '';

  /// Authentifie un utilisateur avec cryptage du mot de passe
  /// ✅ En mode CLIENT: authentifie via le serveur
  /// ✅ En mode LOCAL/SERVER: authentifie via la base locale
  Future<bool> login(String username, String password) async {
    try {
      final dbService = DatabaseService();

      // ✅ Utiliser le wrapper mode-aware pour l'authentification
      final user = await dbService.authenticateUserWithModeAwareness(username, password);

      if (user != null && SecurityService.verifyPassword(password, user.motDePasse)) {
        _currentUser = user;

        // Log de connexion
        await AuditService().log(
          userId: user.id,
          userName: user.nom,
          action: AuditAction.login,
          module: 'Authentification',
          details: 'Connexion réussie (${dbService.isNetworkMode ? "RÉSEAU" : "LOCAL"})',
        );

        return true;
      }

      // Log de tentative de connexion échouée
      await AuditService().log(
        userId: 'unknown',
        userName: username,
        action: AuditAction.error,
        module: 'Authentification',
        details: 'Tentative de connexion échouée',
      );

      return false;
    } catch (e) {
      await AuditService().log(
        userId: 'unknown',
        userName: username,
        action: AuditAction.error,
        module: 'Authentification',
        details: 'Erreur lors de la connexion: $e',
      );
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur actuel
  Future<void> logout() async {
    if (_currentUser != null) {
      await AuditService().log(
        userId: _currentUser!.id,
        userName: _currentUser!.nom,
        action: AuditAction.logout,
        module: 'Authentification',
        details: 'Déconnexion',
      );
    }
    _currentUser = null;
  }

  /// Met à jour les données de l'utilisateur actuel
  void updateCurrentUser(User user) {
    _currentUser = user;
  }

  /// Définit l'utilisateur actuel (pour authentification réseau)
  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    await AuditService().log(
      userId: user.id,
      userName: user.nom,
      action: AuditAction.login,
      module: 'Authentification',
      details: 'Connexion réussie (réseau)',
    );
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
  static const List<String> _vendeurPermissions = ['ventes', 'clients', 'articles_view', 'stocks_view'];

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
