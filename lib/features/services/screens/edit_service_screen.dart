import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/service.dart';

class CreateServiceScreen extends StatefulWidget {
  final String? serviceId;

  const CreateServiceScreen({super.key, this.serviceId});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = true;
  bool _isEditMode = false;
  Service? _existingService;

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _isEditMode = true;
      _loadService();
    }
  }

  Future<void> _loadService() async {
    setState(() => _isLoading = true);

    try {
      final data = await SupabaseProvider.table('services')
          .select('*')
          .eq('id', widget.serviceId!)
          .single();

      _existingService = Service.fromJson(data);
      
      _nameController.text = _existingService!.name;
      _descriptionController.text = _existingService!.description ?? '';
      _durationController.text = _existingService!.durationMinutes.toString();
      _priceController.text = _existingService!.price.toString();
      _isActive = _existingService!.isActive;
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get business ID
      final businessData = await SupabaseProvider.table('businesses')
          .select('id')
          .eq('owner_id', SupabaseProvider.currentUserId!)
          .single();

      final serviceData = {
        'business_id': businessData['id'],
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration_minutes': int.parse(_durationController.text),
        'price': double.parse(_priceController.text),
        'is_active': _isActive,
        'currency': 'EUR',
      };

      if (_isEditMode) {
        await SupabaseProvider.table('services')
            .update(serviceData)
            .eq('id', widget.serviceId!);
      } else {
        await SupabaseProvider.table('services').insert(serviceData);
      }

      if (mounted) {
        context.showSnackBar(
          _isEditMode ? 'Service modifié' : 'Service créé',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
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
        title: Text(_isEditMode ? 'Modifier le service' : 'Nouveau service'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Name
                CustomTextField(
                  label: 'Nom du service',
                  hint: 'Ex: Coupe Homme',
                  controller: _nameController,
                  validator: (value) => Validators.required(value, 'Nom'),
                  prefixIcon: const Icon(Icons.content_cut),
                ),
                const SizedBox(height: 20),
                
                // Description
                CustomTextField(
                  label: 'Description (optionnel)',
                  hint: 'Décrivez votre service...',
                  controller: _descriptionController,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                
                // Duration and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Durée (minutes)',
                        hint: '30',
                        controller: _durationController,
                        validator: Validators.duration,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Prix (€)',
                        hint: '25.00',
                        controller: _priceController,
                        validator: Validators.price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        prefixIcon: const Icon(Icons.euro),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Active Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service actif',
                              style: ContextExtension(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Les clients peuvent réserver ce service',
                              style: ContextExtension(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                        activeColor: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                CustomButton(
                  text: _isEditMode ? 'Enregistrer' : 'Créer le service',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  icon: _isEditMode ? Icons.save : Icons.add,
                ),
                
                if (_isEditMode) ...[
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Annuler',
                    onPressed: () => context.pop(),
                    isOutlined: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}