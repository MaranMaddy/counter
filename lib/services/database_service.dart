import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'database_helper_web.dart';

abstract class IDatabaseService {
  Future<User?> createUser(String email, String password);
  Future<User?> loginUser(String email, String password);
  Future<bool> emailExists(String email);
}

class DatabaseService implements IDatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  late final IDatabaseService _db;

  DatabaseService._init() {
    if (kIsWeb) {
      _db = DatabaseHelperWeb.instance;
      debugPrint('🌐 DATABASE SERVICE: Using Web database (SharedPreferences)');
    } else {
      _db = DatabaseHelper.instance;
      debugPrint('💾 DATABASE SERVICE: Using Native database (SQLite)');
    }
  }

  @override
  Future<User?> createUser(String email, String password) {
    return _db.createUser(email, password);
  }

  @override
  Future<User?> loginUser(String email, String password) {
    return _db.loginUser(email, password);
  }

  @override
  Future<bool> emailExists(String email) {
    return _db.emailExists(email);
  }
}