import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'database_service.dart';

class DatabaseHelperWeb implements IDatabaseService {
  static final DatabaseHelperWeb instance = DatabaseHelperWeb._init();

  DatabaseHelperWeb._init();

  String _hashPassword(String password) {
    try {
      debugPrint('🔄 ATTEMPTING: Hash password...');
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      debugPrint('✅ SUCCESS: Password hashed successfully');
      return digest.toString();
    } catch (e) {
      debugPrint('❌ ERROR: Failed to hash password - $e');
      throw DatabaseException('Failed to hash password: ${e.toString()}');
    }
  }

  Future<User?> createUser(String email, String password) async {
    debugPrint('🔄 ATTEMPTING: Create user with email: $email (WEB)');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('❌ ERROR: Email or password is empty');
      throw DatabaseException('Email and password cannot be empty');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();

      // Check if user already exists
      final existingUser = prefs.getString('user_$normalizedEmail');
      if (existingUser != null) {
        debugPrint('❌ ERROR: Email already exists - $email');
        throw DatabaseException('Email already exists');
      }

      final hashedPassword = _hashPassword(password);

      // Store user data
      final userData = jsonEncode({
        'email': normalizedEmail,
        'password': hashedPassword,
        'id': DateTime.now().millisecondsSinceEpoch,
      });

      await prefs.setString('user_$normalizedEmail', userData);
      debugPrint('✅ SUCCESS: User created successfully - Email: $normalizedEmail');

      return User(
        id: DateTime.now().millisecondsSinceEpoch,
        email: normalizedEmail,
        password: hashedPassword,
      );
    } catch (e) {
      if (e is DatabaseException) {
        rethrow;
      }
      debugPrint('❌ ERROR: Failed to create user - $e');
      throw DatabaseException('Failed to create user: ${e.toString()}');
    }
  }

  Future<User?> loginUser(String email, String password) async {
    debugPrint('🔄 ATTEMPTING: Login user with email: $email (WEB)');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('❌ ERROR: Email or password is empty');
      throw DatabaseException('Email and password cannot be empty');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final hashedPassword = _hashPassword(password);

      final userData = prefs.getString('user_$normalizedEmail');

      if (userData == null) {
        debugPrint('❌ ERROR: Invalid credentials for email: $email');
        return null;
      }

      final userMap = jsonDecode(userData);

      if (userMap['password'] == hashedPassword) {
        debugPrint('✅ SUCCESS: User logged in successfully - Email: $normalizedEmail');
        return User.fromMap(userMap);
      } else {
        debugPrint('❌ ERROR: Invalid credentials for email: $email');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to login user - $e');
      throw DatabaseException('Failed to login: ${e.toString()}');
    }
  }

  Future<bool> emailExists(String email) async {
    debugPrint('🔄 ATTEMPTING: Check if email exists: $email (WEB)');

    if (email.isEmpty) {
      debugPrint('⚠️  WARNING: Empty email provided for existence check');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final exists = prefs.containsKey('user_$normalizedEmail');

      debugPrint('✅ SUCCESS: Email existence check - Email: $normalizedEmail, Exists: $exists');
      return exists;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to check email existence - $e');
      throw DatabaseException('Failed to check email: ${e.toString()}');
    }
  }
}