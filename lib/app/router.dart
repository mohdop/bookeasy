// lib/app/router.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/business/screens/dashboard_screen.dart';
import '../features/business/screens/business_setup_screen.dart';
import '../features/services/screens/services_list_screen.dart';
import '../features/services/screens/edit_service_screen.dart';
import '../features/appointments/screens/appointments_list_screen.dart';
import '../features/client/screens/business_profile_screen.dart';
import '../features/client/screens/client_home_screen.dart';
import '../features/client/screens/client_my_bookings_screen.dart';
import '../features/client/screens/my_bookings_screen.dart';
import '../features/business/screens/business_settings_screen.dart';
import '../features/business/screens/business_owner_profile_screen.dart';
import '../features/business/screens/analytics_screen.dart';
import '../features/business/screens/customers_screen.dart';
import '../features/client/screens/client_profile_screen.dart';
import '../features/client/screens/client_settings_screen.dart';
import '../features/client/screens/advanced_search_screen.dart';
import '../web/landing_web_page.dart';
import '../data/providers/supabase_provider.dart';
import '../app/theme.dart';

final supabase = Supabase.instance.client;

// =============================================
// 🔑 CLÉS DU SUCCÈS : AuthNotifier + refreshListenable
// =============================================
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    // Écouter TOUS les changements d'authentification
    supabase.auth.onAuthStateChange.listen((data) {
      print('🔐 Auth event: ${data.event}');
      notifyListeners(); // ✅ Rafraîchir le router
    });
  }
}

final authNotifier = AuthNotifier();

// Helper pour vérifier si l'utilisateur est business owner
Future<bool> _isBusinessOwner() async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final profileData = await SupabaseProvider.table('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return profileData['role'] == 'business_owner';
  } catch (e) {
    return false;
  }
}

final router = GoRouter(
  initialLocation: kIsWeb ? '/web-landing' : '/onboarding',
  refreshListenable: authNotifier, // ✅ CRUCIAL : Rafraîchir quand auth change
  redirect: (context, state) async {
  await Future.delayed(const Duration(milliseconds: 100));
  
  final session = supabase.auth.currentSession;
  final isLoggedIn = session != null;
  
  print('📍 Route: ${state.matchedLocation} | Logged in: $isLoggedIn');

  // Web logic
  if (kIsWeb) {
    if (state.matchedLocation == '/web-landing') return null;
    return '/web-landing';
  }

  // --- MOBILE LOGIC ---
  final isAuthRoute = state.matchedLocation == '/login' ||
                      state.matchedLocation == '/register';
  final isOnboarding = state.matchedLocation == '/onboarding';

  // Onboarding check
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // ✅ FIX : Si connecté, ignorer l'onboarding
  if (isLoggedIn) {
    // Si sur onboarding ou auth, rediriger vers la vraie page
    if (isOnboarding || isAuthRoute) {
      try {
        final profileData = await SupabaseProvider.table('profiles')
            .select('role')
            .eq('id', session!.user.id)
            .single();

        final userRole = profileData['role'] as String;
        print('👤 User role: $userRole');

        if (userRole == 'business_owner') {
          final businessData = await SupabaseProvider.table('businesses')
              .select('id')
              .eq('owner_id', session.user.id)
              .maybeSingle();

          final destination = businessData == null ? '/business-setup' : '/dashboard';
          print('➡️ Redirecting to: $destination');
          return destination;
        } else {
          print('➡️ Redirecting to: /client-home');
          return '/client-home';
        }
      } catch (e) {
        print('❌ Error: $e');
        return '/dashboard';
      }
    }
    // Si connecté et sur une autre page, laisser passer
    return null;
  }

  // ✅ Si PAS connecté, vérifier l'onboarding
  if (!onboardingCompleted && !isOnboarding) {
    print('➡️ Redirecting to: /onboarding (not completed)');
    return '/onboarding';
  }

  if (onboardingCompleted && isOnboarding) {
    print('➡️ Redirecting to: /login (onboarding done)');
    return '/login';
  }

  if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
    print('➡️ Redirecting to: /login (not logged in)');
    return '/login';
  }

  return null;
},
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/business-setup',
      builder: (context, state) => const BusinessSetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const ServicesListScreen(),
    ),
    GoRoute(
      path: '/services/create',
      builder: (context, state) => const CreateServiceScreen(),
    ),
    GoRoute(
      path: '/services/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateServiceScreen(serviceId: id);
      },
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentsListScreen(),
    ),
    GoRoute(
      path: '/business-settings',
      builder: (context, state) => const BusinessSettingsScreen(),
    ),
    GoRoute(
      path: '/owner-profile',
      builder: (context, state) => const BusinessOwnerProfileScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersScreen(),
    ),
    GoRoute(
      path: '/client-home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const ClientMyBookingsScreen(),
    ),
    GoRoute(
      path: '/business/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BusinessProfileScreen(businessId: id);
      },
    ),
    GoRoute(
      path: '/booking/:businessId',
      builder: (context, state) {
        final businessId = state.pathParameters['businessId']!;
        final serviceId = state.uri.queryParameters['serviceId'];
        return BookingScreen(
          businessId: businessId,
          serviceId: serviceId,
        );
      },
    ),
    GoRoute(
      path: '/web-landing',
      builder: (context, state) => const LandingWebPage(),
    ),
    GoRoute(
      path: '/client-profile',
      builder: (context, state) => const ClientProfileScreen(),
    ),
    GoRoute(
      path: '/client-settings',
      builder: (context, state) => const ClientSettingsScreen(),
    ),
    GoRoute(
      path: '/advanced-search',
      builder: (context, state) => const AdvancedSearchScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Page introuvable: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Retour'),
          ),
        ],
      ),
    ),
  ),
);