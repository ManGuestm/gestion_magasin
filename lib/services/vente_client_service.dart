import '../../constants/client_categories.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import 'package:drift/drift.dart' as drift;

/// Service pour la gestion des clients dans les ventes
class VenteClientService {
  final DatabaseService _databaseService = DatabaseService();

  /// Filtre les clients selon le type de vente (MAG ou Tous dépôts)
  List<CltData> filterClientsByRole(List<CltData> allClients, bool tousDepots) {
    if (tousDepots) {
      return allClients
          .where((client) => client.categorie == ClientCategory.tousDepots.label)
          .toList();
    } else {
      return allClients
          .where((client) => client.categorie == ClientCategory.magasin.label)
          .toList();
    }
  }

  /// Calcule le solde d'un client
  Future<double> calculerSoldeClient(String? client, {String? excludeNumVente}) async {
    if (client == null || client.isEmpty) return 0.0;

    try {
      double solde = await _databaseService.database.calculerSoldeClient(client);

      // Exclure une vente spécifique du calcul si nécessaire
      if (excludeNumVente != null && excludeNumVente.isNotEmpty) {
        final vente = await (_databaseService.database.select(
          _databaseService.database.ventes,
        )..where((v) => v.numventes.equals(excludeNumVente)))
            .getSingleOrNull();

        if (vente != null && vente.modepai == 'A crédit') {
          double montantVente = (vente.totalttc ?? 0) - (vente.avance ?? 0);
          solde -= montantVente;
        }
      }

      return solde;
    } catch (e) {
      return 0.0;
    }
  }

  /// Vérifie si le mode crédit doit être affiché pour un client
  bool shouldShowCreditMode(CltData? client) {
    if (client == null) return true;
    return client.categorie == null || client.categorie == ClientCategory.tousDepots.label;
  }

  /// Crée un nouveau client
  Future<void> creerClient({
    required String nomClient,
    required bool tousDepots,
  }) async {
    await _databaseService.database.into(_databaseService.database.clt).insert(
          CltCompanion.insert(
            rsoc: nomClient,
            categorie: drift.Value(
              tousDepots ? ClientCategory.tousDepots.label : ClientCategory.magasin.label,
            ),
            commercial: drift.Value(AuthService().currentUser?.nom ?? ''),
            taux: const drift.Value(0),
            soldes: const drift.Value(0),
            soldesa: const drift.Value(0),
            action: const drift.Value("A"),
            plafon: const drift.Value(9000000000.0),
            plafonbl: const drift.Value(9000000000.0),
          ),
        );
  }

  /// Vérifie si un client existe
  bool clientExists(List<CltData> clients, String nomClient) {
    return clients.any((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase());
  }

  /// Trouve un client par nom
  CltData? findClientByName(List<CltData> clients, String nomClient) {
    return clients
        .where((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase())
        .firstOrNull;
  }
}
