// lib/features/business/screens/business_settings_screen.dart

import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/business.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Business Info Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  Business? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  BusinessCategory? _selectedCategory;
  bool _isActive = true;
  
  // Opening Hours
  Map<String, OpeningHours> _openingHours = {};
  int _slotDuration = 30;
  int _bufferTime = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBusinessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);

    try {
      final businessData = await SupabaseProvider.table('businesses')
          .select('*')
          .eq('owner_id', SupabaseProvider.currentUserId!)
          .maybeSingle();

      if (businessData == null) {
        if (mounted) {
          context.showSnackBar('Aucun établissement trouvé', isError: true);
          context.go('/business-setup');
        }
        return;
      }

      _business = Business.fromJson(businessData);
      
      // Populate form fields
      _nameController.text = _business!.name;
      _descriptionController.text = _business!.description ?? '';
      _phoneController.text = _business!.phone;
      _emailController.text = _business!.email ?? '';
      _addressController.text = _business!.address ?? '';
      _cityController.text = _business!.city ?? '';
      _postalCodeController.text = _business!.postalCode ?? '';
      _selectedCategory = _business!.category;
      _isActive = _business!.isActive;
      _openingHours = Map.from(_business!.openingHours);
      _slotDuration = _business!.slotDuration;
      _bufferTime = _business!.bufferTime;
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

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!.value,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'is_active': _isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseProvider.table('businesses')
          .update(updates)
          .eq('id', _business!.id);

      if (mounted) {
        context.showSnackBar('Informations mises à jour');
        _loadBusinessData();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveScheduleSettings() async {
    setState(() => _isSaving = true);

    try {
      final hoursMap = <String, dynamic>{};
      _openingHours.forEach((day, hours) {
        hoursMap[day] = hours.toJson();
      });

      final updates = {
        'opening_hours': hoursMap,
        'slot_duration': _slotDuration,
        'buffer_time': _bufferTime,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseProvider.table('businesses')
          .update(updates)
          .eq('id', _business!.id);

      if (mounted) {
        context.showSnackBar('Horaires mis à jour');
        _loadBusinessData();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Chargement...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres établissement'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Informations'),
            Tab(text: 'Horaires'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Name
            CustomTextField(
              label: 'Nom de l\'établissement',
              controller: _nameController,
              validator: (value) => Validators.required(value, 'Nom'),
              prefixIcon: const Icon(Icons.business),
            ),
            const SizedBox(height: 20),
            
            // Category
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
            
            // Description
            CustomTextField(
              label: 'Description',
              controller: _descriptionController,
              maxLines: 4,
              hint: 'Décrivez votre établissement...',
            ),
            const SizedBox(height: 32),
            
            // Contact Section
            Text(
              'Coordonnées',
              style: ContextExtension(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Téléphone',
              controller: _phoneController,
              validator: Validators.phone,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              label: 'Email (optionnel)',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: 32),
            
            // Address Section
            Text(
              'Adresse',
              style: ContextExtension(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Adresse',
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
                    controller: _cityController,
                    validator: (value) => Validators.required(value, 'Ville'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Code postal',
                    controller: _postalCodeController,
                    validator: (value) => Validators.required(value, 'Code postal'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Active Status
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
                          'Établissement actif',
                          style: ContextExtension(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre établissement est visible par les clients',
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
            
            // Save Button
            CustomButton(
              text: 'Enregistrer les modifications',
              onPressed: _saveBusinessInfo,
              isLoading: _isSaving,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Slot Settings
          Text(
            'Paramètres des créneaux',
            style: ContextExtension(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          _buildSlotDurationSelector(),
          const SizedBox(height: 16),
          
          _buildBufferTimeSelector(),
          const SizedBox(height: 32),
          
          // Opening Hours
          Text(
            'Horaires d\'ouverture',
            style: ContextExtension(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ..._buildOpeningHoursEditors(),
          
          const SizedBox(height: 32),
          
          // Save Button
          CustomButton(
            text: 'Enregistrer les horaires',
            onPressed: _saveScheduleSettings,
            isLoading: _isSaving,
            icon: Icons.save,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durée des créneaux',
            style: ContextExtension(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Durée par défaut pour les rendez-vous',
            style: ContextExtension(context).textTheme.bodySmall?.copyWith(color: AppTheme.gray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [15, 30, 45, 60].map((duration) {
              final isSelected = _slotDuration == duration;
              return ChoiceChip(
                label: Text('$duration min'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _slotDuration = duration);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temps de battement',
            style: ContextExtension(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Pause entre les rendez-vous',
            style: ContextExtension(context).textTheme.bodySmall?.copyWith(color: AppTheme.gray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [0, 5, 10, 15, 30].map((buffer) {
              final isSelected = _bufferTime == buffer;
              return ChoiceChip(
                label: Text(buffer == 0 ? 'Aucun' : '$buffer min'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _bufferTime = buffer);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOpeningHoursEditors() {
    final days = [
      {'key': 'monday', 'label': 'Lundi'},
      {'key': 'tuesday', 'label': 'Mardi'},
      {'key': 'wednesday', 'label': 'Mercredi'},
      {'key': 'thursday', 'label': 'Jeudi'},
      {'key': 'friday', 'label': 'Vendredi'},
      {'key': 'saturday', 'label': 'Samedi'},
      {'key': 'sunday', 'label': 'Dimanche'},
    ];

    return days.map((day) {
      final dayKey = day['key']!;
      final dayLabel = day['label']!;
      final hours = _openingHours[dayKey] ?? OpeningHours(open: '09:00', close: '18:00', closed: true);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dayLabel,
                      style: ContextExtension(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    hours.closed ? 'Fermé' : 'Ouvert',
                    style: ContextExtension(context).textTheme.labelSmall?.copyWith(
                      color: hours.closed ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: !hours.closed,
                    onChanged: (isOpen) {
                      setState(() {
                        _openingHours[dayKey] = OpeningHours(
                          open: hours.open,
                          close: hours.close,
                          closed: !isOpen,
                        );
                      });
                    },
                    activeColor: AppTheme.success,
                  ),
                ],
              ),
              if (!hours.closed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelector(
                        label: 'Ouverture',
                        time: hours.open,
                        onChanged: (time) {
                          setState(() {
                            _openingHours[dayKey] = OpeningHours(
                              open: time,
                              close: hours.close,
                              closed: false,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TimeSelector(
                        label: 'Fermeture',
                        time: hours.close,
                        onChanged: (time) {
                          setState(() {
                            _openingHours[dayKey] = OpeningHours(
                              open: hours.open,
                              close: time,
                              closed: false,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String time;
  final Function(String) onChanged;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ContextExtension(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final parts = time.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            
            if (picked != null) {
              final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(time),
              ],
            ),
          ),
        ),
      ],
    );
  }
}