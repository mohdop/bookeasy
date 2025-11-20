import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../data/providers/supabase_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // 1. Se connecter avec Supabase
    final response = await SupabaseProvider.client.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (response.user == null) {
      throw Exception('Erreur de connexion');
    }

    // 2. Attendre un peu pour que la session soit établie
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Vérifier le rôle de l'utilisateur
    if (mounted) {
      try {
        final profileData = await SupabaseProvider.table('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        final userRole = profileData['role'] as String;

        // 4. Rediriger selon le rôle
        if (userRole == 'business_owner') {
          // Vérifier si le business existe
          final businessData = await SupabaseProvider.table('businesses')
              .select('id')
              .eq('owner_id', response.user!.id)
              .maybeSingle();

          if (businessData == null) {
            // Pas de business, aller au setup
            GoRouterHelper(context).go('/business-setup');
          } else {
            // Business existe, aller au dashboard
            GoRouterHelper(context).go('/dashboard');
          }
        } else {
          // Client: aller à une page d'accueil client
          // TODO: Créer une vraie page d'accueil client
          context.showSnackBar('Bienvenue ! Page client en développement');
          
          // Temporairement, déconnecter le client
          await SupabaseProvider.client.auth.signOut();
          
          if (mounted) {
            context.showSnackBar(
              'Fonctionnalité client en cours de développement. Utilisez un compte professionnel.',
              isError: true,
            );
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération du profil: $e');
        // Si erreur, aller au dashboard par défaut
        GoRouterHelper(context).go('/dashboard');
      }
    }
  } on AuthException catch (e) {
    if (mounted) {
      String errorMessage = 'Email ou mot de passe incorrect';
      
      if (e.message.contains('Invalid login')) {
        errorMessage = 'Email ou mot de passe incorrect';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Veuillez confirmer votre email';
      } else {
        errorMessage = e.message;
      }
      
      context.showSnackBar(errorMessage, isError: true);
    }
  } catch (e) {
    if (mounted) {
      context.showSnackBar(
        'Erreur de connexion: ${e.toString()}',
        isError: true,
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    
                    child: const Center(
                      child:  Image(image: AssetImage("assets/images/BookEasy_white.png"),)
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Bienvenue sur',
                  textAlign: TextAlign.center,
                  style: ContextExtension(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'BookEasy',
                  textAlign: TextAlign.center,
                  style: ContextExtension(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontFamily:  GoogleFonts.lobster.toString(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos rendez-vous simplement',
                  textAlign: TextAlign.center,
                  style: ContextExtension(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'votre@email.com',
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                CustomTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordController,
                  validator: Validators.password,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      context.showSnackBar('Fonctionnalité bientôt disponible');
                    },
                    child: Text(
                      'Mot de passe oublié?',
                      style: ContextExtension(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                CustomButton(
                  text: 'Se connecter',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 32),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: ContextExtension(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte? ',
                      style: ContextExtension(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => GoRouterHelper(context).go('/register'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'S\'inscrire',
                        style: ContextExtension(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
