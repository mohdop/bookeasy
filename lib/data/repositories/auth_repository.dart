import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class AuthRepository {
  final _supabase = SupabaseProvider.client;
  
  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
      },
    );
  }
  
  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get Current User
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  // Check if logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
  
  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}