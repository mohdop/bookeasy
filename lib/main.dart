import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  //  POUR LE DIAGNOSTIC
  print('==========================================');
  print('🔍 DIAGNOSTIC SESSION AU DÉMARRAGE');
  print('==========================================');
  
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    print('❌ Aucune session trouvée au démarrage');
  } else {
    print('✅ Session trouvée !');
    print('User: ${session.user.email}');
    print('Token existe: ${session.accessToken.isNotEmpty}');
    print('Expire à: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}');
  }
  
  // Écouter les changements
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    print('🔐 Auth State Change: ${data.event}');
    if (data.session != null) {
      print('   User: ${data.session!.user.email}');
    }
  });
  
  print('==========================================');
  
  runApp(const BookEasyApp());
}