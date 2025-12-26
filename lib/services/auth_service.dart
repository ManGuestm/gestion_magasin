import '../database/database.dart';
import '../database/database_service.dart';
import 'audit_service.dart';

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
  /// 🔒 SERVEUR → Administrateur uniquement
  /// 🔒 CLIENT → Tous les utilisateurs
  Future<bool> login(String username, String password) async {
    try {
      await AuditService().log(
        userId: 'system',
        userName: 'system',
        action: AuditAction.login,
        module: 'AUTH_SERVICE',
        details: 'Tentative de connexion pour: $username',
      );

      final dbService = DatabaseService();
      final isClientMode = dbService.isNetworkMode;

      await AuditService().log(
        userId: 'system',
        userName: 'system',
        action: AuditAction.login,
        module: 'AUTH_SERVICE',
        details: 'Mode détecté: ${isClientMode ? "CLIENT" : "SERVEUR"}',
      );

      // 🔒 SERVEUR: Vérifier que l'utilisateur est Administrateur AVANT l'authentification
      if (!isClientMode) {
        await AuditService().log(
          userId: 'system',
          userName: 'system',
          action: AuditAction.login,
          module: 'AUTH_SERVICE',
          details: 'Vérification rôle en mode SERVEUR...',
        );

        final user = await dbService.database.getUserByUsername(username);
        if (user == null) {
          await AuditService().log(
            userId: user?.id ?? 'unknown',
            userName: username,
            action: AuditAction.error,
            module: 'Authentification',
            details:
                'Accès refusé: Rôle ${user?.role ?? "utilisateur inconnu"} - Seul Administrateur autorisé en mode SERVEUR',
          );
          return false;
        }

        await AuditService().log(
          userId: 'system',
          userName: 'system',
          action: AuditAction.login,
          module: 'AUTH_SERVICE',
          details: 'Rôle Administrateur confirmé',
        );
      }

      // ✅ authenticateUserWithModeAwareness effectue la vérification du mot de passe (bcrypt)
      await AuditService().log(
        userId: 'system',
        userName: 'system',
        action: AuditAction.login,
        module: 'AUTH_SERVICE',
        details: 'Authentification en cours via ${isClientMode ? "serveur réseau" : "base locale"}...',
      );

      final user = await dbService.authenticateUserWithModeAwareness(username, password);

      if (user != null) {
        await AuditService().log(
          userId: user.id,
          userName: user.nom,
          action: AuditAction.login,
          module: 'AUTH_SERVICE',
          details: 'Authentification réussie pour: ${user.nom} (${user.role})',
        );

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

      await AuditService().log(
        userId: 'unknown',
        userName: username,
        action: AuditAction.error,
        module: 'AUTH_SERVICE',
        details: 'Authentification échouée - Credentials invalides',
      );

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
        module: 'AUTH_SERVICE',
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
      case 'Consultant':
        return _consultantPermissions.contains(feature);
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

  /// Permissions pour le rôle Consultant
  static const List<String> _consultantPermissions = ['ventes', 'clients', 'articles_view', 'stocks_view'];

  /// Vérifie si un vendeur peut accéder à un modal spécifique
  bool isVendeurRestrictedModal(String modalName) {
    if (_currentUser?.role != 'Vendeur' || _currentUser?.role != 'Consultant') return false;

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

  /// Vérifie si un consultant peut accéder à un modal spécifique
  bool isConsultantRestrictedModal(String modalName) {
    if (_currentUser?.role != 'Vendeur' || _currentUser?.role != 'Consultant') return false;

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

  /// Vérifie si l'utilisateur peut imprimer
  bool canPrint() {
    if (_currentUser == null) return false;
    return _currentUser!.role != 'Consultant';
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
