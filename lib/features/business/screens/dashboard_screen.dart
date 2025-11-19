
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/appointment_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/business.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  Business? _business;
  List<Appointment> _todayAppointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load business
      final businessData = await SupabaseProvider.table('businesses')
          .select('*')
          .eq('owner_id', SupabaseProvider.currentUserId!)
          .single();
      
      _business = Business.fromJson(businessData);

      // Load today's appointments
      final today = DateTime.now();
      final appointmentsData = await SupabaseProvider.table('appointments')
          .select('*, service:services(*)')
          .eq('business_id', _business!.id)
          .eq('appointment_date', today.toIso8601String().split('T')[0])
          .order('start_time');

      _todayAppointments = appointmentsData
          .map((json) => Appointment.fromJson(json))
          .toList();

    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        context.push('/services');
        break;
      case 2:
        context.push('/appointments');
        break;
      case 3:
        _showProfileMenu();
        break;
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Mon établissement'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to business settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mon profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Déconnexion', style: TextStyle(color: AppTheme.error)),
              onTap: () async {
                await SupabaseProvider.client.auth.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Chargement...')
            : _error != null
                ? Center(child: Text('Erreur: $_error'))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(),
                          const SizedBox(height: 24),
                          
                          // Stats
                          _buildStats(),
                          const SizedBox(height: 32),
                          
                          // Quick Actions
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          
                          // Today's Appointments
                          _buildTodayAppointments(),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour 👋',
          style: ContextExtension(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.gray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _business?.name ?? 'Mon établissement',
          style: ContextExtension(context).textTheme.displayMedium?.copyWith(
            color: AppTheme.dark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _business?.category.displayName ?? '',
          style: ContextExtension(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.gray,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final todayRevenue = _todayAppointments
        .where((apt) => apt.status == AppointmentStatus.confirmed || 
                       apt.status == AppointmentStatus.completed)
        .fold<double>(0, (sum, apt) => sum + (apt.service?.price ?? 0));

    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: _todayAppointments.length.toString(),
            label: 'RDV Aujourd\'hui',
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            value: '${todayRevenue.toStringAsFixed(0)}€',
            label: 'CA du jour',
            icon: Icons.euro,
            gradient: AppTheme.accentGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: ContextExtension(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_business,
                label: 'Nouveau service',
                onTap: () => context.push('/services/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calendar_month,
                label: 'Voir l\'agenda',
                onTap: () => context.push('/appointments'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rendez-vous du jour',
              style: ContextExtension(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push('/appointments'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_todayAppointments.isEmpty)
          const EmptyState(
            icon: Icons.event_busy,
            title: 'Aucun rendez-vous',
            message: 'Vous n\'avez pas de rendez-vous aujourd\'hui',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayAppointments.length,
            itemBuilder: (context, index) {
              final appointment = _todayAppointments[index];
              return AppointmentCard(
                appointment: appointment,
                onTap: () {
                  // TODO: Show appointment details
                },
              );
            },
          ),
      ],
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: ContextExtension(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}