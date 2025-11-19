// =============================================
// lib/features/business/screens/business_setup_screen.dart
// =============================================

import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/business.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  bool _isLoading = false;
  int _currentStep = 0;
  BusinessCategory _selectedCategory = BusinessCategory.barber;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final businessData = {
        'owner_id': SupabaseProvider.currentUserId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory.value,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'is_active': true,
      };

      await SupabaseProvider.table('businesses').insert(businessData);

      if (mounted) {
        context.showSnackBar('Établissement créé avec succès!');
        context.go('/dashboard');
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

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _handleSubmit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration de votre établissement'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentStep == 0) _buildStep1(),
                      if (_currentStep == 1) _buildStep2(),
                      if (_currentStep == 2) _buildStep3(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StepIndicator(isActive: _currentStep >= 0, isCompleted: _currentStep > 0),
          _StepConnector(isActive: _currentStep > 0),
          _StepIndicator(isActive: _currentStep >= 1, isCompleted: _currentStep > 1),
          _StepConnector(isActive: _currentStep > 1),
          _StepIndicator(isActive: _currentStep >= 2, isCompleted: false),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations générales',
          style: ContextExtension(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Commençons par les informations de base',
          style: ContextExtension(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray),
        ),
        const SizedBox(height: 32),
        
        CustomTextField(
          label: 'Nom de l\'établissement',
          hint: 'Salon Jean',
          controller: _nameController,
          validator: (value) => Validators.required(value, 'Nom'),
          prefixIcon: const Icon(Icons.business),
        ),
        const SizedBox(height: 20),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégorie',
              style: ContextExtension(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BusinessCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.dark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        CustomTextField(
          label: 'Description (optionnel)',
          hint: 'Décrivez votre établissement...',
          controller: _descriptionController,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordonnées',
          style: ContextExtension(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Comment vos clients peuvent vous contacter',
          style: ContextExtension(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray),
        ),
        const SizedBox(height: 32),
        
        CustomTextField(
          label: 'Téléphone',
          hint: '06 12 34 56 78',
          controller: _phoneController,
          validator: Validators.phone,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone),
        ),
        const SizedBox(height: 20),
        
        CustomTextField(
          label: 'Email (optionnel)',
          hint: 'contact@exemple.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email),
        ),
        const SizedBox(height: 20),
        
        CustomTextField(
          label: 'Adresse',
          hint: '10 Rue de Paris',
          controller: _addressController,
          validator: (value) => Validators.required(value, 'Adresse'),
          prefixIcon: const Icon(Icons.location_on),
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                label: 'Ville',
                hint: 'Paris',
                controller: _cityController,
                validator: (value) => Validators.required(value, 'Ville'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Code postal',
                hint: '75001',
                controller: _postalCodeController,
                validator: (value) => Validators.required(value, 'Code postal'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif',
          style: ContextExtension(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez vos informations avant de continuer',
          style: ContextExtension(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray),
        ),
        const SizedBox(height: 32),
        
        _SummaryCard(
          title: 'Établissement',
          items: [
            _SummaryItem(label: 'Nom', value: _nameController.text),
            _SummaryItem(label: 'Catégorie', value: _selectedCategory.displayName),
            if (_descriptionController.text.isNotEmpty)
              _SummaryItem(label: 'Description', value: _descriptionController.text),
          ],
        ),
        const SizedBox(height: 16),
        
        _SummaryCard(
          title: 'Coordonnées',
          items: [
            _SummaryItem(label: 'Téléphone', value: _phoneController.text),
            if (_emailController.text.isNotEmpty)
              _SummaryItem(label: 'Email', value: _emailController.text),
            _SummaryItem(
              label: 'Adresse',
              value: '${_addressController.text}, ${_postalCodeController.text} ${_cityController.text}',
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous pourrez modifier ces informations plus tard dans les paramètres',
                  style: ContextExtension(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Retour',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _currentStep == 2 ? 'Terminer' : 'Continuer',
              onPressed: _nextStep,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

// Step Indicator Widget
class _StepIndicator extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? AppTheme.primaryBlue : AppTheme.lightGray,
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 20)
          : null,
    );
  }
}

// Step Connector Widget
class _StepConnector extends StatelessWidget {
  final bool isActive;

  const _StepConnector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppTheme.primaryBlue : AppTheme.lightGray,
      ),
    );
  }
}

// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final List<_SummaryItem> items;

  const _SummaryCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ContextExtension(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: item,
          )),
        ],
      ),
    );
  }
}

// Summary Item Widget
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ContextExtension(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ContextExtension(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}