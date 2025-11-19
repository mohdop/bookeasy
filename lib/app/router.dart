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
    final isLoggingIn = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    
    // Redirect to dashboard if logged in and trying to access login
    if (isLoggedIn && isLoggingIn) {
      return '/dashboard';
    }
    
    // Redirect to login if not logged in and trying to access protected routes
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    
    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Business Setup (First time)
    GoRoute(
      path: '/business-setup',
      builder: (context, state) => const BusinessSetupScreen(),
    ),
    
    // Dashboard Routes
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    
    // Services Routes
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
    
    // Appointments Routes
    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentsListScreen(),
    ),
    
    // Client Routes
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
        return BookingScreen(businessId: businessId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);