import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';

class SecurityService {
  static const int _saltRounds = 12;

  /// Chiffre un mot de passe
  static String hashPassword(String password) {
    try {
      return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _saltRounds));
    } catch (e) {
      debugPrint('Erreur chiffrement mot de passe: $e');
      rethrow;
    }
  }

  /// Vérifie un mot de passe
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      debugPrint('Erreur vérification mot de passe: $e');
      return false;
    }
  }

  /// Valide la force d'un mot de passe
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  /// Génère un mot de passe sécurisé
  static String generateSecurePassword({int length = 12}) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(
        (DateTime.now().millisecondsSinceEpoch * 
         DateTime.now().microsecondsSinceEpoch) % chars.length
      ))
    );
  }
}