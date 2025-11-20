import 'package:bookeasy/features/client/screens/my_bookings_screen.dart';
import 'package:bookeasy/features/services/screens/edit_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/business/screens/dashboard_screen.dart';
import '../features/business/screens/business_setup_screen.dart';
import '../features/services/screens/services_list_screen.dart';
import '../features/appointments/screens/appointments_list_screen.dart';
import '../features/client/screens/business_profile_screen.dart';
import '../data/providers/supabase_provider.dart';
import '../app/theme.dart';

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
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    
    // Si pas connecté et pas sur auth, aller au login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    
    // Si connecté et sur auth, aller au dashboard
    // (le dashboard gérera lui-même la vérification du rôle)
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }
    
    return null; // Laisser passer
  },
  routes: [
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
