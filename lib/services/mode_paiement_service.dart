import '../database/database_service.dart';

class ModePaiementService {
  static final ModePaiementService _instance = ModePaiementService._internal();
  factory ModePaiementService() => _instance;
  ModePaiementService._internal();

  final DatabaseService _db = DatabaseService();

  /// Récupère tous les modes de paiement
  Future<List<String>> getAllModesPaiement() async {
    return await _db.getAllModesPaiement();
  }

  /// Ajoute un mode de paiement s'il n'existe pas
  Future<void> addModePaiement(String modePaiement) async {
    await _db.database.customStatement('INSERT OR IGNORE INTO mp (mp) VALUES (?)', [modePaiement]);
  }

  /// Initialise les modes de paiement par défaut
  Future<void> initializeDefaultModes() async {
    const defaultModes = ['Espèces', 'A crédit', 'Mobile Money'];

    for (final mode in defaultModes) {
      await addModePaiement(mode);
    }
  }
}
