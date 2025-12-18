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
            tu2u1: row['tu2u1'],
            tu3u2: row['tu3u2'],
            pvu1: row['pvu1'],
            pvu2: row['pvu2'],
            pvu3: row['pvu3'],
            stocksu1: row['stocksu1'],
            stocksu2: row['stocksu2'],
            stocksu3: row['stocksu3'],
            sec: row['sec'],
            usec: row['usec'],
            cmup: row['cmup'],
            dep: row['dep'],
            action: row['action'],
            categorie: row['categorie'],
            classification: row['classification'],
            emb: row['emb'],
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
            tu2u1: row['tu2u1'],
            tu3u2: row['tu3u2'],
            pvu1: row['pvu1'],
            pvu2: row['pvu2'],
            pvu3: row['pvu3'],
            stocksu1: row['stocksu1'],
            stocksu2: row['stocksu2'],
            stocksu3: row['stocksu3'],
            sec: row['sec'],
            usec: row['usec'],
            cmup: row['cmup'],
            dep: row['dep'],
            action: row['action'],
            categorie: row['categorie'],
            classification: row['classification'],
            emb: row['emb'],
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
            categorie: row['categorie'],
            capital: row['capital'],
            port: row['port'],
            site: row['site'],
            fax: row['fax'],
            telex: row['telex'],
            datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
            delai: row['delai'],
            soldesa: row['soldesa'],
            action: row['action'],
            commercial: row['commercial'],
            plafon: row['plafon'],
            taux: row['taux'],
            plafonbl: row['plafonbl'],
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
            categorie: row['categorie'],
            capital: row['capital'],
            port: row['port'],
            site: row['site'],
            fax: row['fax'],
            telex: row['telex'],
            datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
            delai: row['delai'],
            soldesa: row['soldesa'],
            action: row['action'],
            commercial: row['commercial'],
            plafon: row['plafon'],
            taux: row['taux'],
            plafonbl: row['plafonbl'],
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
            capital: row['capital'],
            rcs: row['rcs'],
            nif: row['nif'],
            stat: row['stat'],
            tel: row['tel'],
            port: row['port'],
            email: row['email'],
            site: row['site'],
            fax: row['fax'],
            telex: row['telex'],
            soldes: row['soldes'],
            datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
            delai: row['delai'],
            soldesa: row['soldesa'],
            action: row['action'],
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
            capital: row['capital'],
            rcs: row['rcs'],
            nif: row['nif'],
            stat: row['stat'],
            tel: row['tel'],
            port: row['port'],
            email: row['email'],
            site: row['site'],
            fax: row['fax'],
            telex: row['telex'],
            soldes: row['soldes'],
            datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
            delai: row['delai'],
            soldesa: row['soldesa'],
            action: row['action'],
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
            logo: row['logo'],
            capital: row['capital'],
            rcs: row['rcs'],
            nif: row['nif'],
            stat: row['stat'],
            tel: row['tel'],
            port: row['port'],
            email: row['email'],
            site: row['site'],
            fax: row['fax'],
            telex: row['telex'],
            tva: row['tva'],
            t: row['t'],
            val: row['val'],
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
      tu2u1: row['tu2u1'],
      tu3u2: row['tu3u2'],
      pvu1: row['pvu1'],
      pvu2: row['pvu2'],
      pvu3: row['pvu3'],
      stocksu1: row['stocksu1'],
      stocksu2: row['stocksu2'],
      stocksu3: row['stocksu3'],
      sec: row['sec'],
      usec: row['usec'],
      cmup: row['cmup'],
      dep: row['dep'],
      action: row['action'],
      categorie: row['categorie'],
      classification: row['classification'],
      emb: row['emb'],
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

  // Méthodes supplémentaires pour compatibilité complète
  Future<void> createDefaultAdmin() async {
    // Vérifier si l'admin existe déjà
    final adminExists = await userExists('admin');
    if (adminExists) return;

    // Créer l'utilisateur admin par défaut
    await customStatement(
      'INSERT INTO users (id, nom, username, motDePasse, role, actif, dateCreation) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        Variable('admin-001'),
        Variable('Administrateur'),
        Variable('admin'),
        Variable('hashed_admin123'),
        Variable('Administrateur'),
        Variable(1),
        Variable(DateTime.now().toIso8601String()),
      ],
    );
  }

  Future<String> getDatabasePath() async {
    // En mode réseau, retourner un chemin virtuel
    return 'network://server/database';
  }

  Future<void> close() async {
    // Rien à fermer en mode réseau
  }

  // Méthodes manquantes pour compatibilité complète avec database.dart
  Future<CltData?> getClientByRsoc(String rsoc) async {
    final result = await customSelect('SELECT * FROM clt WHERE rsoc = ?', [Variable(rsoc)]);
    return result.isEmpty ? null : _mapCltData(result.first);
  }

  Future<Frn?> getFournisseurByRsoc(String rsoc) async {
    final result = await customSelect('SELECT * FROM frns WHERE rsoc = ?', [Variable(rsoc)]);
    return result.isEmpty ? null : _mapFrn(result.first);
  }

  Future<Depot?> getDepotByName(String name) async {
    final result = await customSelect('SELECT * FROM depots WHERE depots = ?', [Variable(name)]);
    return result.isEmpty ? null : Depot(depots: result.first['depots']);
  }

  Future<User?> getUserByUsername(String username) async {
    final result = await customSelect('SELECT * FROM users WHERE username = ?', [Variable(username)]);
    return result.isEmpty ? null : _mapUser(result.first);
  }

  Future<User?> getUserById(String id) async {
    final result = await customSelect('SELECT * FROM users WHERE id = ?', [Variable(id)]);
    return result.isEmpty ? null : _mapUser(result.first);
  }

  Future<List<User>> getAllUsers() async {
    final result = await customSelect('SELECT * FROM users ORDER BY nom');
    return result.map((row) => _mapUser(row)).toList();
  }

  // Méthodes de mapping pour éviter la duplication de code
  CltData _mapCltData(Map<String, dynamic> row) {
    return CltData(
      rsoc: row['rsoc'],
      adr: row['adr'],
      tel: row['tel'],
      email: row['email'],
      nif: row['nif'],
      stat: row['stat'],
      rcs: row['rcs'],
      soldes: row['soldes'],
      categorie: row['categorie'],
      capital: row['capital'],
      port: row['port'],
      site: row['site'],
      fax: row['fax'],
      telex: row['telex'],
      datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
      delai: row['delai'],
      soldesa: row['soldesa'],
      action: row['action'],
      commercial: row['commercial'],
      plafon: row['plafon'],
      taux: row['taux'],
      plafonbl: row['plafonbl'],
    );
  }

  Frn _mapFrn(Map<String, dynamic> row) {
    return Frn(
      rsoc: row['rsoc'],
      adr: row['adr'],
      capital: row['capital'],
      rcs: row['rcs'],
      nif: row['nif'],
      stat: row['stat'],
      tel: row['tel'],
      port: row['port'],
      email: row['email'],
      site: row['site'],
      fax: row['fax'],
      telex: row['telex'],
      soldes: row['soldes'],
      datedernop: row['datedernop'] != null ? DateTime.tryParse(row['datedernop']) : null,
      delai: row['delai'],
      soldesa: row['soldesa'],
      action: row['action'],
    );
  }

  User _mapUser(Map<String, dynamic> row) {
    return User(
      id: row['id'],
      nom: row['nom'],
      username: row['username'],
      motDePasse: row['motDePasse'],
      role: row['role'],
      actif: row['actif'] == 1,
      dateCreation: DateTime.parse(row['dateCreation']),
    );
  }
}
