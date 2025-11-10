import 'database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late AppDatabase _database;
  AppDatabase get database => _database;

  Future<void> initialize() async {
    _database = AppDatabase();
  }

  Future<void> close() async {
    await _database.close();
  }
}