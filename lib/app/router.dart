// lib/app/router.dart
import '../features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/business/screens/dashboard_screen.dart';
import '../features/business/screens/business_setup_screen.dart';
import '../features/services/screens/services_list_screen.dart';
import '../features/services/screens/edit_service_screen.dart';
import '../features/appointments/screens/appointments_list_screen.dart';
import '../features/client/screens/business_profile_screen.dart';
import '../features/client/screens/client_home_screen.dart';
import '../features/client/screens/client_my_bookings_screen.dart'; // For viewing bookings
import '../features/client/screens/my_bookings_screen.dart'; // For creating new bookings (BookingScreen)
import '../data/providers/supabase_provider.dart';
import '../app/theme.dart';
import '../features/business/screens/business_settings_screen.dart';
import '../features/business/screens/business_owner_profile_screen.dart';
import '../features/business/screens/analytics_screen.dart';
import '../features/business/screens/customers_screen.dart';
import '../features/client/screens/client_profile_screen.dart';
import '../features/client/screens/client_settings_screen.dart';
import '../features/client/screens/advanced_search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


final supabase = Supabase.instance.client;

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
  initialLocation: '/onboarding',  // Changed from '/login'
  redirect: (context, state) async {
    final session = supabase.auth.currentSession;
    final isLoggedIn = session != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    final isOnboarding = state.matchedLocation == '/onboarding';
    
    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    // If onboarding not completed and not on onboarding page, go to onboarding
    if (!onboardingCompleted && !isOnboarding) {
      return '/onboarding';
    }
    
    // If onboarding completed but on onboarding page, go to login
    if (onboardingCompleted && isOnboarding) {
      return '/login';
    }
    
    // If not logged in and not on auth or onboarding, redirect to login
    if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
      return '/login';
    }
    
    // If logged in and on auth page, redirect based on role
    if (isLoggedIn && isAuthRoute) {
      try {
        final profileData = await SupabaseProvider.table('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();
        
        final userRole = profileData['role'] as String;
        
        if (userRole == 'business_owner') {
          final businessData = await SupabaseProvider.table('businesses')
              .select('id')
              .eq('owner_id', session.user.id)
              .maybeSingle();
          
          return businessData == null ? '/business-setup' : '/dashboard';
        } else {
          return '/client-home';
        }
      } catch (e) {
        print('Error checking role: $e');
        return '/dashboard';
      }
    }
    
    return null; // Allow navigation
  },
  routes: [

    GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingScreen(),
  ),
    // =============================================
    // AUTH ROUTES
    // =============================================
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // =============================================
    // BUSINESS OWNER ROUTES
    // =============================================
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
    // Add after the dashboard route
    GoRoute(
      path: '/business-settings',
      builder: (context, state) => const BusinessSettingsScreen(),
    ),
    GoRoute(
      path: '/owner-profile',
      builder: (context, state) => const BusinessOwnerProfileScreen(),
    ),
    // Add after other business owner routes
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersScreen(),
    ),
    
    // =============================================
    // CLIENT ROUTES
    // =============================================
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
    // Add after other client routes
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