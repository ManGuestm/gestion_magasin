import 'package:drift/drift.dart';

import '../database/database.dart';
import 'network_client.dart';

class NetworkDatabaseService {
  final NetworkClient _client = NetworkClient.instance;

  // Wrapper pour les requêtes SELECT
  Future<List<Map<String, dynamic>>> customSelect(String sql, [List<Variable>? variables]) async {
    final params = variables?.map((v) => v.value).toList();
    return await _client.query(sql, params);
  }

  // Wrapper pour les requêtes d'écriture
  Future<void> customStatement(String sql, [List<Variable>? variables]) async {
    final params = variables?.map((v) => v.value).toList();
    await _client.execute(sql, params);
  }

  // Transaction
  Future<void> transaction(Future<void> Function() action) async {
    // Pour simplifier, on exécute directement l'action
    // Dans une vraie implémentation, il faudrait capturer les requêtes
    await action();
  }

  // Méthodes spécifiques pour l'application
  Future<List<Article>> getAllArticles() async {
    final result = await customSelect('SELECT * FROM articles ORDER BY designation');
    return result
        .map(
          (row) => Article(
            designation: row['designation'],
            u1: row['u1'],
            u2: row['u2'],
            u3: row['u3'],
            pvu1: row['pvu1'],
            pvu2: row['pvu2'],
            pvu3: row['pvu3'],
            stocksu1: row['stocksu1'],
            stocksu2: row['stocksu2'],
            stocksu3: row['stocksu3'],
            categorie: row['categorie'],
          ),
        )
        .toList();
  }

  // Méthodes spécifiques pour l'application
  Future<List<Article>> getActiveArticles() async {
    final result = await customSelect('SELECT * FROM articles WHERE action="A" ORDER BY designation');
    return result
        .map(
          (row) => Article(
            designation: row['designation'],
            u1: row['u1'],
            u2: row['u2'],
            u3: row['u3'],
            pvu1: row['pvu1'],
            pvu2: row['pvu2'],
            pvu3: row['pvu3'],
            stocksu1: row['stocksu1'],
            stocksu2: row['stocksu2'],
            stocksu3: row['stocksu3'],
            categorie: row['categorie'],
          ),
        )
        .toList();
  }

  Future<List<CltData>> getAllClients() async {
    final result = await customSelect('SELECT * FROM clt ORDER BY rsoc');
    return result
        .map(
          (row) => CltData(
            rsoc: row['rsoc'],
            adr: row['adr'],
            tel: row['tel'],
            email: row['email'],
            nif: row['nif'],
            stat: row['stat'],
            rcs: row['rcs'],
            soldes: row['soldes'],
          ),
        )
        .toList();
  }

  Future<List<CltData>> getActiveClients() async {
    final result = await customSelect('SELECT * FROM clt WHERE action="A" ORDER BY rsoc');
    return result
        .map(
          (row) => CltData(
            rsoc: row['rsoc'],
            adr: row['adr'],
            tel: row['tel'],
            email: row['email'],
            nif: row['nif'],
            stat: row['stat'],
            rcs: row['rcs'],
            soldes: row['soldes'],
          ),
        )
        .toList();
  }

  Future<List<Depot>> getAllDepots() async {
    final result = await customSelect('SELECT * FROM depots ORDER BY depots');
    return result.map((row) => Depot(depots: row['depots'])).toList();
  }

  Future<List<Frn>> getAllFournisseurs() async {
    final result = await customSelect('SELECT * FROM frns ORDER BY rsoc');
    return result
        .map(
          (row) => Frn(
            rsoc: row['rsoc'],
            adr: row['adr'],
            tel: row['tel'],
            email: row['email'],
            nif: row['nif'],
            stat: row['stat'],
            rcs: row['rcs'],
            soldes: row['soldes'],
          ),
        )
        .toList();
  }

  Future<List<Frn>> getActiveFournisseurs() async {
    final result = await customSelect('SELECT * FROM frns WHERE action="A" ORDER BY rsoc');
    return result
        .map(
          (row) => Frn(
            rsoc: row['rsoc'],
            adr: row['adr'],
            tel: row['tel'],
            email: row['email'],
            nif: row['nif'],
            stat: row['stat'],
            rcs: row['rcs'],
            soldes: row['soldes'],
          ),
        )
        .toList();
  }

  Future<List<SocData>> getAllSoc() async {
    final result = await customSelect('SELECT * FROM soc');
    return result
        .map(
          (row) => SocData(
            ref: row['ref'],
            rsoc: row['rsoc'],
            activites: row['activites'],
            adr: row['adr'],
            tel: row['tel'],
            port: row['port'],
            email: row['email'],
            site: row['site'],
            logo: row['logo'],
            rcs: row['rcs'],
            nif: row['nif'],
            stat: row['stat'],
            cif: row['cif'],
          ),
        )
        .toList();
  }

  Future<Article?> getArticleByDesignation(String designation) async {
    final result = await customSelect('SELECT * FROM articles WHERE designation = ?', [
      Variable(designation),
    ]);
    if (result.isEmpty) return null;

    final row = result.first;
    return Article(
      designation: row['designation'],
      u1: row['u1'],
      u2: row['u2'],
      u3: row['u3'],
      pvu1: row['pvu1'],
      pvu2: row['pvu2'],
      pvu3: row['pvu3'],
      stocksu1: row['stocksu1'],
      stocksu2: row['stocksu2'],
      stocksu3: row['stocksu3'],
      categorie: row['categorie'],
    );
  }

  Future<bool> userExists(String username) async {
    final result = await customSelect('SELECT COUNT(*) as count FROM users WHERE nom = ?', [
      Variable(username),
    ]);
    return (result.first['count'] as int) > 0;
  }

  Future<User?> getUserByCredentials(String username, String password) async {
    try {
      final result = await _client.authenticate(username, password);
      if (result != null) {
        return User(
          id: result['id'],
          nom: result['nom'],
          username: result['username'],
          motDePasse: result['motDePasse'],
          role: result['role'],
          actif: result['actif'] == 1,
          dateCreation: DateTime.parse(result['dateCreation']),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Erreur authentification réseau: $e');
    }
  }

  // Méthodes pour les statistiques
  Future<int> getTotalClients() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM clt');
    return result.first['count'] as int;
  }

  Future<int> getTotalArticles() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM articles');
    return result.first['count'] as int;
  }

  Future<double> getTotalStockValue() async {
    final result = await customSelect('SELECT COALESCE(SUM(stocksu1 * pu1), 0) as total FROM articles');
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalVentes() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(totalttc), 0) as total FROM ventes WHERE contre != "1"',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getVentesToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await customSelect(
      'SELECT COALESCE(SUM(totalttc), 0) as total FROM ventes WHERE DATE(daty) = ? AND contre != "1"',
      [Variable(today)],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<String>> getAllModesPaiement() async {
    final result = await customSelect('SELECT mp FROM mp ORDER BY mp');
    return result.map((row) => row['mp'] as String).toList();
  }
}
