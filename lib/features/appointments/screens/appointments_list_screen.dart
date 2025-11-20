// =============================================
// lib/features/appointments/screens/appointments_list_screen.dart
// =============================================

import '../../../shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/theme.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/appointment_card.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/appointment.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _allAppointments = [];
  List<Appointment> _selectedDayAppointments = [];
  bool _isLoading = true;
  String? _businessId;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      // Get business ID
      final businessData = await SupabaseProvider.table('businesses')
          .select('id')
          .eq('owner_id', SupabaseProvider.currentUserId!)
          .maybeSingle();
      
      _businessId = businessData?['id'];

      // Load all appointments for the month
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final appointmentsData = await SupabaseProvider.table('appointments')
          .select('*, service:services(*)')
          .eq('business_id', _businessId!)
          .gte('appointment_date', startDate.toIso8601String().split('T')[0])
          .lte('appointment_date', endDate.toIso8601String().split('T')[0])
          .order('start_time');

      _allAppointments = appointmentsData
          .map((json) => Appointment.fromJson(json))
          .toList();

      _filterAppointmentsForSelectedDay();
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

  void _filterAppointmentsForSelectedDay() {
    _selectedDayAppointments = _allAppointments
        .where((apt) => app_date_utils.AppDateUtils.isSameDay(
              apt.appointmentDate,
              _selectedDay,
            ))
        .toList();
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return _allAppointments
        .where((apt) => app_date_utils.AppDateUtils.isSameDay(
              apt.appointmentDate,
              day,
            ))
        .toList();
  }

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      await SupabaseProvider.table('appointments')
          .update({'status': newStatus.value})
          .eq('id', appointment.id);

      if (mounted) {
        context.showSnackBar('Statut mis à jour');
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AppointmentDetailsSheet(
        appointment: appointment,
        onStatusChange: _updateAppointmentStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_week
                  : Icons.calendar_view_month,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement de l\'agenda...')
          : Column(
              children: [
                // Calendar
                _buildCalendar(),
                
                const Divider(height: 1),
                
                // Appointments List
                Expanded(child: _buildAppointmentsList()),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
  return Container(
    color: Colors.white,
    child: TableCalendar<Appointment>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      eventLoader: _getAppointmentsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      
      // IMPORTANT: Enlever le locale qui cause l'erreur
      // locale: 'fr_FR',  ← SUPPRIMER CETTE LIGNE
      
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: AppTheme.accentTeal,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        outsideDaysVisible: false, // AJOUTER CETTE LIGNE
      ),
      
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: ContextExtension(context).textTheme.titleLarge!,
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: AppTheme.primaryBlue,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: AppTheme.primaryBlue,
        ),
      ),
      
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: ContextExtension(context).textTheme.labelMedium!,
        weekendStyle: ContextExtension(context).textTheme.labelMedium!.copyWith(
          color: AppTheme.error,
        ),
      ),
      
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _filterAppointmentsForSelectedDay();
        });
      },
      
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadAppointments();
      },
    ),
  );
}


  Widget _buildAppointmentsList() {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Selected Date Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  app_date_utils.AppDateUtils.getRelativeDate(_selectedDay),
                  style: ContextExtension(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_selectedDayAppointments.length} RDV',
                  style: ContextExtension(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          ),
          
          // Appointments
          Expanded(
            child: _selectedDayAppointments.isEmpty
                ? const EmptyState(
                    icon: Icons.event_busy,
                    title: 'Aucun rendez-vous',
                    message: 'Aucun rendez-vous pour cette date',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedDayAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _selectedDayAppointments[index];
                      return AppointmentCard(
                        appointment: appointment,
                        onTap: () => _showAppointmentDetails(appointment),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Appointment Details Sheet
// =============================================

class AppointmentDetailsSheet extends StatelessWidget {
  final Appointment appointment;
  final Function(Appointment, AppointmentStatus) onStatusChange;

  const AppointmentDetailsSheet({
    super.key,
    required this.appointment,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      Text(
                        appointment.service?.name ?? 'Service',
                        style: ContextExtension(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      
                      // Status Badge
                      StatusBadge(status: appointment.status),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Client Info
                      InfoSection(
                        icon: Icons.person,
                        title: 'Client',
                        items: [
                          InfoItem(
                            label: 'Nom',
                            value: appointment.clientName,
                          ),
                          InfoItem(
                            label: 'Téléphone',
                            value: appointment.clientPhone,
                          ),
                          if (appointment.clientEmail != null)
                            InfoItem(
                              label: 'Email',
                              value: appointment.clientEmail!,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date & Time
                      InfoSection(
                        icon: Icons.calendar_today,
                        title: 'Date et heure',
                        items: [
                          InfoItem(
                            label: 'Date',
                            value: app_date_utils.AppDateUtils.formatDate(
                              appointment.appointmentDate,
                            ),
                          ),
                          InfoItem(
                            label: 'Heure',
                            value: '${app_date_utils.AppDateUtils.formatTime(appointment.startTime)} - ${app_date_utils.AppDateUtils.formatTime(appointment.endTime)}',
                          ),
                          InfoItem(
                            label: 'Durée',
                            value: appointment.service?.formattedDuration ?? '',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Service Info
                      InfoSection(
                        icon: Icons.content_cut,
                        title: 'Service',
                        items: [
                          InfoItem(
                            label: 'Prix',
                            value: appointment.service?.formattedPrice ?? '',
                          ),
                        ],
                      ),
                      
                      if (appointment.notes != null) ...[
                        const SizedBox(height: 24),
                        InfoSection(
                          icon: Icons.note,
                          title: 'Notes',
                          items: [
                            InfoItem(
                              label: '',
                              value: appointment.notes!,
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Actions
                      if (appointment.status == AppointmentStatus.pending) ...[
                        CustomButton(
                          text: 'Confirmer',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.confirmed,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Annuler',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.cancelled,
                            );
                            Navigator.pop(context);
                          },
                          isOutlined: true,
                          color: AppTheme.error,
                          icon: Icons.cancel,
                        ),
                      ],
                      
                      if (appointment.status == AppointmentStatus.confirmed) ...[
                        CustomButton(
                          text: 'Marquer comme terminé',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.completed,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icons.check,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Client absent',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.noShow,
                            );
                            Navigator.pop(context);
                          },
                          isOutlined: true,
                          color: AppTheme.warning,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper Widgets
class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const StatusBadge({super.key, required this.status});

  Color _getColor() {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppTheme.success;
      case AppointmentStatus.pending:
        return AppTheme.warning;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        return AppTheme.error;
      case AppointmentStatus.completed:
        return AppTheme.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: ContextExtension(context).textTheme.labelMedium?.copyWith(
          color: _getColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<InfoItem> items;

  const InfoSection({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: ContextExtension(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const InfoItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: ContextExtension(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: ContextExtension(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

