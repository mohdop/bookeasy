import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/service.dart';

class BookingScreen extends StatefulWidget {
  final String businessId;
  final String? serviceId;

  const BookingScreen({
    super.key,
    required this.businessId,
    this.serviceId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  List<Service> _services = [];
  Service? _selectedService;
  
  DateTime _selectedDate = DateTime.now();
  List<String> _availableSlots = [];
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final servicesData = await SupabaseProvider.table('services')
          .select('*')
          .eq('business_id', widget.businessId)
          .eq('is_active', true)
          .order('order_index');

      _services = servicesData.map((json) => Service.fromJson(json)).toList();
      
      if (widget.serviceId != null) {
        _selectedService = _services.firstWhere(
          (s) => s.id == widget.serviceId,
          orElse: () => _services.first,
        );
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedService == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseProvider.client.rpc(
        'get_available_slots',
        params: {
          'p_business_id': widget.businessId,
          'p_date': _selectedDate.toIso8601String().split('T')[0],
          'p_service_id': _selectedService!.id,
        },
      );

      _availableSlots = (response as List)
          .map((slot) => slot['slot_time'] as String)
          .toList();
      
      _selectedSlot = null;
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

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate() || _selectedSlot == null) {
      context.showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calculate end time
      final startParts = _selectedSlot!.split(':');
      final startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      
      final endMinutes = startTime.hour * 60 + 
                         startTime.minute + 
                         _selectedService!.durationMinutes;
      final endTime = TimeOfDay(
        hour: endMinutes ~/ 60,
        minute: endMinutes % 60,
      );

      final bookingData = {
        'business_id': widget.businessId,
        'service_id': _selectedService!.id,
        'client_id': SupabaseProvider.currentUserId,
        'client_name': _nameController.text.trim(),
        'client_phone': _phoneController.text.trim(),
        'client_email': _emailController.text.trim(),
        'appointment_date': _selectedDate.toIso8601String().split('T')[0],
        'start_time': _selectedSlot,
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
        'status': 'pending',
        'notes': _notesController.text.trim(),
      };

      await SupabaseProvider.table('appointments').insert(bookingData);

      if (mounted) {
        context.showSnackBar('Réservation effectuée!');
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

  void _nextStep() {
    if (_currentStep == 0 && _selectedService == null) {
      context.showSnackBar('Veuillez sélectionner un service', isError: true);
      return;
    }
    
    if (_currentStep == 1) {
      if (_selectedSlot == null) {
        context.showSnackBar('Veuillez sélectionner un créneau', isError: true);
        return;
      }
    }
    
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      if (_currentStep == 1) {
        _loadAvailableSlots();
      }
    } else {
      _createBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver'),
      ),
      body: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: [
                _buildServiceSelection(),
                _buildDateTimeSelection(),
                _buildClientInfo(),
              ][_currentStep],
            ),
          ),
          
          // Action Button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _StepDot(isActive: true, isCompleted: _currentStep > 0, number: 1),
          _StepLine(isActive: _currentStep > 0),
          _StepDot(isActive: _currentStep >= 1, isCompleted: _currentStep > 1, number: 2),
          _StepLine(isActive: _currentStep > 1),
          _StepDot(isActive: _currentStep >= 2, isCompleted: false, number: 3),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisissez un service', style: ContextExtension(context).textTheme.displaySmall),
        const SizedBox(height: 24),
        
        ..._services.map((service) {
          final isSelected = _selectedService?.id == service.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
            child: InkWell(
              onTap: () => setState(() => _selectedService = service),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<Service>(
                      value: service,
                      groupValue: _selectedService,
                      onChanged: (value) => setState(() => _selectedService = value),
                      activeColor: AppTheme.primaryBlue,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: ContextExtension(context).textTheme.titleMedium),
                          Text(
                            '${service.formattedDuration} • ${service.formattedPrice}',
                            style: ContextExtension(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date et heure', style: ContextExtension(context).textTheme.displaySmall),
        const SizedBox(height: 24),
        
        // Calendar
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          calendarFormat: CalendarFormat.week,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDate = selected;
              _loadAvailableSlots();
            });
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        Text('Créneaux disponibles', style: ContextExtension(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        
        if (_isLoading)
          const LoadingIndicator()
        else if (_availableSlots.isEmpty)
          const Text('Aucun créneau disponible')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(app_date_utils.AppDateUtils.formatTime(slot)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedSlot = selected ? slot : null);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos informations', style: ContextExtension(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          
          CustomTextField(
            label: 'Nom complet',
            controller: _nameController,
            validator: (v) => Validators.required(v, 'Nom'),
            prefixIcon: const Icon(Icons.person),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Téléphone',
            controller: _phoneController,
            validator: Validators.phone,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Email (optionnel)',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Notes (optionnel)',
            controller: _notesController,
            maxLines: 3,
            hint: 'Des précisions à ajouter?',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: SafeArea(
        child: CustomButton(
          text: _currentStep == 2 ? 'Confirmer' : 'Continuer',
          onPressed: _nextStep,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final int number;

  const _StepDot({
    required this.isActive,
    required this.isCompleted,
    required this.number,
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
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.gray,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

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