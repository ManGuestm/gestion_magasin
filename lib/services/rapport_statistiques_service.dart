import 'package:drift/drift.dart';

import '../database/database_service.dart';

class RapportStatistiquesService {
  static final RapportStatistiquesService _instance = RapportStatistiquesService._internal();
  factory RapportStatistiquesService() => _instance;
  RapportStatistiquesService._internal();

  final DatabaseService _db = DatabaseService();

  /// Statistiques de ventes par période
  Future<Map<String, dynamic>> getStatistiquesVentes(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           COUNT(*) as nombre_ventes,
           COALESCE(SUM(totalnt), 0) as total_ht,
           COALESCE(SUM(totalttc), 0) as total_ttc,
           COALESCE(SUM(tva), 0) as total_tva,
           COALESCE(AVG(totalttc), 0) as moyenne_vente,
           COUNT(DISTINCT clt) as nombre_clients
         FROM ventes 
         WHERE daty BETWEEN ? AND ? AND verification = 'Journal' ''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).getSingle();

    return {
      'nombre_ventes': result.read<int>('nombre_ventes'),
      'total_ht': result.read<double>('total_ht'),
      'total_ttc': result.read<double>('total_ttc'),
      'total_tva': result.read<double>('total_tva'),
      'moyenne_vente': result.read<double>('moyenne_vente'),
      'nombre_clients': result.read<int>('nombre_clients'),
    };
  }

  /// Statistiques d'achats par période
  Future<Map<String, dynamic>> getStatistiquesAchats(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           COUNT(*) as nombre_achats,
           COALESCE(SUM(totalnt), 0) as total_ht,
           COALESCE(SUM(totalttc), 0) as total_ttc,
           COALESCE(SUM(tva), 0) as total_tva,
           COALESCE(AVG(totalttc), 0) as moyenne_achat,
           COUNT(DISTINCT frns) as nombre_fournisseurs
         FROM achats 
         WHERE daty BETWEEN ? AND ?''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).getSingle();

    return {
      'nombre_achats': result.read<int>('nombre_achats'),
      'total_ht': result.read<double>('total_ht'),
      'total_ttc': result.read<double>('total_ttc'),
      'total_tva': result.read<double>('total_tva'),
      'moyenne_achat': result.read<double>('moyenne_achat'),
      'nombre_fournisseurs': result.read<int>('nombre_fournisseurs'),
    };
  }

  /// Top des articles les plus vendus
  Future<List<Map<String, dynamic>>> getTopArticlesVendus(int limite, DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           dv.designation,
           a.u1, a.u2, a.u3,
           SUM(dv.q) as quantite_totale,
           SUM(dv.q * dv.pu) as chiffre_affaires,
           COUNT(*) as nombre_ventes,
           AVG(dv.pu) as prix_moyen
         FROM detventes dv
         JOIN ventes v ON dv.numventes = v.numventes
         LEFT JOIN articles a ON dv.designation = a.designation
         WHERE v.daty BETWEEN ? AND ? AND v.verification = 'Journal'
         GROUP BY dv.designation
         ORDER BY chiffre_affaires DESC
         LIMIT ?''', variables: [
      Variable(debut.toIso8601String()),
      Variable(fin.toIso8601String()),
      Variable(limite)
    ]).get();

    return result
        .map((row) => {
              'designation': row.read<String>('designation'),
              'u1': row.read<String?>('u1'),
              'u2': row.read<String?>('u2'),
              'u3': row.read<String?>('u3'),
              'quantite_totale': row.read<double>('quantite_totale'),
              'chiffre_affaires': row.read<double>('chiffre_affaires'),
              'nombre_ventes': row.read<int>('nombre_ventes'),
              'prix_moyen': row.read<double>('prix_moyen'),
            })
        .toList();
  }

  /// Top des clients par chiffre d'affaires
  Future<List<Map<String, dynamic>>> getTopClients(int limite, DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           v.clt,
           c.adr, c.tel, c.email,
           COUNT(*) as nombre_achats,
           SUM(v.totalttc) as chiffre_affaires,
           AVG(v.totalttc) as panier_moyen,
           MAX(v.daty) as derniere_visite
         FROM ventes v
         LEFT JOIN clt c ON v.clt = c.rsoc
         WHERE v.daty BETWEEN ? AND ? AND v.verification = 'Journal' AND v.clt IS NOT NULL
         GROUP BY v.clt
         ORDER BY chiffre_affaires DESC
         LIMIT ?''', variables: [
      Variable(debut.toIso8601String()),
      Variable(fin.toIso8601String()),
      Variable(limite)
    ]).get();

    return result
        .map((row) => {
              'client': row.read<String>('clt'),
              'adresse': row.read<String?>('adr'),
              'telephone': row.read<String?>('tel'),
              'email': row.read<String?>('email'),
              'nombre_achats': row.read<int>('nombre_achats'),
              'chiffre_affaires': row.read<double>('chiffre_affaires'),
              'panier_moyen': row.read<double>('panier_moyen'),
              'derniere_visite': row.read<DateTime?>('derniere_visite'),
            })
        .toList();
  }

  /// Évolution des ventes par mois
  Future<List<Map<String, dynamic>>> getEvolutionVentesMensuelle(int annee) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           strftime('%m', daty) as mois,
           COUNT(*) as nombre_ventes,
           SUM(totalttc) as chiffre_affaires
         FROM ventes 
         WHERE strftime('%Y', daty) = ? AND verification = 'Journal'
         GROUP BY strftime('%m', daty)
         ORDER BY mois''', variables: [Variable(annee.toString())]).get();

    return result
        .map((row) => {
              'mois': int.parse(row.read<String>('mois')),
              'nombre_ventes': row.read<int>('nombre_ventes'),
              'chiffre_affaires': row.read<double>('chiffre_affaires'),
            })
        .toList();
  }

  /// État des stocks par dépôt
  Future<List<Map<String, dynamic>>> getEtatStocksParDepot() async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           d.designation,
           d.depots,
           d.stocksu1, d.stocksu2, d.stocksu3,
           a.u1, a.u2, a.u3,
           a.pvu1, a.pvu2, a.pvu3,
           a.cmup,
           (d.stocksu1 * a.cmup) as valeur_stock
         FROM depart d
         LEFT JOIN articles a ON d.designation = a.designation
         WHERE d.stocksu1 > 0 OR d.stocksu2 > 0 OR d.stocksu3 > 0
         ORDER BY d.depots, d.designation''').get();

    return result
        .map((row) => {
              'designation': row.read<String>('designation'),
              'depot': row.read<String>('depots'),
              'stock_u1': row.read<double?>('stocksu1') ?? 0,
              'stock_u2': row.read<double?>('stocksu2') ?? 0,
              'stock_u3': row.read<double?>('stocksu3') ?? 0,
              'unite_1': row.read<String?>('u1'),
              'unite_2': row.read<String?>('u2'),
              'unite_3': row.read<String?>('u3'),
              'prix_u1': row.read<double?>('pvu1') ?? 0,
              'prix_u2': row.read<double?>('pvu2') ?? 0,
              'prix_u3': row.read<double?>('pvu3') ?? 0,
              'cmup': row.read<double?>('cmup') ?? 0,
              'valeur_stock': row.read<double?>('valeur_stock') ?? 0,
            })
        .toList();
  }

  /// Marges par article
  Future<List<Map<String, dynamic>>> getMargesParArticle(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           dv.designation,
           SUM(dv.q) as quantite_vendue,
           SUM(dv.q * dv.pu) as ca_vente,
           SUM(dv.q * a.cmup) as cout_achat,
           SUM(dv.q * dv.pu) - SUM(dv.q * a.cmup) as marge_brute,
           CASE 
             WHEN SUM(dv.q * dv.pu) > 0 
             THEN ((SUM(dv.q * dv.pu) - SUM(dv.q * a.cmup)) / SUM(dv.q * dv.pu)) * 100
             ELSE 0 
           END as taux_marge
         FROM detventes dv
         JOIN ventes v ON dv.numventes = v.numventes
         LEFT JOIN articles a ON dv.designation = a.designation
         WHERE v.daty BETWEEN ? AND ? AND v.verification = 'Journal'
         GROUP BY dv.designation
         HAVING quantite_vendue > 0
         ORDER BY marge_brute DESC''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).get();

    return result
        .map((row) => {
              'designation': row.read<String>('designation'),
              'quantite_vendue': row.read<double>('quantite_vendue'),
              'ca_vente': row.read<double>('ca_vente'),
              'cout_achat': row.read<double>('cout_achat'),
              'marge_brute': row.read<double>('marge_brute'),
              'taux_marge': row.read<double>('taux_marge'),
            })
        .toList();
  }

  /// Soldes clients
  Future<List<Map<String, dynamic>>> getSoldesClients() async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           c.rsoc,
           c.adr, c.tel, c.email,
           c.soldes,
           c.plafon,
           c.delai,
           c.datedernop,
           CASE 
             WHEN c.datedernop IS NOT NULL 
             THEN julianday('now') - julianday(c.datedernop)
             ELSE NULL 
           END as jours_depuis_derniere_op
         FROM clt c
         WHERE c.soldes != 0
         ORDER BY c.soldes DESC''').get();

    return result
        .map((row) => {
              'client': row.read<String>('rsoc'),
              'adresse': row.read<String?>('adr'),
              'telephone': row.read<String?>('tel'),
              'email': row.read<String?>('email'),
              'solde': row.read<double?>('soldes') ?? 0,
              'plafond': row.read<double?>('plafon') ?? 0,
              'delai': row.read<int?>('delai') ?? 0,
              'derniere_operation': row.read<DateTime?>('datedernop'),
              'jours_depuis_derniere_op': row.read<double?>('jours_depuis_derniere_op')?.round(),
            })
        .toList();
  }

  /// Soldes fournisseurs
  Future<List<Map<String, dynamic>>> getSoldesFournisseurs() async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           f.rsoc,
           f.adr, f.tel, f.email,
           f.soldes,
           f.datedernop,
           CASE 
             WHEN f.datedernop IS NOT NULL 
             THEN julianday('now') - julianday(f.datedernop)
             ELSE NULL 
           END as jours_depuis_derniere_op
         FROM frns f
         WHERE f.soldes != 0
         ORDER BY f.soldes DESC''').get();

    return result
        .map((row) => {
              'fournisseur': row.read<String>('rsoc'),
              'adresse': row.read<String?>('adr'),
              'telephone': row.read<String?>('tel'),
              'email': row.read<String?>('email'),
              'solde': row.read<double?>('soldes') ?? 0,
              'derniere_operation': row.read<DateTime?>('datedernop'),
              'jours_depuis_derniere_op': row.read<double?>('jours_depuis_derniere_op')?.round(),
            })
        .toList();
  }

  /// Commissions des commerciaux
  Future<List<Map<String, dynamic>>> getCommissionsCommerciaux(DateTime debut, DateTime fin) async {
    final database = _db.database;

    final result = await database.customSelect('''SELECT 
           v.commerc,
           c.adr, c.tel, c.email,
           COUNT(*) as nombre_ventes,
           SUM(v.totalttc) as chiffre_affaires,
           SUM(v.commission) as total_commissions,
           AVG(v.commission) as commission_moyenne
         FROM ventes v
         LEFT JOIN com c ON v.commerc = c.nom
         WHERE v.daty BETWEEN ? AND ? AND v.verification = 'Journal' 
               AND v.commerc IS NOT NULL AND v.commission > 0
         GROUP BY v.commerc
         ORDER BY total_commissions DESC''',
        variables: [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())]).get();

    return result
        .map((row) => {
              'commercial': row.read<String>('commerc'),
              'adresse': row.read<String?>('adr'),
              'telephone': row.read<String?>('tel'),
              'email': row.read<String?>('email'),
              'nombre_ventes': row.read<int>('nombre_ventes'),
              'chiffre_affaires': row.read<double>('chiffre_affaires'),
              'total_commissions': row.read<double>('total_commissions'),
              'commission_moyenne': row.read<double>('commission_moyenne'),
            })
        .toList();
  }

  /// Mouvements de stock par article
  Future<List<Map<String, dynamic>>> getMouvementsStock(
      String? designation, DateTime debut, DateTime fin) async {
    final database = _db.database;

    String whereClause = 'WHERE s.daty BETWEEN ? AND ?';
    List<Variable> variables = [Variable(debut.toIso8601String()), Variable(fin.toIso8601String())];

    if (designation != null) {
      whereClause += ' AND s.refart = ?';
      variables.add(Variable(designation));
    }

    final result = await database.customSelect('''SELECT 
           s.ref, s.daty, s.lib, s.refart, s.depots,
           s.qe, s.qs, s.entres, s.sortie,
           s.ue, s.us, s.pus, s.cmup,
           s.numventes, s.numachats, s.verification,
           s.clt, s.frns
         FROM stocks s
         $whereClause
         ORDER BY s.daty DESC, s.ref DESC''', variables: variables).get();

    return result
        .map((row) => {
              'reference': row.read<String>('ref'),
              'date': row.read<DateTime?>('daty'),
              'libelle': row.read<String?>('lib'),
              'article': row.read<String?>('refart'),
              'depot': row.read<String?>('depots'),
              'quantite_entree': row.read<double?>('qe') ?? 0,
              'quantite_sortie': row.read<double?>('qs') ?? 0,
              'entrees': row.read<double?>('entres') ?? 0,
              'sorties': row.read<double?>('sortie') ?? 0,
              'unite_entree': row.read<String?>('ue'),
              'unite_sortie': row.read<String?>('us'),
              'prix_unitaire': row.read<double?>('pus') ?? 0,
              'cmup': row.read<double?>('cmup') ?? 0,
              'num_vente': row.read<String?>('numventes'),
              'num_achat': row.read<String?>('numachats'),
              'type': row.read<String?>('verification'),
              'client': row.read<String?>('clt'),
              'fournisseur': row.read<String?>('frns'),
            })
        .toList();
  }

  /// Tableau de bord général
  Future<Map<String, dynamic>> getTableauBord() async {
    final database = _db.database;

    // Statistiques du jour
    final aujourdhui = DateTime.now();
    final debutJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
    final finJour = debutJour.add(const Duration(days: 1));

    final ventesJour = await database.customSelect(
        '''SELECT COUNT(*) as nb, COALESCE(SUM(totalttc), 0) as total
         FROM ventes 
         WHERE daty BETWEEN ? AND ? AND verification = 'Journal' ''',
        variables: [Variable(debutJour.toIso8601String()), Variable(finJour.toIso8601String())]).getSingle();

    // Statistiques du mois
    final debutMois = DateTime(aujourdhui.year, aujourdhui.month, 1);
    final finMois = DateTime(aujourdhui.year, aujourdhui.month + 1, 1);

    final ventesMois = await database.customSelect(
        '''SELECT COUNT(*) as nb, COALESCE(SUM(totalttc), 0) as total
         FROM ventes 
         WHERE daty BETWEEN ? AND ? AND verification = 'Journal' ''',
        variables: [Variable(debutMois.toIso8601String()), Variable(finMois.toIso8601String())]).getSingle();

    // Nombre total d'articles
    final nbArticles = await database.customSelect('SELECT COUNT(*) as nb FROM articles').getSingle();

    // Nombre total de clients
    final nbClients = await database.customSelect('SELECT COUNT(*) as nb FROM clt').getSingle();

    // Valeur totale du stock
    final valeurStock = await database.customSelect('''SELECT COALESCE(SUM(stocksu1 * cmup), 0) as valeur
         FROM articles 
         WHERE stocksu1 > 0 AND cmup > 0''').getSingle();

    return {
      'ventes_jour': {
        'nombre': ventesJour.read<int>('nb'),
        'montant': ventesJour.read<double>('total'),
      },
      'ventes_mois': {
        'nombre': ventesMois.read<int>('nb'),
        'montant': ventesMois.read<double>('total'),
      },
      'nombre_articles': nbArticles.read<int>('nb'),
      'nombre_clients': nbClients.read<int>('nb'),
      'valeur_stock': valeurStock.read<double>('valeur'),
    };
  }
}
