import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}

class DatabaseHelper implements IDatabaseService {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      debugPrint('✅ SUCCESS: Database already initialized');
      return _database!;
    }

    try {
      debugPrint('🔄 ATTEMPTING: Initialize database...');
      _database = await _initDB('users.db');
      debugPrint('✅ SUCCESS: Database initialized successfully');
      return _database!;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to initialize database - $e');
      throw DatabaseException('Failed to initialize database: ${e.toString()}');
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      debugPrint('🔄 ATTEMPTING: Open database at $filePath...');
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      debugPrint('📁 Database path: $path');

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,

        onOpen: (db) async {
          debugPrint('🔄 ATTEMPTING: Verify database accessibility...');
          await db.query('sqlite_master');
          debugPrint('✅ SUCCESS: Database is accessible');
        },
      );

      debugPrint('✅ SUCCESS: Database opened successfully');
      return db;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to open database - $e');
      throw DatabaseException('Failed to open database: ${e.toString()}');
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      debugPrint('🔄 ATTEMPTING: Create database schema...');
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
      ''');
      debugPrint('✅ SUCCESS: Database schema created successfully');
    } catch (e) {
      debugPrint('❌ ERROR: Failed to create database schema - $e');
      throw DatabaseException('Failed to create database schema: ${e.toString()}');
    }
  }

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
    debugPrint('🔄 ATTEMPTING: Create user with email: $email');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('❌ ERROR: Email or password is empty');
      throw DatabaseException('Email and password cannot be empty');
    }

    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      final normalizedEmail = email.toLowerCase().trim();

      debugPrint('🔄 ATTEMPTING: Insert user into database...');
      final id = await db.insert(
        'users',
        {
          'email': normalizedEmail,
          'password': hashedPassword,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      debugPrint('✅ SUCCESS: User created successfully - ID: $id, Email: $normalizedEmail');
      return User(
        id: id,
        email: normalizedEmail,
        password: hashedPassword,
      );
    } on DatabaseException catch (e) {
      debugPrint('❌ ERROR: DatabaseException while creating user - $e');
      rethrow;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        debugPrint('❌ ERROR: Email already exists - $email');
        throw DatabaseException('Email already exists');
      }
      debugPrint('❌ ERROR: Failed to create user - $e');
      throw DatabaseException('Failed to create user: ${e.toString()}');
    }
  }

  Future<User?> loginUser(String email, String password) async {
    debugPrint('🔄 ATTEMPTING: Login user with email: $email');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('❌ ERROR: Email or password is empty');
      throw DatabaseException('Email and password cannot be empty');
    }

    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      final normalizedEmail = email.toLowerCase().trim();

      debugPrint('🔄 ATTEMPTING: Query user from database...');
      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [normalizedEmail, hashedPassword],
      );

      if (results.isNotEmpty) {
        debugPrint('✅ SUCCESS: User logged in successfully - Email: $normalizedEmail');
        return User.fromMap(results.first);
      }

      debugPrint('❌ ERROR: Invalid credentials for email: $email');
      return null;
    } on DatabaseException catch (e) {
      debugPrint('❌ ERROR: DatabaseException during login - $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to login user - $e');
      throw DatabaseException('Failed to login: ${e.toString()}');
    }
  }

  Future<bool> emailExists(String email) async {
    debugPrint('🔄 ATTEMPTING: Check if email exists: $email');

    if (email.isEmpty) {
      debugPrint('⚠️  WARNING: Empty email provided for existence check');
      return false;
    }

    try {
      final db = await database;
      final normalizedEmail = email.toLowerCase().trim();

      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );

      final exists = results.isNotEmpty;
      debugPrint('✅ SUCCESS: Email existence check - Email: $normalizedEmail, Exists: $exists');
      return exists;
    } on DatabaseException catch (e) {
      debugPrint('❌ ERROR: DatabaseException while checking email - $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to check email existence - $e');
      throw DatabaseException('Failed to check email: ${e.toString()}');
    }
  }

  Future<void> close() async {
    try {
      debugPrint('🔄 ATTEMPTING: Close database...');
      if (_database != null) {
        await _database!.close();
        _database = null;
        debugPrint('✅ SUCCESS: Database closed successfully');
      } else {
        debugPrint('⚠️  WARNING: Database was already closed or never opened');
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to close database - $e');
      throw DatabaseException('Failed to close database: ${e.toString()}');
    }
  }
}