import 'package:drift/drift.dart';

import '../constants/client_categories.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';

class ClientFilterService {
  static final ClientFilterService _instance = ClientFilterService._internal();
  factory ClientFilterService() => _instance;
  ClientFilterService._internal();

  final DatabaseService _db = DatabaseService();

  /// Filtre les clients selon le mode de vente et le rôle utilisateur
  Future<List<dynamic>> getClientsFiltered({required bool tousDepots}) async {
    final userRole = AuthService().currentUser?.role;

    // Vendeur : seulement clients Magasin
    if (userRole == 'Vendeur') {
      return await _db.database.customSelect('SELECT * FROM clt WHERE categorie = ? ORDER BY rsoc',
          variables: [Variable(ClientCategory.magasin.label)]).get();
    }

    // Administrateur/autres : selon le mode
    final categorie = tousDepots ? ClientCategory.tousDepots.label : ClientCategory.magasin.label;

    return await _db.database.customSelect('SELECT * FROM clt WHERE categorie = ? ORDER BY rsoc',
        variables: [Variable(categorie)]).get();
  }

  /// Vérifie si un client peut être utilisé dans un mode de vente
  bool peutUtiliserClient(String categorieClient, bool tousDepots) {
    final userRole = AuthService().currentUser?.role;

    // Vendeur : seulement clients Magasin
    if (userRole == 'Vendeur') {
      return categorieClient == ClientCategory.magasin.label;
    }

    // Administrateur : selon le mode
    if (tousDepots) {
      return categorieClient == ClientCategory.tousDepots.label;
    } else {
      return categorieClient == ClientCategory.magasin.label;
    }
  }

  /// Détermine la catégorie par défaut selon le contexte
  String getCategorieDefaut(bool tousDepots) {
    final userRole = AuthService().currentUser?.role;

    // Vendeur : toujours Magasin
    if (userRole == 'Vendeur') {
      return ClientCategory.magasin.label;
    }

    // Administrateur : selon le mode
    return tousDepots ? ClientCategory.tousDepots.label : ClientCategory.magasin.label;
  }
}
