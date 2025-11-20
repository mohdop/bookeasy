import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../data/providers/supabase_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _role = 'business_owner'; // Default to business owner

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation requise';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _handleRegister() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // 1. Créer le compte avec Supabase Auth
    final authResponse = await SupabaseProvider.client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      data: {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _role,
      },
    );

    if (authResponse.user == null) {
      throw Exception('Erreur lors de la création du compte');
    }

    // 2. Créer ou mettre à jour le profil manuellement (au cas où le trigger échoue)
    try {
      await SupabaseProvider.table('profiles').upsert({
        'id': authResponse.user!.id,
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _role,
      });
    } catch (e) {
      print('Profil déjà créé par le trigger: $e');
    }

    if (mounted) {
      context.showSnackBar('Compte créé avec succès!');
      
      // 3. Attendre 1 seconde puis rediriger
      await Future.delayed(const Duration(seconds: 1));
      
      // 4. Rediriger selon le rôle
      if (_role == 'business_owner') {
        GoRouterHelper(context).go('/business-setup');
      } else {
        // Pour les clients, rediriger vers login temporairement
        // TODO: Créer une page d'accueil client
        GoRouterHelper(context).go('/login');
      }
    }
  } on AuthException catch (e) {
    if (mounted) {
      String errorMessage = 'Erreur lors de l\'inscription';
      
      if (e.message.contains('already registered')) {
        errorMessage = 'Cet email est déjà utilisé';
      } else if (e.message.contains('password')) {
        errorMessage = 'Le mot de passe est trop faible';
      } else {
        errorMessage = e.message;
      }
      
      context.showSnackBar(errorMessage, isError: true);
    }
  } catch (e) {
    if (mounted) {
      context.showSnackBar(
        'Erreur: ${e.toString()}',
        isError: true,
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
Future<void> _debugCheckProfile(String userId) async {
  try {
    print('=== DEBUG: Vérification du profil ===');
    
    // Vérifier dans auth.users
    final authUser = SupabaseProvider.client.auth.currentUser;
    print('Auth User ID: ${authUser?.id}');
    print('Auth User Email: ${authUser?.email}');
    print('Auth User Metadata: ${authUser?.userMetadata}');
    
    // Vérifier dans profiles
    final profileData = await SupabaseProvider.table('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    
    print('Profile Data: $profileData');
    print('=== FIN DEBUG ===');
  } catch (e) {
    print('Erreur debug: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouterHelper(context).go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Créer un compte',
                  textAlign: TextAlign.center,
                  style: ContextExtension(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez BookEasy aujourd\'hui',
                  textAlign: TextAlign.center,
                  style: ContextExtension(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Full Name
                CustomTextField(
                  label: 'Nom complet',
                  hint: 'Jean Dupont',
                  controller: _fullNameController,
                  validator: (value) => Validators.required(value, 'Nom'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                
                const SizedBox(height: 20),
                
                // Email
                CustomTextField(
                  label: 'Email',
                  hint: 'votre@email.com',
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                
                const SizedBox(height: 20),
                
                // Phone
                CustomTextField(
                  label: 'Téléphone',
                  hint: '06 12 34 56 78',
                  controller: _phoneController,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                
                const SizedBox(height: 20),
                
                // Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Je suis un...',
                      style: ContextExtension(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Professionnel (Business)'),
                            subtitle: const Text('Je veux gérer mes rendez-vous'),
                            value: 'business_owner',
                            groupValue: _role,
                            onChanged: (value) {
                              setState(() => _role = value!);
                            },
                            activeColor: AppTheme.primaryBlue,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Client'),
                            subtitle: const Text('Je veux prendre des rendez-vous'),
                            value: 'client',
                            groupValue: _role,
                            onChanged: (value) {
                              setState(() => _role = value!);
                            },
                            activeColor: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Password
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
                
                const SizedBox(height: 20),
                
                // Confirm Password
                CustomTextField(
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Register Button
                CustomButton(
                  text: 'S\'inscrire',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 24),
                
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte? ',
                      style: ContextExtension(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => GoRouterHelper(context).go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Se connecter',
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