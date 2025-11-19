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

final supabase = Supabase.instance.client;

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    
    // If logged in and trying to access auth pages, redirect to dashboard
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }
    
    // If not logged in and trying to access protected pages, redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    
    return null; // Allow navigation
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Page introuvable: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    ),
  ),
);