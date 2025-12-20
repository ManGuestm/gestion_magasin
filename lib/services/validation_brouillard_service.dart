import '../database/database_service.dart';
import 'auth_service.dart';

/// Service pour gérer la validation Brouillard → Journal
/// Seuls Administrateur et Caisse peuvent valider
class ValidationBrouillardService {
  static final ValidationBrouillardService _instance = ValidationBrouillardService._();
  factory ValidationBrouillardService() => _instance;
  ValidationBrouillardService._();

  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  /// Vérifie si l'utilisateur peut valider en Journal
  bool canValidateToJournal() {
    final role = _authService.currentUserRole;
    return role == 'Administrateur' || role == 'Caisse';
  }

  /// Valide une vente de Brouillard → Journal
  Future<bool> validateVenteToJournal(String numVente) async {
    if (!canValidateToJournal()) {
      throw Exception('Accès refusé: Seuls Administrateur et Caisse peuvent valider en Journal');
    }

    try {
      await _db.customStatement(
        'UPDATE ventes SET verification = ? WHERE numventes = ?',
        ['JOURNAL', numVente],
      );
      return true;
    } catch (e) {
      throw Exception('Erreur validation vente: $e');
    }
  }

  /// Valide un achat de Brouillard → Journal
  Future<bool> validateAchatToJournal(String numAchat) async {
    if (!canValidateToJournal()) {
      throw Exception('Accès refusé: Seuls Administrateur et Caisse peuvent valider en Journal');
    }

    try {
      await _db.customStatement(
        'UPDATE achats SET verification = ? WHERE numachats = ?',
        ['JOURNAL', numAchat],
      );
      return true;
    } catch (e) {
      throw Exception('Erreur validation achat: $e');
    }
  }

  /// Récupère les ventes en Brouillard
  Future<List<Map<String, dynamic>>> getVentesBrouillard() async {
    final result = await _db.customSelect(
      'SELECT * FROM ventes WHERE verification = ? ORDER BY daty DESC',
      ['BROUILLARD'],
    );
    return result;
  }

  /// Récupère les achats en Brouillard
  Future<List<Map<String, dynamic>>> getAchatsBrouillard() async {
    final result = await _db.customSelect(
      'SELECT * FROM achats WHERE verification = ? ORDER BY daty DESC',
      ['BROUILLARD'],
    );
    return result;
  }
}
