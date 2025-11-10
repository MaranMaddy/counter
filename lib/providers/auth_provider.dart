import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/database_helper.dart';

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IDatabaseService _dbHelper;

  AuthNotifier(this._dbHelper) : super(AuthState());

  Future<bool> signUp(String email, String password) async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🔄 AUTH PROVIDER: Starting signup process');
    debugPrint('Email: $email');

    if (!mounted) {
      debugPrint('⚠️  AUTH PROVIDER: Provider not mounted, aborting signup');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('✅ AUTH PROVIDER: Set loading state to true');

    try {
      // Validate input
      debugPrint('🔄 AUTH PROVIDER: Validating input...');
      if (email.trim().isEmpty) {
        debugPrint('❌ AUTH PROVIDER: Validation failed - Empty email');
        state = state.copyWith(
          isLoading: false,
          error: 'Email cannot be empty',
        );
        return false;
      }

      if (password.isEmpty) {
        debugPrint('❌ AUTH PROVIDER: Validation failed - Empty password');
        state = state.copyWith(
          isLoading: false,
          error: 'Password cannot be empty',
        );
        return false;
      }
      debugPrint('✅ AUTH PROVIDER: Input validation passed');

      // Check if email already exists
      debugPrint('🔄 AUTH PROVIDER: Checking if email exists...');
      final emailExists = await _dbHelper.emailExists(email);
      if (emailExists) {
        debugPrint('❌ AUTH PROVIDER: Email already exists - $email');
        state = state.copyWith(
          isLoading: false,
          error: 'An account with this email already exists',
        );
        return false;
      }
      debugPrint('✅ AUTH PROVIDER: Email is available');

      // Create user
      debugPrint('🔄 AUTH PROVIDER: Creating user account...');
      final user = await _dbHelper.createUser(email, password);
      if (user != null) {
        if (!mounted) {
          debugPrint('⚠️  AUTH PROVIDER: Provider unmounted during signup');
          return false;
        }
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          error: null,
          isAuthenticated: true,
        );
        debugPrint('✅ AUTH PROVIDER: Signup successful - User ID: ${user.id}, Email: ${user.email}');
        debugPrint('═══════════════════════════════════════════════');
        return true;
      } else {
        debugPrint('❌ AUTH PROVIDER: User creation returned null');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create account. Please try again.',
        );
        debugPrint('═══════════════════════════════════════════════');
        return false;
      }
    } on DatabaseException catch (e) {
      if (!mounted) return false;
      debugPrint('❌ AUTH PROVIDER: DatabaseException during signup - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      debugPrint('═══════════════════════════════════════════════');
      return false;
    } catch (e) {
      if (!mounted) return false;
      debugPrint('❌ AUTH PROVIDER: Unexpected error during signup - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      debugPrint('═══════════════════════════════════════════════');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🔄 AUTH PROVIDER: Starting login process');
    debugPrint('Email: $email');

    if (!mounted) {
      debugPrint('⚠️  AUTH PROVIDER: Provider not mounted, aborting login');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('✅ AUTH PROVIDER: Set loading state to true');

    try {
      // Validate input
      debugPrint('🔄 AUTH PROVIDER: Validating input...');
      if (email.trim().isEmpty) {
        debugPrint('❌ AUTH PROVIDER: Validation failed - Empty email');
        state = state.copyWith(
          isLoading: false,
          error: 'Email cannot be empty',
        );
        return false;
      }

      if (password.isEmpty) {
        debugPrint('❌ AUTH PROVIDER: Validation failed - Empty password');
        state = state.copyWith(
          isLoading: false,
          error: 'Password cannot be empty',
        );
        return false;
      }
      debugPrint('✅ AUTH PROVIDER: Input validation passed');

      // Attempt login
      debugPrint('🔄 AUTH PROVIDER: Attempting login...');
      final user = await _dbHelper.loginUser(email, password);
      if (user != null) {
        if (!mounted) {
          debugPrint('⚠️  AUTH PROVIDER: Provider unmounted during login');
          return false;
        }
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          error: null,
          isAuthenticated: true,
        );
        debugPrint('✅ AUTH PROVIDER: Login successful - User ID: ${user.id}, Email: ${user.email}');
        debugPrint('═══════════════════════════════════════════════');
        return true;
      } else {
        debugPrint('❌ AUTH PROVIDER: Invalid credentials provided');
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password. Please try again.',
        );
        debugPrint('═══════════════════════════════════════════════');
        return false;
      }
    } on DatabaseException catch (e) {
      if (!mounted) return false;
      debugPrint('❌ AUTH PROVIDER: DatabaseException during login - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      debugPrint('═══════════════════════════════════════════════');
      return false;
    } catch (e) {
      if (!mounted) return false;
      debugPrint('❌ AUTH PROVIDER: Unexpected error during login - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please check your connection and try again.',
      );
      debugPrint('═══════════════════════════════════════════════');
      return false;
    }
  }

  void logout() {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🔄 AUTH PROVIDER: Starting logout process');
    try {
      if (!mounted) {
        debugPrint('⚠️  AUTH PROVIDER: Provider not mounted during logout');
        return;
      }
      final userEmail = state.currentUser?.email;
      state = AuthState();
      debugPrint('✅ AUTH PROVIDER: Logout successful - User: $userEmail');
      debugPrint('═══════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ AUTH PROVIDER: Error during logout - $e');
      state = AuthState();
      debugPrint('═══════════════════════════════════════════════');
    }
  }

  void clearError() {
    if (!mounted) return;
    debugPrint('✅ AUTH PROVIDER: Clearing error state');
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(DatabaseService.instance);
});