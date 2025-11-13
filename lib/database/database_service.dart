import 'database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  AppDatabase? _database;
  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    _database = AppDatabase();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}