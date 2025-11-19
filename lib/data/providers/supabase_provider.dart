import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseProvider {
  static SupabaseClient get client => supabase;
  
  // Auth helpers
  static User? get currentUser => supabase.auth.currentUser;
  static String? get currentUserId => supabase.auth.currentUser?.id;
  static bool get isLoggedIn => supabase.auth.currentUser != null;
  
  // Database helpers
  static SupabaseQueryBuilder table(String tableName) {
    return supabase.from(tableName);
  }
  
  // Storage helpers
  static SupabaseStorageClient get storage => supabase.storage;
}