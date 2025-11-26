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
    // 1. Create the account with Supabase Auth
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

    // 2. IMPORTANT: Wait for the trigger to create the profile
    await Future.delayed(const Duration(seconds: 2));

    // 3. Update the profile with complete information
    try {
      await SupabaseProvider.table('profiles').upsert({
        'id': authResponse.user!.id,
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _role,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Profile updated successfully');
    } catch (e) {
      print('⚠️ Error updating profile: $e');
      // Continue anyway - the trigger should have created basic profile
    }

    if (mounted) {
  // Show email verification dialog
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.mark_email_read, color: AppTheme.success),
          const SizedBox(width: 12),
          const Text('Vérifiez votre email'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Un email de confirmation a été envoyé à :',
            style: ContextExtension(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text.trim(),
            style: ContextExtension(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Veuillez cliquer sur le lien dans l\'email pour activer votre compte.',
            style: ContextExtension(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pensez à vérifier vos spams !',
                    style: ContextExtension(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('J\'ai compris'),
        ),
      ],
    ),
  );
  
  // 3. Attendre puis rediriger
  await Future.delayed(const Duration(milliseconds: 500));
      
      // 5. Redirect based on role
      if (_role == 'business_owner') {
        GoRouterHelper(context).go('/business-setup');
      } else {
        GoRouterHelper(context).go('/client-home');
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