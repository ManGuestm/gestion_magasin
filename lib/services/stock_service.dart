import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_service.dart';

class StockService {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> updateStockForUnit(Article article, String unit, double quantity) async {
    if (unit == article.u1) {
      double newStock = (article.stocksu1 ?? 0) + quantity;
      await (_databaseService.database.update(_databaseService.database.articles)
            ..where((a) => a.designation.equals(article.designation)))
          .write(ArticlesCompanion(stocksu1: drift.Value(newStock)));
    } else if (unit == article.u2) {
      double newStock = (article.stocksu2 ?? 0) + quantity;
      await (_databaseService.database.update(_databaseService.database.articles)
            ..where((a) => a.designation.equals(article.designation)))
          .write(ArticlesCompanion(stocksu2: drift.Value(newStock)));
    } else if (unit == article.u3) {
      double newStock = (article.stocksu3 ?? 0) + quantity;
      await (_databaseService.database.update(_databaseService.database.articles)
            ..where((a) => a.designation.equals(article.designation)))
          .write(ArticlesCompanion(stocksu3: drift.Value(newStock)));
    }
  }

  Future<void> updateDepartStock(Article article, String depot, String unit, double quantity) async {
    final existingDepart = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    if (existingDepart != null) {
      if (unit == article.u1) {
        double newStock = (existingDepart.stocksu1 ?? 0) + quantity;
        await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
            .write(DepartCompanion(stocksu1: drift.Value(newStock)));
      } else if (unit == article.u2) {
        double newStock = (existingDepart.stocksu2 ?? 0) + quantity;
        await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
            .write(DepartCompanion(stocksu2: drift.Value(newStock)));
      } else if (unit == article.u3) {
        double newStock = (existingDepart.stocksu3 ?? 0) + quantity;
        await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
            .write(DepartCompanion(stocksu3: drift.Value(newStock)));
      }
    } else {
      await _databaseService.database.into(_databaseService.database.depart).insert(
            DepartCompanion.insert(
              designation: article.designation,
              depots: depot,
              stocksu1: drift.Value(unit == article.u1 ? quantity : 0.0),
              stocksu2: drift.Value(unit == article.u2 ? quantity : 0.0),
              stocksu3: drift.Value(unit == article.u3 ? quantity : 0.0),
            ),
          );
    }
  }

  double calculateTotalStock(Article article) {
    double total = article.stocksu1 ?? 0;
    if (article.u2 != null && article.tu2u1 != null) {
      total += (article.stocksu2 ?? 0) * article.tu2u1!;
    }
    if (article.u3 != null && article.tu3u2 != null && article.tu2u1 != null) {
      total += (article.stocksu3 ?? 0) * article.tu3u2! * article.tu2u1!;
    }
    return total;
  }

  double calculateCMUP(Article article, double newQuantity, double newPrice) {
    double currentStock = calculateTotalStock(article);
    double currentCMUP = article.cmup ?? 0.0;
    
    double initialValue = currentStock * currentCMUP;
    double newValue = newQuantity * newPrice;
    double totalQuantity = currentStock + newQuantity;

    return totalQuantity == 0 ? newPrice : (initialValue + newValue) / totalQuantity;
  }
}